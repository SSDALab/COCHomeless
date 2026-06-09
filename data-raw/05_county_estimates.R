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
})
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
pop2010 <- get_decennial("county", variables = "P001001", year = 2010,
                         geometry = FALSE, progress_bar = FALSE) |>
  transmute(fips = GEOID, pop2010 = value)

dens <- geo |> left_join(pop2010, by = "fips") |> left_join(area, by = "fips") |>
  mutate(D = pop2010 / skm)

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

  # Within each CoC, split its PIT count among member counties by population
  # density (paper's volume-preserving estimator), water-filling so no county
  # exceeds its cap and the excess flows to counties with headroom.
  membership |>
    left_join(dens[, c("fips", "D")], by = "fips") |>
    left_join(caps[, c("fips", "cap")], by = "fips") |>
    filter(!is.na(D), D > 0) |>
    left_join(hud, by = c("COCNUM" = "coc_num")) |>
    filter(!is.na(count)) |>
    group_by(COCNUM) |>
    group_modify(~ { .x$cnt <- round_preserve(water_fill(.x$count[1], .x$D, .x$cap)); .x }) |>
    ungroup() |>
    group_by(fips) |> summarise(count = sum(cnt), .groups = "drop") |>
    mutate(year = yr)
}

panel_cache <- "data-raw/downloads/county_panel.rds"
if (file.exists(panel_cache)) {
  message("loading cached apportionment panel")
  panel <- readRDS(panel_cache)
} else {
  message("apportioning ", length(YEARS), " years ...")
  panel <- bind_rows(lapply(YEARS, function(y) { message("  ", y); allocate_year(y) }))
  saveRDS(panel, panel_cache)
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
