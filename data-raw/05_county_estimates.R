################################################################################
# 05_county_estimates.R
#
# Regenerate the county-level homeless estimates by disaggregating CoC
# Point-in-Time counts to counties, following Almquist, Helwig & You (2020):
#
#  1. For each year, intersect the county boundaries with that year's CoC
#     boundaries. Allocate each CoC's PIT count to the counties it overlaps in
#     proportion to county POPULATION DENSITY D_i = pop_i / area_i (population
#     benchmarked to the 2010 Census; area in km^2). This is volume-preserving
#     (pycnophylactic): the counties of a CoC sum back to the CoC total.
#  2. Integer rounding that preserves each CoC's total (largest-remainder).
#  3. Counties overlapping no CoC in a year are left missing (NA).
#  4. Missing counties are imputed with a spatial Poisson model using only
#     population and area (the paper uses a Bayesian spatial Poisson GLM, Finley
#     et al. 2015; here an mgcv Poisson GAM with a smooth of county centroid
#     coordinates, an established, faithful analog). The fitted mean fills the
#     gaps, then the same rounding is applied.
#  5. ACS covariates (5-year estimates) are attached for downstream use.
#
# Outputs: homeless, homeless_na, sp_homeless (sf). Run from the package root.
# Requires CENSUS_API_KEY in ~/.Renviron.
################################################################################

suppressMessages({
  library(sf); library(dplyr); library(tidyr); library(tidycensus); library(mgcv)
  library(tigris)
})
options(tigris_use_cache = TRUE, tigris_class = "sf")
source("data-raw/00_geo_helpers.R")   # EQ, prep_tracts(), add_county_fips()
source("data-raw/00_build_helpers.R") # round_preserve, water_fill, choose_primary, ...
sf_use_s2(FALSE)
stopifnot(dir.exists("data"))
YEARS <- 2007:2025
ACS_END <- 2022L   # 5-year ACS vintage for covariates (2018-2022)

## ---- county frame: 50 states + DC (exclude territories), matches legacy -----
load("data/counties.rda"); load("data/area.rda")
area$fips <- sprintf("%05d", as.integer(as.character(area$fips)))
counties <- counties[as.integer(counties$STATEFP) < 60 & counties$STATEFP != "", ]
counties <- counties[order(counties$fips), ]
cents <- suppressWarnings(st_coordinates(st_centroid(st_transform(counties, 4269))))
geo <- data.frame(fips = counties$fips, state = substr(counties$fips, 1, 2),
                  lon = cents[, 1], lat = cents[, 2], stringsAsFactors = FALSE)

## ---- 2010 Census population (density benchmark) -----------------------------
# Pulled at TRACT level and aggregated onto the canonical county frame, rather
# than taken as county totals. `get_decennial("county", year = 2010)` is keyed on
# the 2010 county vintage, which has no Connecticut planning regions, no Chugach
# / Copper River / Kusilvak and no Oglala Lakota. Joining those county totals to
# the modern frame left 13 counties with pop2010 = NA; they were then dropped by
# the density filter below, skipped by the imputation guard, and written out as
# zeros -- every Connecticut county read 0 in every year. 2010 tracts nest inside
# the modern counties, so assigning each tract by its interior point gives a
# vintage-independent benchmark.
pop_cache <- file.path("data-raw/downloads", "pop2010_county.rds")
if (file.exists(pop_cache)) {
  pop2010 <- readRDS(pop_cache)
} else {
  message("pulling 2010 decennial population at tract level ...")
  st_list <- sort(unique(counties$STATEFP))
  tr_pop <- bind_rows(lapply(st_list, function(s)
    tryCatch(get_decennial("tract", variables = "P001001", year = 2010,
                           state = s, geometry = FALSE, progress_bar = FALSE),
             error = function(e) NULL))) |>
    transmute(GEOID, pop = value)

  # Tract geometry must be the SAME 2010 vintage as the population table: a
  # tract GEOID embeds its county code, so 2010 tracts in Wade Hampton AK and
  # Shannon SD are keyed 02270.../46113..., while the 2019 shapefile keys the
  # same ground as 02158.../46102.... Joining across vintages loses exactly
  # those counties (the build guard below catches it).
  tr <- bind_rows(lapply(st_list, function(s)
    tryCatch(tigris::tracts(state = s, year = 2010, cb = TRUE,
                            progress_bar = FALSE),
             error = function(e) NULL)))
  tr$GEOID <- if ("GEOID10" %in% names(tr)) tr$GEOID10 else
              paste0(tr$STATE, tr$COUNTY, tr$TRACT)
  tr <- tr[, "GEOID"] |> st_transform(EQ) |> st_make_valid()
  map <- tract_county_fips(tr, counties,
                           cache = file.path("data-raw/downloads",
                                             "tract2010v_county.rds"))

  pop2010 <- tr_pop |> left_join(map, by = "GEOID") |>
    filter(!is.na(fips)) |>
    group_by(fips) |> summarise(pop2010 = sum(pop, na.rm = TRUE), .groups = "drop")
  saveRDS(pop2010, pop_cache)
}

