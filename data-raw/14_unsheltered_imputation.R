################################################################################
# 14_unsheltered_imputation.R
#
# Impute the unsheltered counts HUD's 2021 COVID waiver left missing, and add
# them to pit_coc, county_pit and pit_us as NEW, FLAGGED columns. HUD's official
# sheltered / unsheltered / total columns are never modified.
#
# What is imputed. In 2021 HUD let CoCs skip the unsheltered count; 167 CoCs
# report 0 unsheltered (against 3-11 in a normal year). A 2021 zero is treated
# as MISSING when the CoC reported unsheltered people in both neighbouring
# years with data (flag_missing_unsheltered); a CoC that genuinely never finds
# unsheltered people keeps its zero. Nothing outside 2021 is imputed.
#
# How. Per CoC, the unsheltered series 2007-2025 is modelled on log(1 + y) with
# an automatically selected ARIMA (forecast::auto.arima) and the missing year is
# filled by Kalman smoothing (imputeTS::na_kalman), so later years inform the
# estimate as well as earlier ones. Series too short to fit (< 6 observed years)
# fall back to linear interpolation on the log scale. See
# data-raw/00_build_helpers.R::impute_unsheltered_arima and the vignette
# "Imputing the 2021 unsheltered count".
#
# County level. The imputed CoC addition (unsheltered_imp - unsheltered) is
# apportioned to counties with exactly the split the county estimates used
# (county_coc_alloc), rounded to preserve each CoC's addition. Counties with no
# CoC (imputed by the spatial model) are not changed.
#
# Run from the package root AFTER 05, 09, 10 (it adds columns to their output;
# re-running 09 or 10 drops them, so re-run this script afterwards).
################################################################################

suppressMessages(library(dplyr))
source("data-raw/00_build_helpers.R")
stopifnot(requireNamespace("forecast"), requireNamespace("imputeTS"))
load("data/pit_coc.rda"); load("data/county_pit.rda"); load("data/pit_us.rda")
load("data/county_coc_alloc.rda")
set.seed(20211)   # auto.arima is deterministic; seed kept for any stochastic fallback

NOTE <- paste(
  "unsheltered_imp / total_imp: HUD's 2021 COVID waiver let CoCs skip the",
  "unsheltered count. Where a CoC reported 0 unsheltered in 2021 but counted",
  "unsheltered people in the years either side, unsheltered_imp is an ARIMA /",
  "Kalman-smoothed estimate (flag unsheltered_imputed = TRUE). Everywhere else",
  "unsheltered_imp == unsheltered. HUD's official columns are unchanged.",
  "See vignette('unsheltered-imputation', package = 'COCHomeless').")

## ---- CoC level ---------------------------------------------------------------
drop_cols <- c("unsheltered_imp", "total_imp", "unsheltered_imputed", "imputation_method")
pit_coc <- pit_coc[, setdiff(names(pit_coc), drop_cols)]
pit_coc <- pit_coc[order(pit_coc$coc_num, pit_coc$year), ]

res <- lapply(split(pit_coc, pit_coc$coc_num), function(d) {
  miss <- flag_missing_unsheltered(d$year, d$unsheltered)
  r <- impute_unsheltered_arima(d$year, d$unsheltered, miss)
  data.frame(coc_num = d$coc_num, year = d$year,
             unsheltered_imp = as.integer(r$value),
             unsheltered_imputed = miss, imputation_method = r$method)
})
imp <- do.call(rbind, res)
pit_coc <- pit_coc |>
  left_join(imp, by = c("coc_num", "year")) |>
  mutate(total_imp = as.integer(sheltered + unsheltered_imp)) |>
  select(coc_num, year, total, sheltered, unsheltered,
         total_imp, unsheltered_imp, unsheltered_imputed, imputation_method) |>
  as.data.frame()
rownames(pit_coc) <- NULL
stopifnot(all(pit_coc$unsheltered_imp[!pit_coc$unsheltered_imputed] ==
                pit_coc$unsheltered[!pit_coc$unsheltered_imputed]),
          all(pit_coc$year[pit_coc$unsheltered_imputed] == 2021L),
          all(pit_coc$unsheltered_imp >= 0))
attr(pit_coc, "note") <- NOTE

