# U.S. county boundaries

Cartographic boundaries (1:500,000) for all U.S. counties and county
equivalents, as a national `sf` object. Geometries are simplified for a
compact package size. Use as a base layer for mapping the county-level
estimates
([`homeless`](https://ssdalab.github.io/COCHomeless/reference/homeless.md))
and with the Census-to-CoC crosswalk.

## Usage

``` r
counties
```

## Format

An `sf` data frame (CRS EPSG:4269, NAD83) with one row per county and 9
attributes plus geometry:

- fips:

  5-digit county FIPS code.

- STATEFP:

  2-digit state FIPS code.

- COUNTYFP:

  3-digit county FIPS code.

- NAME:

  County name.

- NAMELSAD:

  County name with legal/statistical description.

- STUSPS:

  Two-letter state abbreviation.

- STATE_NAME:

  State name.

- ALAND:

  Land area in square meters.

- AWATER:

  Water area in square meters.

- geometry:

  County boundary polygon.

## Source

U.S. Census Bureau TIGER/Line cartographic boundary files, via the
tigris package
(<https://www.census.gov/geographies/mapping-files.html>).

## Details

This object defines the **canonical county FIPS vintage** for the whole
package: `area`, `homeless`, `homeless_na`, `sp_homeless`, `county_pit`,
`county_pit_detail` and the `county_coc*` / `tract_coc*` crosswalks are
all keyed on it. County codes change over time – Connecticut replaced
its eight counties (09001-09015) with nine planning regions
(09110-09190), Alaska split Valdez-Cordova into Chugach (02063) and
Copper River (02066) and renamed Wade Hampton to Kusilvak (02158), and
South Dakota renamed Shannon to Oglala Lakota (46102) – so joining data
built on different vintages returns nothing for the affected counties.
The frame is pinned to the 2024 TIGER/Line vintage.