dens <- geo |> left_join(pop2010, by = "fips") |> left_join(area, by = "fips") |>
  mutate(D = pop2010 / skm)

# The guard whose absence let Connecticut ship as zeros: every county in the
# frame must have a usable density weight before any apportionment happens.
bad <- dens$fips[is.na(dens$D) | !is.finite(dens$D)]
if (length(bad))
  stop("no density weight for ", length(bad), " counties: ",
       paste(head(bad, 20), collapse = ", "),
       "\n  -> county FIPS vintage mismatch between counties/area/pop2010")

## ---- ACS pulls are cached and retried: the Census API is flaky (timeouts,
## connection resets) and should not be able to fail a rebuild. ---------------
cached_acs <- function(cache, ...) {
  if (file.exists(cache)) return(readRDS(cache))
  for (i in 1:5) {
    out <- tryCatch(get_acs(...), error = function(e) { message("  ACS retry ", i, ": ", conditionMessage(e)); NULL })
    if (!is.null(out)) { saveRDS(out, cache); return(out) }
    Sys.sleep(10 * i)
  }
  stop("ACS pull failed 5 times: ", cache)
}

## ---- plausibility caps (metro-aware) ---------------------------------------
# Max homeless per county = cap_rate * ACS population. New York City's boroughs
# and Los Angeles County -- dense major-metro cores with genuinely high
# homelessness -- get 3.5%; every other county 2%. Excess above a county's cap
# is redistributed within its CoC (water-filling) so the CoC's PIT total is
# preserved rather than discarded.
METRO_FIPS <- c("36061", "36047", "36081", "36005", "36085",  # NYC boroughs
                "06037")                                       # Los Angeles
cap_rate_for <- function(fips) ifelse(fips %in% METRO_FIPS, 0.035, 0.02)
pop_acs <- cached_acs(file.path("data-raw/downloads", sprintf("acs%d_county_pop.rds", ACS_END)),
                   "county", variables = "B01003_001", year = ACS_END,
                   survey = "acs5", geometry = FALSE, progress_bar = FALSE) |>
  transmute(fips = GEOID, pop_acs = estimate)
caps <- data.frame(fips = geo$fips) |> left_join(pop_acs, by = "fips") |>
  mutate(cap = ifelse(is.na(pop_acs), Inf, cap_rate_for(fips) * pop_acs))
cap_by_fips <- setNames(caps$cap, caps$fips)

