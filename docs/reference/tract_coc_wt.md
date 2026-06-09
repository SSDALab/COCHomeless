# Tract to CoC area-weighted overlap crosswalk

Area-weighted overlap between census tracts and HUD Continuum of Care
(CoC) boundaries, for tracts that straddle CoC borders. Computed from
the intersection of tract and CoC polygons in an equal-area projection
(EPSG:5070). Use it to apportion tract-level American Community Survey
values across CoCs (weights sum to 1 within each tract). For the
county-level apportionment of CoC counts see
[`county_coc2019`](https://ssdalab.github.io/COCHomeless/reference/county_coc.md).

## Usage

``` r
tract_coc_wt2007

tract_coc_wt2008

tract_coc_wt2009

tract_coc_wt2010

tract_coc_wt2011

tract_coc_wt2012

tract_coc_wt2013

tract_coc_wt2014

tract_coc_wt2015

tract_coc_wt2016

tract_coc_wt2017

tract_coc_wt2018

tract_coc_wt2019

tract_coc_wt2020

tract_coc_wt2021

tract_coc_wt2022

tract_coc_wt2023

tract_coc_wt2024

tract_coc_wt2025
```

## Format

A data frame with one row per (tract, CoC) overlap and 5 variables:

- GEOID:

  11-digit census tract identifier.

- fips:

  5-digit county FIPS code.

- COCNUM:

  CoC number.

- COCNAME:

  CoC name.

- w_tract:

  Share of the tract's area in this CoC; sums to 1 per tract.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
84680 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
85189 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
84945 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
84930 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
84618 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
84299 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
84457 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
84515 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
84506 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
84545 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
84334 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
84788 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
96783 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
96847 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
96684 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
96722 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
96838 rows and 5 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
96849 rows and 5 columns.

## Source

HUD CoC GIS National Boundary files; IPUMS NHGIS tract geography. See
[`tract_coc2019`](https://ssdalab.github.io/COCHomeless/reference/tract_coc.md).

## Details

Crosswalk procedure due to Tom Byrne (Boston University); please credit
Byrne and his repository
(<https://github.com/tomhbyrne/HUD-CoC-Geography-Crosswalk>) when using
these data.
