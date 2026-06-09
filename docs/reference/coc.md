# CoC geographic boundaries, 2007-2025

HUD Continuum of Care (CoC) boundary polygons by year, `coc2007` through
`coc2024`, as national simple-feature (`sf`) objects with one row per
CoC. Built from HUD's per-state CoC GIS shapefiles, combined nationally,
with CoC codes harmonized across vintages (an embedded fiscal year such
as `"AL07-500"` is normalized to `"AL-500"`). Geometries are
topology-preserving simplified (about 2 percent of vertices retained) to
keep the package a manageable size; they are intended for national-scale
mapping and areal analysis rather than fine local cartography.

## Usage

``` r
coc2007

coc2008

coc2009

coc2010

coc2011

coc2012

coc2013

coc2014

coc2015

coc2016

coc2017

coc2018

coc2019

coc2020

coc2021

coc2022

coc2023

coc2024

coc2025
```

## Format

An `sf` data frame (CRS EPSG:4269, NAD83) with one row per CoC and 4
attributes plus geometry:

- COCNUM:

  CoC number, e.g. `"WA-500"`.

- COCNAME:

  CoC name.

- ST:

  Two-letter state/territory abbreviation.

- STATE_NAME:

  State/territory name.

- total:

  Overall Point-in-Time homeless count that year (`NA` if the CoC has no
  PIT record).

- sheltered:

  Sheltered homeless count that year.

- unsheltered:

  Unsheltered homeless count that year.

- geometry:

  CoC boundary polygon.

An object of class `sf` (inherits from `tbl_df`, `tbl`, `data.frame`)
with 448 rows and 8 columns.

An object of class `sf` (inherits from `data.frame`) with 450 rows and 8
columns.

An object of class `sf` (inherits from `data.frame`) with 442 rows and 8
columns.

An object of class `sf` (inherits from `data.frame`) with 431 rows and 8
columns.

An object of class `sf` (inherits from `data.frame`) with 422 rows and 8
columns.

An object of class `sf` (inherits from `data.frame`) with 411 rows and 8
columns.

An object of class `sf` (inherits from `data.frame`) with 413 rows and 8
columns.

An object of class `sf` (inherits from `data.frame`) with 399 rows and 8
columns.

An object of class `sf` (inherits from `data.frame`) with 398 rows and 8
columns.

An object of class `sf` (inherits from `data.frame`) with 397 rows and 8
columns.

An object of class `sf` (inherits from `tbl_df`, `tbl`, `data.frame`)
with 393 rows and 8 columns.

An object of class `sf` (inherits from `data.frame`) with 398 rows and 8
columns.

An object of class `sf` (inherits from `data.frame`) with 389 rows and 8
columns.

An object of class `sf` (inherits from `tbl_df`, `tbl`, `data.frame`)
with 389 rows and 8 columns.

An object of class `sf` (inherits from `data.frame`) with 386 rows and 8
columns.

An object of class `sf` (inherits from `tbl_df`, `tbl`, `data.frame`)
with 387 rows and 8 columns.

An object of class `sf` (inherits from `data.frame`) with 387 rows and 8
columns.

An object of class `sf` (inherits from `tbl_df`, `tbl`, `data.frame`)
with 388 rows and 8 columns.

## Source

HUD CoC GIS tools:
<https://www.hudexchange.info/programs/coc/gis-tools/>