## ---- bi-state CoC splits from HUD's published by-state totals ---------------
# MO-604 (Kansas City) covers territory in both Missouri and Kansas. HUD's
# by-CoC workbook reports it as one combined row coded to Missouri; HUD's
# by-State workbook reports the two portions separately. Without the split, the
# density weighting hands dense Wyandotte County KS a large share of the whole
# CoC, pushing Kansas roughly 29% above its officially reported state total.
#
# The split is derived, not hardcoded: for each state, the residual between
# HUD's published state total and the sum of the CoCs coded to that state is the
# portion contributed by a CoC coded elsewhere. Only Kansas/Missouri show a
# residual in any year, and the residuals net to zero nationally.
state_csv <- "data-raw/downloads/pit_by_state.csv"
if (!file.exists(state_csv)) {
  xlsb <- "data-raw/downloads/PIT-by-State.xlsb"
  if (!file.exists(xlsb)) {
    ua  <- "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"
    ref <- paste0("https://www.huduser.gov/portal/datasets/ahar/",
                  "2025-ahar-part-1-pit-estimates-of-homelessness-in-the-us.html")
    system(sprintf("curl -sL --max-time 300 -A %s -H %s -o %s %s",
                   shQuote(ua), shQuote(paste0("Referer: ", ref)), shQuote(xlsb),
                   shQuote(paste0("https://www.huduser.gov/portal/sites/default/",
                                  "files/xls/2007-2025-PIT-Counts-by-State.xlsb"))))
  }
  run_extractor(Sys.which("python3"),
                c("data-raw/pit_state_extract.py", shQuote(xlsb), shQuote(state_csv)),
                out = state_csv, src = xlsb)
}
hud_state <- utils::read.csv(state_csv)
usps <- setNames(counties$STUSPS, counties$STATEFP)

state_split <- function(yr, hud, prefer = BISTATE_REF) {
  own <- tapply(hud$count, substr(as.character(hud$coc_num), 1, 2), sum)
  hs <- hud_state[hud_state$year == yr, ]
  resid <- setNames(hs$total - ifelse(is.na(own[hs$state]), 0, own[hs$state]), hs$state)
  hosts <- names(resid)[!is.na(resid) & resid > 0]
  if (!length(hosts)) return(NULL)
  cc <- local({ load(sprintf("data/county_coc%d.rda", yr))
                get(sprintf("county_coc%d", yr)) })
  cc$ST <- usps[substr(cc$fips, 1, 2)]
  out <- NULL; members <- NULL; picks <- character()
  for (s in hosts) {
    cand <- cc[!is.na(cc$ST) & cc$ST == s & substr(cc$COCNUM, 1, 2) != s, ]
    if (!nrow(cand)) next
    # BUG-010: the CoC must be coded to a state that is SHORT by the residual
    # (Missouri for MO-604). Picking the largest-area foreign CoC charged
    # Kansas City's Kansas portion to OK-503 whenever its sliver into Kansas
    # outsized MO-604's in HUD's pre-2016 boundary file.
    coc <- pick_split_coc(s, resid, tapply(cand$area_m2, cand$COCNUM, sum),
                          setNames(hud$count, as.character(hud$coc_num)), prefer)
    if (is.na(coc)) stop(sprintf("%d: %s is %+d vs its CoCs but no CoC coded to a short state overlaps it",
                                 yr, s, resid[[s]]))
    tot <- hud$count[as.character(hud$coc_num) == coc]
    if (!length(tot)) next
    if (resid[[s]] >= tot) stop(sprintf("%d: split of %s gives %s %d of %d", yr, coc, s, resid[[s]], tot))
    out <- rbind(out,
                 data.frame(COCNUM = coc, ST = s, cnt = resid[[s]]),
                 data.frame(COCNUM = coc, ST = substr(coc, 1, 2),
                            cnt = tot - resid[[s]]))
    # The host-state portion must land on host-state counties even where the
    # CoC is only a sliver there (MO-604 reaches 0.7 km^2 into Kansas pre-2016).
    members <- rbind(members, data.frame(fips = unique(cand$fips[cand$COCNUM == coc]),
                                         COCNUM = coc))
    picks[s] <- coc
  }
  if (!is.null(out)) { attr(out, "members") <- members; attr(out, "picks") <- picks }
  out
}

