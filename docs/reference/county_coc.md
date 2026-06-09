# County to CoC area-weighted crosswalk

Area-weighted overlap between U.S. counties and HUD Continuum of Care
(CoC) boundaries, with two normalizations supporting both directions of
apportionment. Computed by aggregating the tract-by-CoC intersection to
the county level in an equal-area projection (EPSG:5070).

## Usage

``` r
county_coc2007

county_coc2008

county_coc2009

county_coc2010

county_coc2011

county_coc2012

county_coc2013

county_coc2014

county_coc2015

county_coc2016

county_coc2017

county_coc2018

county_coc2019

county_coc2020

county_coc2021

county_coc2022

county_coc2023

county_coc2024

county_coc2025
```

## Format

A data frame with one row per (county, CoC) overlap and 6 variables:

- fips:

  5-digit county FIPS code.

- COCNUM:

  CoC number.

- COCNAME:

  CoC name.

- area_m2:

  Overlap area in square meters (EPSG:5070).

- w_coc:

  Share of the CoC's area in this county; sums to 1 per CoC.

- w_county:

  Share of the county's area in this CoC; sums to 1 per county.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6827 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6838 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6825 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6805 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6783 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6676 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6670 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6650 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6649 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6664 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6649 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6717 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6645 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6671 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6666 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6670 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6701 rows and 6 columns.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
6711 rows and 6 columns.

## Source

HUD CoC GIS National Boundary files; IPUMS NHGIS tract geography. See
[`tract_coc2019`](https://ssdalab.github.io/COCHomeless/reference/tract_coc.md).

## Details

- `w_coc` apportions a CoC's Point-in-Time count *down* to its counties
  (sums to 1 within each `COCNUM`). This is the weight used to build the
  county-level estimates in
  [`homeless`](https://ssdalab.github.io/COCHomeless/reference/homeless.md),
  following Almquist, Helwig and You (2020).

- `w_county` aggregates county data *up* to CoCs (sums to 1 within each
  `fips`).

Crosswalk procedure due to Tom Byrne (Boston University); please credit
Byrne and his repository
(<https://github.com/tomhbyrne/HUD-CoC-Geography-Crosswalk>) when using
these data.

## References

Almquist, Z. W., Helwig, N. E. and You, Y. (2020). Connecting Continuum
of Care point-in-time homeless counts to United States Census areal
units. *Mathematical Population Studies*, 27(1), 46–58.
[doi:10.1080/08898480.2019.1636574](https://doi.org/10.1080/08898480.2019.1636574)
