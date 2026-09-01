################################################################################
# 10_county_pit.R
#
# Build county_pit: county-level PIT homeless estimates split by shelter status
# (total / sheltered / unsheltered), long format, 2007-2025.
#
# The county TOTAL comes from `homeless` (CoC counts disaggregated to counties).
# It is split into sheltered/unsheltered using the shelter ratio of the county's
# PRIMARY CoC that year, taken from the membership 05_county_estimates.R actually
# apportioned with (data-raw/downloads/county_primary_coc.rds). This file used to
# recompute a dominant CoC of its own from county_coc<year>$w_county, which could
# name a different CoC than the count came from -- and, because the crosswalk was
# on a different county-FIPS vintage, matched nothing at all in Connecticut.
# Counties with no CoC fall back to the national ratio (`pit_us`).
# sheltered + unsheltered = total exactly.
# Run from the package root after 05_county_estimates.R and 09_pit_coc.R.
################################################################################

suppressMessages(library(dplyr))
stopifnot(dir.exists("data"))
load("data/homeless.rda"); load("data/pit_coc.rda"); load("data/pit_us.rda")
YEARS <- 2007:2025

prim_cache <- "data-raw/downloads/county_primary_coc.rds"
if (!file.exists(prim_cache))
  stop("missing ", prim_cache, " -- run data-raw/05_county_estimates.R first")
primary <- readRDS(prim_cache)

# Two different reasons a county can miss its CoC shelter ratio:
#
#  * it has no primary CoC at all -- this is the join-broke signal, and is what
#    silently zeroed Connecticut, so it is a hard error;
#  * its primary CoC reported no PIT count that year -- legitimate and historical
#    (69 CoCs had boundaries but no PIT in 2007, down to 3 by 2024), so the
#    national ratio is used and the rate is logged, not enforced.
no_coc <- 0L; no_ratio <- 0L

# national sheltered fraction per year (fallback for no-CoC counties)
nat_sh <- setNames(pit_us$sheltered / pit_us$total, pit_us$year)

county_pit <- bind_rows(lapply(YEARS, function(yr) {
  dom <- primary |> filter(year == yr) |> select(fips, COCNUM)
  ratio <- pit_coc |> filter(year == yr, total > 0) |>
    transmute(COCNUM = coc_num, sh = sheltered / total)
  tot_col <- sprintf("count%02d", yr %% 100)
  homeless |>
    transmute(fips, total = .data[[tot_col]]) |>
    left_join(dom, by = "fips") |>
    left_join(ratio, by = "COCNUM") |>
    mutate(unkeyed = is.na(COCNUM),
           fallback = is.na(sh) & total > 0,
           sh = ifelse(is.na(sh), nat_sh[as.character(yr)], sh),
           year = yr,
           sheltered = round(total * sh),
           unsheltered = total - sheltered) |>
    (\(d) { no_coc <<- no_coc + sum(d$unkeyed)
            no_ratio <<- no_ratio + sum(d$fallback & !d$unkeyed); d })() |>
    select(fips, year, total, sheltered, unsheltered)
}))

# No state may be missing from the apportionment in any year. A whole state
# going dark is exactly the Connecticut failure, and it is far too small a share
# of the national panel for a percentage threshold to catch.
by_state <- county_pit |>
  mutate(st = substr(fips, 1, 2)) |>
  group_by(st, year) |> summarise(any_pos = any(total > 0), .groups = "drop") |>
  filter(!any_pos)
if (nrow(by_state))
  stop("state-years with no positive county count anywhere: ",
       paste(sprintf("%s/%d", by_state$st, by_state$year), collapse = ", "))

if (no_coc > 0.005 * nrow(county_pit))
  stop(sprintf("%d of %d county-years have no primary CoC (>0.5%%) -- broken join",
               no_coc, nrow(county_pit)))
message(sprintf("  no primary CoC: %d county-years (%.2f%%); CoC did not report a PIT count: %d (%.2f%%)",
                no_coc, 100 * no_coc / nrow(county_pit),
                no_ratio, 100 * no_ratio / nrow(county_pit)))
county_pit <- county_pit[order(county_pit$fips, county_pit$year), ]
rownames(county_pit) <- NULL

save(county_pit, file = "data/county_pit.rda", compress = "xz")
message(sprintf("county_pit: %d rows (%d counties x %d years); sheltered+unsheltered==total: %s",
                nrow(county_pit), length(unique(county_pit$fips)), length(YEARS),
                all(county_pit$sheltered + county_pit$unsheltered == county_pit$total)))