# Identify each bi-state CoC once, from the most recent boundary file, and hold
# it fixed across the series (BUG-010).
BISTATE_REF <- NULL
BISTATE_REF <- local({
  yr <- max(YEARS); e <- new.env(); load(sprintf("data/hud%d.rda", yr), envir = e)
  attr(state_split(yr, get(sprintf("hud%d", yr), envir = e), prefer = NULL), "picks")
})
message("bi-state CoCs (from ", max(YEARS), "): ",
        paste(names(BISTATE_REF), BISTATE_REF, sep = "<-", collapse = ", "))

## round_preserve() and water_fill() live in data-raw/00_build_helpers.R
## (sourced above) so they are unit-tested.

co5070 <- st_make_valid(st_transform(counties[, "fips"], 5070))
county_area <- setNames(as.numeric(st_area(co5070)), co5070$fips)

## ---- boundary fallback index (BUG-008) --------------------------------------
# HUD's boundary file for a year sometimes omits a CoC that reported a PIT count
# (CA-524 2009-2012, LA-509 2007-2014, five Maryland CoCs in 2020, ...). Such a
# CoC used to reach no county and its whole count was dropped. Every one of
# them has a polygon in some other year, so borrow the nearest year's.
coc_by_year <- lapply(setNames(YEARS, YEARS), function(y) {
  e <- new.env(); load(sprintf("data/coc%d.rda", y), envir = e)
  x <- get(sprintf("coc%d", y), envir = e)[, "COCNUM"]
  x$COCNUM <- normalize_coc_code(x$COCNUM)
  st_make_valid(st_transform(x, 5070))
})
poly_years <- split(rep(YEARS, vapply(coc_by_year, nrow, 1L)),
                    unlist(lapply(coc_by_year, `[[`, "COCNUM")))
TERRITORY_COC <- c("AS", "GU", "MP", "PR", "VI")

## ---- per-year apportionment -------------------------------------------------
allocate_year <- function(yr) {
  load(sprintf("data/hud%d.rda", yr)); hud <- get(sprintf("hud%d", yr))
  hud$coc_num <- as.character(hud$coc_num)
  cc <- coc_by_year[[as.character(yr)]]

  need <- setdiff(hud$coc_num[hud$count > 0 &
                                !substr(hud$coc_num, 1, 2) %in% TERRITORY_COC],
                  cc$COCNUM)
  for (k in need) {
    by <- nearest_boundary_year(yr, poly_years[[k]] %||% integer())
    if (is.na(by)) stop(sprintf("%s reports %d people in %d but has no polygon in any year",
                                k, hud$count[hud$coc_num == k], yr))
    cc <- rbind(cc, coc_by_year[[as.character(by)]][coc_by_year[[as.character(by)]]$COCNUM == k, ])
    fallback <<- rbind(fallback, data.frame(year = yr, COCNUM = k, polygon_year = by))
  }

  int <- st_intersection(co5070, cc)
  int$a <- as.numeric(st_area(int))
  ov <- st_drop_geometry(int) |> filter(a > 0)

  # Each county's PRIMARY CoC = the CoC covering the largest share of it, and
  # only if it covers at least 1% of the county (BUG-009): a county the
  # boundary file leaves uncovered is imputed, not handed to a neighbour that
  # slivers into it. Raw density weighting over every overlapped county would
  # also hand a dense neighbour a CoC that isn't really there (BUG-004).
  dom <- choose_primary(ov, county_area, min_share = MIN_PRIMARY_SHARE)

  # Sub-county / nested CoCs (e.g. Long Beach inside LA County) are nobody's
  # primary CoC; assign each to the county that contains most of it, so its
  # count is not lost.
  orphan_assign <- assign_orphans(ov, dom, unique(hud$coc_num), county_area)

  membership <- bind_rows(dom, orphan_assign) |> distinct(fips, COCNUM)

  # Each county's PRIMARY CoC, exported so that 10_county_pit.R and
  # 12_pit_detail.R split the same county the same way (BUG-011). A county with
  # no primary of its own but which hosts an orphan CoC takes that CoC.
  prim_y <- bind_rows(mutate(dom, via = "primary"),
                      orphan_assign |> filter(!fips %in% dom$fips) |>
                        distinct(fips, .keep_all = TRUE) |> mutate(via = "nested"))
  primary <<- bind_rows(primary, mutate(prim_y, year = yr))

  # Within each CoC, split its PIT count among member counties by population
  # density (paper's volume-preserving estimator), water-filling so no county
  # exceeds its cap and the excess flows to counties with headroom.
  # For a CoC that HUD reports split across states, allocate each state's
  # published portion within that state's member counties only.
  spl <- state_split(yr, hud)
  if (!is.null(attr(spl, "members")))
    membership <- bind_rows(membership, attr(spl, "members")) |> distinct(fips, COCNUM)

  a <- membership |>
    left_join(dens[, c("fips", "D")], by = "fips") |>
    left_join(caps[, c("fips", "cap")], by = "fips") |>
    filter(!is.na(D), D > 0) |>
    left_join(hud, by = c("COCNUM" = "coc_num")) |>
    filter(!is.na(count)) |>
    mutate(ST = usps[substr(fips, 1, 2)]) |>
    (\(d) {
      if (is.null(spl)) { d$grp <- "ALL"; d$grp_count <- d$count; return(d) }
      d <- left_join(d, spl, by = c("COCNUM", "ST"))
      split_coc <- unique(spl$COCNUM)
      d$grp <- ifelse(d$COCNUM %in% split_coc, d$ST, "ALL")
      d$grp_count <- ifelse(d$COCNUM %in% split_coc, d$cnt, d$count)
      # a split CoC may touch a state HUD assigns no portion to; drop those
      d[!is.na(d$grp_count), ]
    })() |>
    group_by(COCNUM, grp) |>
    group_modify(~ { .x$cnt <- round_preserve(water_fill(.x$grp_count[1], .x$D, .x$cap)); .x }) |>
    ungroup()

  # Per (county, CoC) allocation, kept so later steps (14_unsheltered_
  # imputation.R) can apportion a CoC-level quantity with exactly the same split.
  alloc <<- bind_rows(alloc, a |> transmute(fips, COCNUM, year = yr, cnt,
                                            coc_count = count))

  a |> group_by(fips) |> summarise(count = sum(cnt), .groups = "drop") |>
    mutate(year = yr)
}

