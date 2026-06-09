# County-level homeless estimates, 2007-2025 (pre-imputation, with missing values)

Identical to
[`homeless`](https://ssdalab.github.io/COCHomeless/reference/homeless.md)
but *before* imputation: counties that overlapped no HUD Continuum of
Care in a given year retain a missing (`NA`) count for that year. This
is the input to the spatial-Poisson imputation step that produces
`homeless`.

## Usage

``` r
homeless_na
```

## Format

A data frame with 3143 rows and the same columns as
[`homeless`](https://ssdalab.github.io/COCHomeless/reference/homeless.md);
the yearly `count07`–`count25` columns contain `NA` for counties with no
CoC coverage that year (about 1–3 percent of counties).

## Source

HUD Point-in-Time data (see
[`hud2007`](https://ssdalab.github.io/COCHomeless/reference/hud.md))
disaggregated to counties; ACS covariates via tidycensus.
