# County-level homeless estimates by shelter status, 2007-2025

County homeless estimates split into sheltered and unsheltered
components (`sheltered + unsheltered = total`), long format. The county
total is the disaggregated estimate from
[`homeless`](https://ssdalab.github.io/COCHomeless/reference/homeless.md);
it is split using the shelter ratio of the county's dominant CoC (from
the crosswalk
[`county_coc2019`](https://ssdalab.github.io/COCHomeless/reference/county_coc.md)
and
[`pit_coc`](https://ssdalab.github.io/COCHomeless/reference/pit_coc.md)).
Join to county geography by `fips` (e.g.
[`counties`](https://ssdalab.github.io/COCHomeless/reference/counties.md)
or
[`sp_homeless`](https://ssdalab.github.io/COCHomeless/reference/sp_homeless.md));
the same sheltered/unsheltered values are also carried directly on
`sp_homeless` as `sheltered<yy>` / `unsheltered<yy>`. Note the 2021
`unsheltered` values reflect HUD's COVID-19 unsheltered-count waiver.

## Usage

``` r
county_pit
```

## Format

A data frame with one row per county-year and 5 variables:

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

## Source

HUD PIT counts disaggregated to counties; see
[`homeless`](https://ssdalab.github.io/COCHomeless/reference/homeless.md).