MIN_PRIMARY_SHARE <- 0.01
panel_cache <- "data-raw/downloads/county_panel.rds"
prim_cache  <- "data-raw/downloads/county_primary_coc.rds"
alloc_cache <- "data-raw/downloads/county_coc_alloc.rds"
fb_cache    <- "data-raw/downloads/boundary_fallback.rds"
primary <- NULL; alloc <- NULL; fallback <- NULL
if (all(file.exists(c(panel_cache, prim_cache, alloc_cache, fb_cache)))) {
  message("loading cached apportionment panel")
  panel <- readRDS(panel_cache)
  alloc <- readRDS(alloc_cache)
} else {
  message("apportioning ", length(YEARS), " years ...")
  panel <- bind_rows(lapply(YEARS, function(y) { message("  ", y); allocate_year(y) }))
  saveRDS(panel, panel_cache)
  saveRDS(primary, prim_cache)
  saveRDS(alloc, alloc_cache)
  saveRDS(fallback, fb_cache)
}

## ---- county_coc_alloc: where each county's estimate comes from ------------
# One row per (county, year, CoC) with the number of people apportioned from
# that CoC, its role, how much of the county the CoC covers, and which year's
# HUD boundary was used (BUG-008 fallback). Shipped so users -- and the QC tests
# -- can trace every county estimate to its source CoCs.
fallback <- readRDS(fb_cache)
if (is.null(fallback)) fallback <- data.frame(year = integer(), COCNUM = character(),
                                             polygon_year = integer())
