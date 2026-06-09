# National Point-in-Time homeless totals by shelter status, 2007-2025

United States annual Point-in-Time (PIT) homeless counts split into
sheltered and unsheltered components
(`sheltered + unsheltered = total`). Note the 2021 `unsheltered` figure:
HUD waived the unsheltered count for many Continuum of Care areas during
the COVID-19 pandemic, so 2021 understates true homelessness and is a
natural candidate for time-series imputation.

## Usage

``` r
pit_us
```

## Format

A data frame with one row per year and 4 variables:

- year:

  Year of the count.

- total:

  Overall homeless (PIT).

- sheltered:

  Sheltered homeless (emergency shelter, transitional housing, safe
  haven).

- unsheltered:

  Unsheltered homeless.

## Source

HUD AHAR Part 1 PIT estimates, national totals computed from the
PIT-by-CoC workbook (see
[`hud2007`](https://ssdalab.github.io/COCHomeless/reference/hud.md)).
