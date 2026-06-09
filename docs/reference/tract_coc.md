# Census tract to Continuum of Care (CoC) hard assignment crosswalk

Assigns each U.S. census tract to the single HUD Continuum of Care (CoC)
that contains the tract's interior point. Built by a tract-centroid
point-in-polygon match
([`sf::st_point_on_surface`](https://r-spatial.github.io/sf/reference/geos_unary.html)
then
[`sf::st_join`](https://r-spatial.github.io/sf/reference/st_join.html))
of IPUMS NHGIS tract polygons against the HUD CoC GIS National Boundary
files. Use it to attach a CoC label to any tract- or county-keyed
dataset. One row per tract; a small number of coastal/water tracts whose
interior point falls outside every CoC have `NA` CoC fields.

## Usage

``` r
tract_coc2007

tract_coc2008

tract_coc2009

tract_coc2010

tract_coc2011

tract_coc2012

tract_coc2013

tract_coc2014

tract_coc2015

tract_coc2016

tract_coc2017

tract_coc2018

tract_coc2019

tract_coc2020

tract_coc2021

tract_coc2022

tract_coc2023

tract_coc2024

tract_coc2025
```

## Format

A data frame with one row per census tract and 9 variables:

- GEOID:

  11-digit census tract identifier (state + county + tract).

- STATEFP:

  2-digit state FIPS code.

- COUNTYFP:

  3-digit county FIPS code.

- fips:

  5-digit county FIPS code (`STATEFP` + `COUNTYFP`).

- TRACTCE:

  6-digit census tract code.

- ST:

  Two-letter state abbreviation.

- STATE_NAME:

  State name.

- COCNUM:

  CoC number, e.g. `"WA-500"` (`NA` if unmatched).

- COCNAME:

  CoC name (`NA` if unmatched).

An object of class `data.frame` with 73666 rows and 9 columns.

An object of class `data.frame` with 73666 rows and 9 columns.

An object of class `data.frame` with 73666 rows and 9 columns.

An object of class `data.frame` with 73666 rows and 9 columns.

An object of class `data.frame` with 73666 rows and 9 columns.

An object of class `data.frame` with 73666 rows and 9 columns.

An object of class `data.frame` with 73666 rows and 9 columns.

An object of class `data.frame` with 73666 rows and 9 columns.

An object of class `data.frame` with 73666 rows and 9 columns.

An object of class `data.frame` with 73666 rows and 9 columns.

An object of class `data.frame` with 73666 rows and 9 columns.

An object of class `data.frame` with 73666 rows and 9 columns.

An object of class `data.frame` with 85061 rows and 9 columns.

An object of class `data.frame` with 85061 rows and 9 columns.

An object of class `data.frame` with 85061 rows and 9 columns.

An object of class `data.frame` with 85061 rows and 9 columns.

An object of class `data.frame` with 85061 rows and 9 columns.

An object of class `data.frame` with 85061 rows and 9 columns.

## Source

HUD CoC GIS National Boundary files
(<https://www.hudexchange.info/programs/coc/gis-tools/>); tract
geography from IPUMS NHGIS (<https://www.nhgis.org/>). Crosswalk
procedure adapted from Tom Byrne's `tract_coc_match` program.

## Details

The matching procedure is due to Tom Byrne (Boston University); please
credit Byrne and his crosswalk repository,
<https://github.com/tomhbyrne/HUD-CoC-Geography-Crosswalk>, when using
these crosswalk data. See
[`COCHomeless`](https://ssdalab.github.io/COCHomeless/reference/COCHomeless-package.md).