prim <- readRDS(prim_cache)
is_primary_of <- prim |> filter(via == "primary") |> distinct(COCNUM, year) |> mutate(somebodys = TRUE)
county_coc_alloc <- alloc |>
  left_join(prim |> filter(via == "primary") |> select(fips, COCNUM, year, share) |>
              mutate(own = TRUE), by = c("fips", "COCNUM", "year")) |>
  left_join(prim |> filter(via == "nested") |> select(fips, COCNUM, year, nshare = share),
            by = c("fips", "COCNUM", "year")) |>
  left_join(is_primary_of, by = c("COCNUM", "year")) |>
  left_join(fallback, by = c("year", "COCNUM")) |>
  mutate(role = case_when(coalesce(own, FALSE) ~ "primary",
                          !coalesce(somebodys, FALSE) ~ "nested",
                          TRUE ~ "bi-state"),
         share = coalesce(share, nshare),
         boundary_year = as.integer(coalesce(polygon_year, year)),
         year = as.integer(year))
county_coc_alloc <- county_coc_alloc |>
  transmute(fips, year, coc_num = COCNUM, count = as.integer(cnt), role,
            share = round(share, 6), boundary_year) |>
  arrange(fips, year, desc(role == "primary"), coc_num) |> as.data.frame()
save(county_coc_alloc, file = "data/county_coc_alloc.rda", compress = "xz")

## ---- conservation guard: every placed CoC's count must reach counties -------
hud_all <- bind_rows(lapply(YEARS, function(y) {
  e <- new.env(); load(sprintf("data/hud%d.rda", y), envir = e)
  h <- get(sprintf("hud%d", y), envir = e)
  data.frame(COCNUM = as.character(h$coc_num), year = y, count = h$count)
})) |> filter(count > 0, !substr(COCNUM, 1, 2) %in% TERRITORY_COC)
leak <- hud_all |>
  left_join(alloc |> group_by(COCNUM, year) |> summarise(placed = sum(cnt), .groups = "drop"),
            by = c("COCNUM", "year")) |>
  mutate(placed = coalesce(placed, 0L)) |> filter(placed != count)
if (nrow(leak))
  stop(sprintf("%d CoC-years not fully placed (%d people), e.g. %s",
                  nrow(leak), sum(leak$count - leak$placed),
                  paste(head(sprintf("%s %d (%d/%d)", leak$COCNUM, leak$year,
                                     leak$placed, leak$count), 15), collapse = ", ")))

## ---- wide county x year, with NA where a county had no CoC that year --------
wide <- panel |>
  mutate(col = sprintf("count%02d", year %% 100)) |>
  select(fips, col, count) |>
  pivot_wider(names_from = col, values_from = count) |>
  right_join(geo, by = "fips")
cnt_cols <- sprintf("count%02d", YEARS %% 100)
wide <- wide[, c("state", "fips", cnt_cols, "lon", "lat")]

## ---- spatial Poisson imputation of missing counties (pop + area) ------------
imp <- dens[, c("fips", "pop2010", "skm", "lon", "lat")]
homeless_counts <- wide
for (cc in cnt_cols) {
  d <- wide[, c("fips", cc)] |> left_join(imp, by = "fips") |>
    mutate(y = .data[[cc]])
  ok <- !is.na(d$pop2010) & d$pop2010 > 0 & !is.na(d$skm) & d$skm > 0
  obs <- d[ok & !is.na(d$y), ]
  fit <- mgcv::gam(y ~ log(pop2010) + log(skm) + s(lon, lat, k = 60),
                   family = poisson(), data = obs)
  miss <- which(is.na(d$y) & ok)
  if (length(miss)) {
    pred <- predict(fit, newdata = d[miss, ], type = "response")
    # imputed counties belong to no CoC, so clip (no CoC to redistribute within)
    capm <- cap_by_fips[d$fips[miss]]; capm[is.na(capm)] <- Inf
    homeless_counts[[cc]][miss] <- pmin(round(as.numeric(pred)), floor(capm))
  }
  # any remaining NA (pop 0, unmatched) -> 0
  homeless_counts[[cc]][is.na(homeless_counts[[cc]])] <- 0L
}

