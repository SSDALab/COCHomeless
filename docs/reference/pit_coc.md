# Per-CoC Point-in-Time homeless counts by shelter status, 2007-2025

HUD Point-in-Time (PIT) homeless counts for each Continuum of Care (CoC)
and year, split into sheltered and unsheltered components
(`sheltered + unsheltered = total`), in long format. Complements the
CoC-total
[`hud2007`](https://ssdalab.github.io/COCHomeless/reference/hud.md)
objects and the national
[`pit_us`](https://ssdalab.github.io/COCHomeless/reference/pit_us.md)
series.

## Usage

``` r
pit_coc
```

## Format

A data frame with one row per CoC-year and 9 variables:

- coc_num:

  CoC number, e.g. `"WA-500"`.

- year:

  Year of the count.

- total:

  Overall homeless (PIT), as published by HUD.

- sheltered:

  Sheltered homeless, as published by HUD.

- unsheltered:

  Unsheltered homeless, as published by HUD.

- total_imp:

  `sheltered + unsheltered_imp`. Equals `total` except where
  `unsheltered_imputed` is `TRUE`.

- unsheltered_imp:

  Unsheltered homeless with the 2021 waiver gap imputed. Equals
  `unsheltered` except where `unsheltered_imputed` is `TRUE`.

- unsheltered_imputed:

  `TRUE` if `unsheltered_imp` is an imputed value, not a HUD count. Only
  ever `TRUE` in 2021.

- imputation_method:

  `"arima_kalman"`, or `"log_linear_interp"` for series too short to fit
  an ARIMA; `NA` for HUD counts.

## Source

HUD AHAR Part 1 PIT estimates, from the PIT-by-CoC workbook (see
[`hud2007`](https://ssdalab.github.io/COCHomeless/reference/hud.md)).
Imputation: `data-raw/14_unsheltered_imputation.R`.

## Details

**2021:** HUD waived the unsheltered count for many CoCs during
COVID-19, so many CoCs report 0 unsheltered in 2021. The official
columns keep HUD's figures; `unsheltered_imp` / `total_imp` carry a
flagged imputation (see the section below).

## Imputed 2021 unsheltered counts

HUD's COVID-19 waiver let CoCs skip the 2021 unsheltered count, and many
report 0. The `_imp` columns carry an estimate for those CoC-years;
HUD's official `total`, `sheltered` and `unsheltered` are never
modified. A 2021 zero is imputed only when the CoC counted unsheltered
people in the years either side (159 CoCs); the estimate is a
once-differenced ARIMA on `log(1 + unsheltered)` with Kalman smoothing,
so both earlier and later years inform it. In a holdout test (2019 and
2023 hidden and re-imputed for the same CoCs) it was 3-4% low in total
with a 15-17% median per-CoC error. Use the official columns to
reproduce HUD; use the `_imp` columns for trends across 2021. The same
note is attached to the data as `attr(x, "note")`. See
[`vignette("unsheltered-imputation", package = "COCHomeless")`](https://ssdalab.github.io/COCHomeless/articles/unsheltered-imputation.md).
