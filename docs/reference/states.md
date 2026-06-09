# U.S. state and territory boundaries

Cartographic boundaries (1:500,000) for all U.S. states, the District of
Columbia, and territories, as a national `sf` object. Geometries are
simplified for a compact package size. Use as a base layer for national
maps.

## Usage

``` r
states
```

## Format

An `sf` data frame (CRS EPSG:4269, NAD83) with one row per
state/territory and 4 attributes plus geometry:

- state_fips:

  2-digit state/territory FIPS code.

- STATEFP:

  2-digit state/territory FIPS code.

- STUSPS:

  Two-letter state/territory abbreviation.

- NAME:

  State/territory name.

- ALAND:

  Land area in square meters.

- geometry:

  State/territory boundary polygon.

## Source

U.S. Census Bureau TIGER/Line cartographic boundary files, via the
tigris package.
