# National Point-in-Time homeless totals by shelter status, 2007-2025

United States annual Point-in-Time (PIT) homeless counts split into
sheltered and unsheltered components
(`sheltered + unsheltered = total`). The 2021 official `unsheltered`
figure understates homelessness because HUD waived the unsheltered count
for many CoCs during COVID-19; the `_imp` columns add the imputed
unsheltered people of the 159 affected CoCs.

## Usage

``` r
pit_us
```

## Format

A data frame with one row per year and 7 variables:

- year:

  Year of the count.

- total:

  Overall homeless (PIT), as published by HUD.

- sheltered:

  Sheltered homeless (emergency shelter, transitional housing, safe
  haven).

- unsheltered:

  Unsheltered homeless, as published by HUD.

- n_coc_imputed:

  Number of CoCs whose unsheltered count was imputed that year (non-zero
  only in 2021).

- unsheltered_imp:

  `unsheltered` plus the imputed CoC values; the sum of
  [`pit_coc`](https://ssdalab.github.io/COCHomeless/reference/pit_coc.md)`$unsheltered_imp`.

- total_imp:

  `sheltered + unsheltered_imp`.

## Source

HUD AHAR Part 1 PIT estimates, national totals computed from the
PIT-by-CoC workbook (see
[`hud2007`](https://ssdalab.github.io/COCHomeless/reference/hud.md)).

## Imputed 2021 unsheltered counts

HUD's COVID-19 waiver let CoCs skip the 2021 unsheltered count, and many
report 0. The `_imp` columns carry an estimate for those CoC-years;
HUD's official `total`, `sheltered` and `unsheltered` are never
modified. A 2021 zero is imputed only when the CoC counted unsheltered
people in the years either side (159 CoCs, including territory CoCs);
the estimate is a once-differenced ARIMA on `log(1 + unsheltered)` with
Kalman smoothing, so both earlier and later years inform it. In a
holdout test (2019 and 2023 hidden and re-imputed for the same CoCs) it
was 3-4% low in total with a 15-17% median per-CoC error. Use the
official columns to reproduce HUD; use the `_imp` columns for trends
across 2021. The same note is attached to the data as `attr(x, "note")`.
See
[`vignette("unsheltered-imputation", package = "COCHomeless")`](https://ssdalab.github.io/COCHomeless/articles/unsheltered-imputation.md).
