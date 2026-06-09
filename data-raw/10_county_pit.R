################################################################################
# 10_county_pit.R
#
# Build county_pit: county-level PIT homeless estimates split by shelter status
# (total / sheltered / unsheltered), long format, 2007-2025.
#
# The county TOTAL comes from `homeless` (CoC counts disaggregated to counties).
# It is split into sheltered/unsheltered using the shelter ratio of the county's
# dominant CoC that year (from `county_coc<year>` + `pit_coc`); counties with no
# CoC fall back to the national ratio (`pit_us`). sheltered + unsheltered = total
# exactly. Run from the package root after 05_county_estimates.R and 09_pit_coc.R.
################################################################################

suppressMessages(library(dplyr))
stopifnot(dir.exists("data"))
load("data/homeless.rda"); load("data/pit_coc.rda"); load("data/pit_us.rda")
YEARS <- 2007:2025

# national sheltered fraction per year (fallback for no-CoC counties)
nat_sh <- setNames(pit_us$sheltered / pit_us$total, pit_us$year)

county_pit <- bind_rows(lapply(YEARS, function(yr) {
  load(sprintf("data/county_coc%d.rda", yr)); cc <- get(sprintf("county_coc%d", yr))
  dom <- cc |> group_by(fips) |> slice_max(w_county, n = 1, with_ties = FALSE) |>
    ungroup() |> select(fips, COCNUM)
  ratio <- pit_coc |> filter(year == yr, total > 0) |>
    transmute(COCNUM = coc_num, sh = sheltered / total)
  tot_col <- sprintf("count%02d", yr %% 100)
  homeless |>
    transmute(fips, total = .data[[tot_col]]) |>
    left_join(dom, by = "fips") |>
    left_join(ratio, by = "COCNUM") |>
    mutate(sh = ifelse(is.na(sh), nat_sh[as.character(yr)], sh),
           year = yr,
           sheltered = round(total * sh),
           unsheltered = total - sheltered) |>
    select(fips, year, total, sheltered, unsheltered)
}))
county_pit <- county_pit[order(county_pit$fips, county_pit$year), ]
rownames(county_pit) <- NULL

save(county_pit, file = "data/county_pit.rda", compress = "xz")
message(sprintf("county_pit: %d rows (%d counties x %d years); sheltered+unsheltered==total: %s",
                nrow(county_pit), length(unique(county_pit$fips)), length(YEARS),
                all(county_pit$sheltered + county_pit$unsheltered == county_pit$total)))
