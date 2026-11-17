# County-level homeless estimates by shelter status, 2007-2025

County homeless estimates split into sheltered and unsheltered
components (`sheltered + unsheltered = total`), long format. The county
total is the disaggregated estimate from
[`homeless`](https://ssdalab.github.io/COCHomeless/reference/homeless.md);
it is split using the shelter ratio of the CoC the county was
apportioned from (its primary CoC in
[`county_coc_alloc`](https://ssdalab.github.io/COCHomeless/reference/county_coc_alloc.md),
with
[`pit_coc`](https://ssdalab.github.io/COCHomeless/reference/pit_coc.md)).
Counties with no CoC (imputed in `homeless`) use the national ratio.
Join to county geography by `fips` (e.g.
[`counties`](https://ssdalab.github.io/COCHomeless/reference/counties.md)
or
[`sp_homeless`](https://ssdalab.github.io/COCHomeless/reference/sp_homeless.md));
the same sheltered/unsheltered values are also carried on `sp_homeless`
as `sheltered<yy>` / `unsheltered<yy>`.

## Usage

``` r
county_pit
```

## Format

A data frame with one row per county-year and 8 variables:

- fips:

  5-digit county FIPS code.

- year:

  Year.

- total:

  Estimated total homeless.

- sheltered:

  Estimated sheltered homeless.

- unsheltered:

  Estimated unsheltered homeless.

- total_imp:

  `sheltered + unsheltered_imp`.

- unsheltered_imp:

  `unsheltered` plus the county's share of its CoCs' imputed 2021
  unsheltered people, split exactly as the county estimates are
  ([`county_coc_alloc`](https://ssdalab.github.io/COCHomeless/reference/county_coc_alloc.md)).

- unsheltered_imputed:

  `TRUE` if `unsheltered_imp` includes imputed people. Only ever `TRUE`
  in 2021. Counties with no CoC (imputed by the spatial model in
  `homeless`) are not adjusted.

## Source

HUD PIT counts disaggregated to counties; see
[`homeless`](https://ssdalab.github.io/COCHomeless/reference/homeless.md).

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
