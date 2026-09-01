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

## ---- plausibility caps (metro-aware) ---------------------------------------
# Max homeless per county = cap_rate * ACS population. New York City's boroughs
# and Los Angeles County -- dense major-metro cores with genuinely high
# homelessness -- get 3.5%; every other county 2%. Excess above a county's cap
# is redistributed within its CoC (water-filling) so the CoC's PIT total is
# preserved rather than discarded.
METRO_FIPS <- c("36061", "36047", "36081", "36005", "36085",  # NYC boroughs
                "06037")                                       # Los Angeles
cap_rate_for <- function(fips) ifelse(fips %in% METRO_FIPS, 0.035, 0.02)
pop_acs <- get_acs("county", variables = "B01003_001", year = ACS_END,
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
  system2(Sys.which("python3"),
          c("data-raw/pit_state_extract.py", shQuote(xlsb), shQuote(state_csv)))
}
hud_state <- utils::read.csv(state_csv)
usps <- setNames(counties$STUSPS, counties$STATEFP)

state_split <- function(yr, hud) {
  own <- tapply(hud$count, substr(as.character(hud$coc_num), 1, 2), sum)
  hs <- hud_state[hud_state$year == yr, ]
  resid <- setNames(hs$total - ifelse(is.na(own[hs$state]), 0, own[hs$state]), hs$state)
  hosts <- names(resid)[!is.na(resid) & resid > 0]
  if (!length(hosts)) return(NULL)
  cc <- local({ load(sprintf("data/county_coc%d.rda", yr))
                get(sprintf("county_coc%d", yr)) })
  cc$ST <- usps[substr(cc$fips, 1, 2)]
  out <- NULL
  for (s in hosts) {
    cand <- cc[!is.na(cc$ST) & cc$ST == s & substr(cc$COCNUM, 1, 2) != s, ]
    if (!nrow(cand)) next
    a <- tapply(cand$area_m2, cand$COCNUM, sum)
    coc <- names(a)[which.max(a)]
    tot <- hud$count[as.character(hud$coc_num) == coc]
    if (!length(tot)) next
    out <- rbind(out,
                 data.frame(COCNUM = coc, ST = s, cnt = resid[[s]]),
                 data.frame(COCNUM = coc, ST = substr(coc, 1, 2),
                            cnt = tot - resid[[s]]))
  }
  out
}

## ---- largest-remainder rounding that preserves a group total ----------------
round_preserve <- function(x) {
  f <- floor(x); need <- round(sum(x)) - sum(f)
  if (need > 0) { o <- order(x - f, decreasing = TRUE)[seq_len(need)]; f[o] <- f[o] + 1 }
  as.integer(f)
}

## ---- water-filling: split a CoC total across its counties by population
## density, subject to per-county caps, pushing any excess onto the counties
## that still have headroom. Conserves the CoC total when capacity allows. ----
water_fill <- function(total, D, cap) {
  n <- length(D); alloc <- numeric(n); active <- rep(TRUE, n); rem <- total
  cap[is.na(cap)] <- Inf; it <- 0
  while (rem > 1e-6 && any(active) && it < 200) {
    it <- it + 1
    sa <- sum(D[active]); if (sa <= 0) break
    give <- numeric(n); give[active] <- rem * D[active] / sa
    prov <- alloc + give
    over <- active & (prov > cap + 1e-9)
    if (!any(over)) { alloc <- prov; rem <- 0 }
    else {
      rem <- rem - sum(cap[over] - alloc[over])
      alloc[over] <- cap[over]; active[over] <- FALSE
    }
  }
  alloc
}

co5070 <- st_make_valid(st_transform(counties[, "fips"], 5070))

## ---- per-year apportionment -------------------------------------------------
allocate_year <- function(yr) {
  load(sprintf("data/coc%d.rda", yr)); coc <- get(sprintf("coc%d", yr))
  load(sprintf("data/hud%d.rda", yr)); hud <- get(sprintf("hud%d", yr))
  cc <- st_make_valid(st_transform(coc[, "COCNUM"], 5070))
  int <- st_intersection(co5070, cc)
  int$a <- as.numeric(st_area(int))
  ov <- st_drop_geometry(int) |> filter(a > 0)

  # Each county's PRIMARY CoC = the CoC covering the largest share of it. This
  # avoids attributing a CoC to counties it only slivers into (raw density
  # weighting otherwise hands a dense neighbor a CoC that isn't really there).
  dom <- ov |> group_by(fips) |> slice_max(a, n = 1, with_ties = FALSE) |>
    ungroup() |> select(fips, COCNUM)

  # Sub-county / nested CoCs (e.g. Long Beach inside LA County) are nobody's
  # primary CoC; assign each to the county that contains most of it, so its
  # count is not lost.
  orphan <- setdiff(unique(hud$coc_num), dom$COCNUM)
  orphan_assign <- ov |> filter(COCNUM %in% orphan) |>
    group_by(COCNUM) |> slice_max(a, n = 1, with_ties = FALSE) |>
    ungroup() |> select(fips, COCNUM)

  membership <- bind_rows(dom, orphan_assign) |> distinct(fips, COCNUM)

  # Each county's PRIMARY CoC, exported so that 10_county_pit.R and
  # 12_pit_detail.R split the same county the same way. They used to recompute a
  # dominant CoC of their own from county_coc<year>$w_county, which could pick a
  # different CoC than the one the count was actually apportioned from.
  primary <<- bind_rows(primary, mutate(dom, year = yr))

  # Within each CoC, split its PIT count among member counties by population
  # density (paper's volume-preserving estimator), water-filling so no county
  # exceeds its cap and the excess flows to counties with headroom.
  # For a CoC that HUD reports split across states, allocate each state's
  # published portion within that state's member counties only.
  spl <- state_split(yr, hud)

  membership |>
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
    ungroup() |>
    group_by(fips) |> summarise(count = sum(cnt), .groups = "drop") |>
    mutate(year = yr)
}

panel_cache <- "data-raw/downloads/county_panel.rds"
prim_cache  <- "data-raw/downloads/county_primary_coc.rds"
primary <- NULL
if (file.exists(panel_cache) && file.exists(prim_cache)) {
  message("loading cached apportionment panel")
  panel <- readRDS(panel_cache)
} else {
  message("apportioning ", length(YEARS), " years ...")
  panel <- bind_rows(lapply(YEARS, function(y) { message("  ", y); allocate_year(y) }))
  saveRDS(panel, panel_cache)
  saveRDS(primary, prim_cache)
}

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
araw <- get_acs("county", year = ACS_END, survey = "acs5", output = "wide",
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
