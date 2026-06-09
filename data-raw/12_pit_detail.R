################################################################################
# 12_pit_detail.R
#
# Build the detailed PIT datasets (shelter type x subpopulation, incl. gender,
# race, age, veterans, chronic, youth, families), long format:
#   pit_coc_detail     per CoC, year, shelter, subpopulation, count
#   county_pit_detail  same apportioned to counties via the crosswalk
#
# Subpopulation names are cleaned; the full (year x shelter x subpopulation)
# grid is completed so categories HUD added in later years are NA (not absent)
# in earlier years. Stored as factors + xz for compactness. Run after
# 05_county_estimates.R, 09_pit_coc.R and the detail extract.
################################################################################

suppressMessages({ library(dplyr); library(tidyr) })
stopifnot(dir.exists("data"))

shelter_levels <- c("Overall", "Sheltered Total", "Sheltered ES",
                    "Sheltered TH", "Sheltered SH", "Unsheltered")

d <- utils::read.csv("data-raw/downloads/pit_coc_detail.csv",
                     colClasses = c(coc_num = "character"))
d$shelter <- factor(d$shelter, levels = shelter_levels)
combos <- distinct(d, shelter, subpopulation)
message("shelter x subpop combos: ", nrow(combos),
        " | subpopulations: ", length(unique(d$subpopulation)))

## ---- pit_coc_detail: complete the grid so missing categories are NA ---------
pit_coc_detail <- d |>
  complete(coc_num, year = 2007:2025, combos) |>
  mutate(subpopulation = factor(subpopulation)) |>
  arrange(coc_num, year, subpopulation, shelter) |>
  select(coc_num, year, shelter, subpopulation, count)
save(pit_coc_detail, file = "data/pit_coc_detail.rda", compress = "xz")
message(sprintf("pit_coc_detail: %s rows, %.1f MB",
                format(nrow(pit_coc_detail), big.mark = ","),
                file.size("data/pit_coc_detail.rda") / 1e6))

## ---- county_pit_detail: apportion to counties via the crosswalk ------------
# A county's value for each (shelter, subpopulation) = its apportioned total
# (from `homeless`) times the dominant CoC's (shelter,subpop)/Overall-All ratio.
load("data/homeless.rda")
overall <- d |> filter(shelter == "Overall", subpopulation == "All") |>
  transmute(coc_num, year, coc_total = count)

county_pit_detail <- bind_rows(lapply(2007:2025, function(yr) {
  load(sprintf("data/county_coc%d.rda", yr)); cc <- get(sprintf("county_coc%d", yr))
  dom <- cc |> group_by(fips) |> slice_max(w_county, n = 1, with_ties = FALSE) |>
    ungroup() |> select(fips, COCNUM)
  tot <- homeless |> transmute(fips, county_total = .data[[sprintf("count%02d", yr %% 100)]])
  prof <- d |> filter(year == yr) |>
    inner_join(filter(overall, year == yr), by = c("coc_num", "year")) |>
    filter(coc_total > 0) |>
    transmute(COCNUM = coc_num, shelter, subpopulation, frac = count / coc_total)
  dom |> inner_join(tot, by = "fips") |>
    inner_join(prof, by = "COCNUM") |>
    transmute(fips, year = yr, shelter, subpopulation,
              count = as.integer(round(county_total * frac)))
}))
county_pit_detail$shelter <- factor(county_pit_detail$shelter, levels = shelter_levels)
county_pit_detail$subpopulation <- factor(county_pit_detail$subpopulation)
county_pit_detail <- county_pit_detail |> arrange(fips, year, subpopulation, shelter)
save(county_pit_detail, file = "data/county_pit_detail.rda", compress = "xz")
message(sprintf("county_pit_detail: %s rows, %.1f MB",
                format(nrow(county_pit_detail), big.mark = ","),
                file.size("data/county_pit_detail.rda") / 1e6))
