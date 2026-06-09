# County-level homeless estimates, 2007-2024 (missing values imputed)

County-level homeless counts with missing values imputed, plus selected
American Community Survey (ACS) demographic covariates. Counts are
produced by disaggregating HUD Continuum of Care (CoC) Point-in-Time
counts to counties using population-density weighting and imputing
counties with no CoC via a spatial Poisson model, following Almquist,
Helwig and You (2020)
[doi:10.1080/08898480.2019.1636574](https://doi.org/10.1080/08898480.2019.1636574)
. See
[`homeless_na`](https://ssdalab.github.io/COCHomeless/reference/homeless_na.md)
for the pre-imputation version.

## Usage

``` r
homeless
```

## Format

A data frame with 3143 rows (counties and county equivalents in the 50
states and DC) and the following variables:

- state:

  Two-digit state FIPS code.

- fips:

  Five-digit county FIPS code.

- count07:

  Estimated homeless count, 2007 (imputed where missing).

- count08:

  Estimated homeless count, 2008.

- count09:

  Estimated homeless count, 2009.

- count10:

  Estimated homeless count, 2010.

- count11:

  Estimated homeless count, 2011.

- count12:

  Estimated homeless count, 2012.

- count13:

  Estimated homeless count, 2013.

- count14:

  Estimated homeless count, 2014.

- count15:

  Estimated homeless count, 2015.

- count16:

  Estimated homeless count, 2016.

- count17:

  Estimated homeless count, 2017.

- count18:

  Estimated homeless count, 2018.

- count19:

  Estimated homeless count, 2019.

- count20:

  Estimated homeless count, 2020.

- count21:

  Estimated homeless count, 2021.

- count22:

  Estimated homeless count, 2022.

- count23:

  Estimated homeless count, 2023.

- count24:

  Estimated homeless count, 2024.

- count25:

  Estimated homeless count, 2025.

- population:

  County population (ACS 5-year estimate).

- density:

  Population density: 2010 Census population per square km.

- pctblack:

  Percent Black population.

- pctageunder18:

  Percent of population under 18.

- pctfoodstamp:

  Percent of housing units receiving SNAP/food stamps.

- pctvacanthousing:

  Percent of housing units vacant.

- pctmedhousingcost:

  Median annual housing cost as a percent of median household income.

- medhousingval:

  Median housing value, in \$1,000.

- pctmarried:

  Percent of population now married.

- avg:

  Mean homeless count across 2007–2025.

- state_name:

  State name.

## Source

Homeless counts: HUD Point-in-Time data (see
[`hud2007`](https://ssdalab.github.io/COCHomeless/reference/hud.md))
disaggregated to counties. Covariates: U.S. Census Bureau American
Community Survey 5-year estimates, via the tidycensus package.

## Details

Estimates are bounded by a plausibility cap of 2,000 homeless per
100,000 residents (2 percent of population), or 3,500 per 100,000 for
the dense major-metro cores (New York City boroughs and Los Angeles
County). The cap is applied by redistributing any excess within the same
CoC, so a CoC's Point-in-Time total is preserved across its counties.
HUD CoC counts
([`hud2007`](https://ssdalab.github.io/COCHomeless/reference/hud.md))
are never altered (none exceed the cap in any year).

## References

Almquist, Z. W., Helwig, N. E. and You, Y. (2020). Connecting Continuum
of Care point-in-time homeless counts to United States Census areal
units. *Mathematical Population Studies*, 27(1), 46–58.