n_imp <- sum(pit_coc$unsheltered_imputed)
add_coc <- pit_coc |> filter(unsheltered_imputed) |>
  transmute(coc_num, year, add = unsheltered_imp - unsheltered)
message(sprintf("pit_coc: imputed %d CoC-years (%s by method), adding %s unsheltered people in 2021",
                n_imp, paste(names(table(pit_coc$imputation_method)), table(pit_coc$imputation_method),
                             collapse = "/"),
                format(sum(add_coc$add), big.mark = ",")))

## ---- county level --------------------------------------------------------------
# Split each imputed CoC's addition over its counties in proportion to the
# people the build apportioned from that CoC.
cadd <- county_coc_alloc |>
  inner_join(add_coc, by = c("coc_num", "year")) |>
  group_by(coc_num, year) |>
  mutate(w = if (sum(count) > 0) count / sum(count) else rep(1 / n(), n()),
         cadd = round_preserve(add[1] * w)) |>
  ungroup() |>
  group_by(fips, year) |> summarise(cadd = sum(cadd), .groups = "drop")
# Territory CoCs (GU, MP, PR, VI, AS) have no counties in the county frame; their
# addition stays at CoC and national level only.
terr <- substr(add_coc$coc_num, 1, 2) %in% c("AS", "GU", "MP", "PR", "VI")
stopifnot(sum(cadd$cadd) == sum(add_coc$add[!terr]))

county_pit <- county_pit[, setdiff(names(county_pit), drop_cols)]
county_pit <- county_pit |>
  left_join(cadd, by = c("fips", "year")) |>
  mutate(unsheltered_imputed = !is.na(cadd) & cadd > 0,
         # same storage type as the official county columns (double)
         unsheltered_imp = unsheltered + as.numeric(coalesce(cadd, 0L)),
         total_imp = sheltered + unsheltered_imp) |>
  select(fips, year, total, sheltered, unsheltered,
         total_imp, unsheltered_imp, unsheltered_imputed) |>
  as.data.frame()
attr(county_pit, "note") <- NOTE
message(sprintf("county_pit: %d county-years carry imputed unsheltered people",
                sum(county_pit$unsheltered_imputed)))

## ---- national ------------------------------------------------------------------
nat <- pit_coc |> group_by(year) |>
  summarise(unsheltered_imp_add = sum(unsheltered_imp - unsheltered),
            n_coc_imputed = sum(unsheltered_imputed), .groups = "drop")
pit_us <- pit_us[, setdiff(names(pit_us), c("total_imp", "unsheltered_imp", "n_coc_imputed"))]
pit_us <- pit_us |> left_join(nat, by = "year") |>
  mutate(unsheltered_imp = as.integer(unsheltered + unsheltered_imp_add),
         total_imp = as.integer(sheltered + unsheltered_imp),
         n_coc_imputed = as.integer(n_coc_imputed)) |>
  select(-unsheltered_imp_add) |> as.data.frame()
attr(pit_us, "note") <- NOTE

save(pit_coc,    file = "data/pit_coc.rda",    compress = "xz")
save(county_pit, file = "data/county_pit.rda", compress = "xz")
save(pit_us,     file = "data/pit_us.rda",     compress = "xz")
print(pit_us[pit_us$year %in% 2019:2023, ])

## ---- holdout validation, published for the vignette ----------------------------
# Hide a year that WAS fully counted, re-impute it with the same method, and
# compare. Run on the same CoCs that were imputed for 2021.
ids <- unique(pit_coc$coc_num[pit_coc$unsheltered_imputed])
bt <- rbind(backtest_unsheltered(pit_coc, ids, 2019L),
            backtest_unsheltered(pit_coc, ids, 2023L))
dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
utils::write.csv(bt, "inst/extdata/unsheltered_backtest.csv", row.names = FALSE)
for (h in unique(bt$hold_year)) {
  b <- bt[bt$hold_year == h, ]
  message(sprintf("backtest %d: n=%d, median abs error %.1f%%, total error %+.1f%%, within 25%%: %.0f%%",
                  h, nrow(b), 100 * median(abs(b$imputed - b$actual) / b$actual),
                  100 * (sum(b$imputed) - sum(b$actual)) / sum(b$actual),
                  100 * mean(abs(b$imputed - b$actual) / b$actual < 0.25)))
}
