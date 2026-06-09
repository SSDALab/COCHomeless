################################################################################
# 04_acs_tidycensus.R
#
# Pull county-level American Community Survey (ACS) 5-year covariates with
# tidycensus and rebuild the raw covariate table + the derived columns used by
# `homeless` / `sp_homeless`.
#
# The derived-column formulas were reverse-engineered exactly from the legacy
# data (see CLAUDE.md). This script reproduces them so the schema is identical.
#
# Requires CENSUS_API_KEY in ~/.Renviron (tidycensus reads it automatically).
# Set ACS_END_YEAR for the 5-year ACS end year (default 2022 -> 2018-2022).
# Run from the package root (COCHomeless/).
################################################################################

suppressMessages({ library(tidycensus); library(dplyr); library(tidyr) })
stopifnot(dir.exists("data"))

end_year <- as.integer(Sys.getenv("ACS_END_YEAR", "2022"))

# ---- ACS variable map ------------------------------------------------------
# Each raw column in data-raw/ACS_Variables.csv -> its ACS table variable(s).
vars <- c(
  population    = "B01003_001",   # total population
  white         = "B02001_002",
  black         = "B02001_003",
  asian         = "B02001_005",
  hispanic      = "B03003_003",
  married_m     = "B12001_004",   # males now married  (summed -> married)
  married_f     = "B12001_013",   # females now married
  hhunit        = "B25001_001",   # housing units
  vacanthousing = "B25002_003",   # vacant units
  medhousingval = "B25077_001",   # median value (owner-occupied)
  monthlycost   = "B25105_001",   # median monthly housing costs (x12 -> annual)
  hhmedincome   = "B19013_001",   # median household income
  hhfoodstamp   = "B22003_002"    # households receiving SNAP in past 12 months
)
# under-18 = sum of the under-18 age brackets, sex by age (B01001)
under18 <- c("B01001_003","B01001_004","B01001_005","B01001_006",   # male <5..15-17
             "B01001_027","B01001_028","B01001_029","B01001_030")   # female

raw <- get_acs(geography = "county", year = end_year, survey = "acs5",
               variables = c(vars, setNames(under18, under18)),
               output = "wide", geometry = FALSE)

est <- raw[, c("GEOID", paste0(names(c(vars, setNames(under18, under18))), "E"))]
names(est) <- sub("E$", "", names(est))

acs <- transmute(
  est,
  fips          = GEOID,
  population,
  white, black, asian, hispanic,
  ageunder18    = B01001_003 + B01001_004 + B01001_005 + B01001_006 +
                  B01001_027 + B01001_028 + B01001_029 + B01001_030,
  married       = married_m + married_f,
  hhunit, vacanthousing,
  medhousingval = medhousingval / 1000,        # store in $1,000s (legacy units)
  hhmedhousingcost = monthlycost * 12,         # annual (legacy units)
  hhmedincome, hhfoodstamp
)

write.csv(acs, "data-raw/ACS_Variables.csv", row.names = FALSE)
message(sprintf("ACS %d-%d: %d counties written to data-raw/ACS_Variables.csv",
                end_year - 4, end_year, nrow(acs)))

# NOTE: pctage18to24highschool and pctmarriedbothwork are stored as ready-made
# percentages in the legacy file. They require their own tables (B15001 for
# 18-24 educational attainment; B23007 for married-couple labor force) and are
# computed in a follow-up block once their exact legacy definitions are
# confirmed against the 2010-2014 values. TODO before final county rebuild.
