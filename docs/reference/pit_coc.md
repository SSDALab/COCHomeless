# Per-CoC Point-in-Time homeless counts by shelter status, 2007-2025

HUD Point-in-Time (PIT) homeless counts for each Continuum of Care (CoC)
and year, split into sheltered and unsheltered components
(`sheltered + unsheltered = total`), in long format. Complements the
CoC-total
[`hud2007`](https://ssdalab.github.io/COCHomeless/reference/hud.md)
objects and the national
[`pit_us`](https://ssdalab.github.io/COCHomeless/reference/pit_us.md)
series. Note the 2021 `unsheltered` values: HUD waived the unsheltered
count for many CoCs during COVID-19, so many CoCs report 0 unsheltered
in 2021.

## Usage

``` r
pit_coc
```

## Format

A data frame with one row per CoC-year and 5 variables:

- coc_num:

  CoC number, e.g. `"WA-500"`.

- year:

  Year of the count.

- total:

  Overall homeless (PIT).

- sheltered:

  Sheltered homeless.

- unsheltered:

  Unsheltered homeless.

## Source

HUD AHAR Part 1 PIT estimates, from the PIT-by-CoC workbook (see
[`hud2007`](https://ssdalab.github.io/COCHomeless/reference/hud.md)).
