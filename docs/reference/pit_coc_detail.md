# Detailed CoC Point-in-Time counts by shelter type and subpopulation

HUD Point-in-Time counts for each Continuum of Care (CoC) and year,
broken down by shelter type and subpopulation – including household type
(individuals, families), veterans, chronically homeless, youth, and the
demographic breakdowns HUD reports (gender, race/ethnicity, age). Long
format, one row per CoC x year x shelter x subpopulation.

## Usage

``` r
pit_coc_detail
```

## Format

A data frame with one row per CoC-year-shelter-subpopulation and 5
variables:

- coc_num:

  CoC number, e.g. `"WA-500"`.

- year:

  Year.

- shelter:

  Shelter type: `Overall`, `Sheltered Total`, `Sheltered ES` (emergency
  shelter), `Sheltered TH` (transitional housing), `Sheltered SH` (safe
  haven), or `Unsheltered`.

- subpopulation:

  Subpopulation / demographic category (`All` for the unrestricted
  count).

- count:

  Number of people (`NA` if not collected that year).

## Source

HUD AHAR Part 1 PIT estimates, from the PIT-by-CoC workbook (see
[`hud2007`](https://ssdalab.github.io/COCHomeless/reference/hud.md)).

## Details

The grid is completed across years, so a subpopulation HUD only began
reporting in a later year (or a category whose definition changed, e.g.
the 2023 race/ethnicity revision) is `NA` in years it was not collected
rather than missing. Join to CoC geography by `coc_num` (=
`coc2024$COCNUM`); for a county version see
[`county_pit_detail`](https://ssdalab.github.io/COCHomeless/reference/county_pit_detail.md).