## ---- ACS covariates (validated mapping; see CLAUDE.md) ----------------------
acs_vars <- c(population = "B01003_001", black = "B02001_003",
              hhunit = "B25001_001", vacanthousing = "B25002_003",
              medhousingval = "B25077_001", monthlycost = "B25105_001",
              hhmedincome = "B19013_001", hhfoodstamp = "B22003_002",
              married_m = "B12001_004", married_f = "B12001_013")
u18 <- c("B01001_003","B01001_004","B01001_005","B01001_006",
         "B01001_027","B01001_028","B01001_029","B01001_030")
araw <- cached_acs(file.path("data-raw/downloads", sprintf("acs%d_county_cov.rds", ACS_END)),
                   "county", year = ACS_END, survey = "acs5", output = "wide",
                variables = c(acs_vars, setNames(u18, u18)),
                geometry = FALSE, progress_bar = FALSE)
ae <- araw[, c("GEOID", paste0(c(names(acs_vars), u18), "E"))]
names(ae) <- sub("E$", "", names(ae))
cov <- ae |> transmute(
  fips = GEOID, population,
  pctblack = black / population * 100,
  pctageunder18 = (B01001_003+B01001_004+B01001_005+B01001_006+
                   B01001_027+B01001_028+B01001_029+B01001_030) / population * 100,
  pctmarried = (married_m + married_f) / population * 100,
  pctvacanthousing = vacanthousing / hhunit * 100,
  pctfoodstamp = hhfoodstamp / hhunit * 100,
  pctmedhousingcost = (monthlycost * 12) / hhmedincome * 100,
  medhousingval = medhousingval / 1000)

## ---- assemble homeless / homeless_na ---------------------------------------
state_names <- setNames(geo$state, geo$fips)
fips_info <- tidycensus::fips_codes |>
  transmute(fips = paste0(state_code, county_code), state_name) |> distinct()

build <- function(counts) {
  out <- counts[, c("state", "fips", cnt_cols)] |>
    left_join(dens[, c("fips", "D")], by = "fips") |>
    left_join(area, by = "fips") |>
    left_join(cov, by = "fips") |>
    mutate(density = D) |>
    left_join(fips_info, by = "fips")
  # Final safety bound (metro-aware): the apportionment water-fills within each
  # CoC so counties already respect their cap, but a county receiving from
  # multiple CoCs could still edge over; clip those rare cases. 3.5% for NYC
  # boroughs and LA County, 2% elsewhere. CoC (hud*) counts are never altered.
  cap <- cap_rate_for(out$fips) * out$population
  for (cc in cnt_cols) {
    over <- !is.na(out$population) & !is.na(out[[cc]]) & out[[cc]] > cap
    out[[cc]][over] <- floor(cap[over])
  }
  out$avg <- rowMeans(out[, cnt_cols], na.rm = TRUE)
  out[, c("state","fips", cnt_cols, "population","density","pctblack",
          "pctageunder18","pctfoodstamp","pctvacanthousing","pctmedhousingcost",
          "medhousingval","pctmarried","avg","state_name")]
}
homeless_na <- build(wide)            # pre-imputation (NA counts retained)
homeless    <- build(homeless_counts) # fully imputed
# Deterministic row order (by fips) so rebuilds and release diffs are stable.
homeless_na <- homeless_na[order(homeless_na$fips), ]
homeless    <- homeless[order(homeless$fips), ]

save(homeless,    file = "data/homeless.rda",    compress = "xz")
save(homeless_na, file = "data/homeless_na.rda", compress = "xz")

## ---- sp_homeless as sf ------------------------------------------------------
sp_homeless <- counties[, "fips"] |>
  left_join(homeless, by = "fips") |>
  st_make_valid()
save(sp_homeless, file = "data/sp_homeless.rda", compress = "xz")

message(sprintf("homeless: %d counties x %d years; imputed cells filled; avg total 2024 = %s",
                nrow(homeless), length(cnt_cols),
                format(sum(homeless$count24, na.rm = TRUE), big.mark = ",")))
