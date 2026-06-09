# Detailed county Point-in-Time estimates by shelter type and subpopulation

The shelter-type and subpopulation breakdowns of
[`pit_coc_detail`](https://ssdalab.github.io/COCHomeless/reference/pit_coc_detail.md)
apportioned to counties through the Census-to-CoC crosswalk. A county's
value for each (shelter, subpopulation) is its disaggregated total (from
[`homeless`](https://ssdalab.github.io/COCHomeless/reference/homeless.md))
scaled by its dominant CoC's share of that category. Long format; join
to county geography by `fips` (e.g.
[`counties`](https://ssdalab.github.io/COCHomeless/reference/counties.md)).

## Usage

``` r
county_pit_detail
```

## Format

A data frame with one row per county-year-shelter-subpopulation and 5
variables:

- fips:

  5-digit county FIPS code.

- year:

  Year.

- shelter:

  Shelter type (see
  [`pit_coc_detail`](https://ssdalab.github.io/COCHomeless/reference/pit_coc_detail.md)).

- subpopulation:

  Subpopulation / demographic category.

- count:

  Estimated number of people.

## Source

HUD PIT subpopulation counts
([`pit_coc_detail`](https://ssdalab.github.io/COCHomeless/reference/pit_coc_detail.md))
apportioned to counties; see
[`homeless`](https://ssdalab.github.io/COCHomeless/reference/homeless.md).
