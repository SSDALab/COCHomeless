# County homeless estimates as a spatial (sf) object

The completed county-level homeless estimates of
[`homeless`](https://ssdalab.github.io/COCHomeless/reference/homeless.md)
joined to U.S. county boundaries, as a simple-feature (`sf`) object for
mapping and spatial modeling. One row per county.

## Usage

``` r
sp_homeless
```

## Format

An `sf` data frame (CRS EPSG:4269, NAD83) with 3143 rows, the columns of
[`homeless`](https://ssdalab.github.io/COCHomeless/reference/homeless.md)
(county `fips`, yearly total `count07`–`count25`, ACS covariates,
`avg`), the yearly shelter split `sheltered07`–`sheltered25` and
`unsheltered07`–`unsheltered25`, and a county boundary `geometry`
column.

## Source

HUD Point-in-Time data disaggregated to counties; county geometry from
[`counties`](https://ssdalab.github.io/COCHomeless/reference/counties.md);
ACS covariates via tidycensus.

## See also

[`homeless`](https://ssdalab.github.io/COCHomeless/reference/homeless.md),
[`counties`](https://ssdalab.github.io/COCHomeless/reference/counties.md)
