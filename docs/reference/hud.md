# CoC-level Point-in-Time (PIT) homeless counts, 2007-2025

Annual HUD Point-in-Time (PIT) estimates of the total homeless
population ("Overall Homeless") for each Continuum of Care (CoC). One
data frame per year, `hud2007` through `hud2024`, harmonized from HUD's
unified "PIT Counts by CoC" workbook so the CoC coding and count
definition are consistent across the series.

## Usage

``` r
hud2007

hud2008

hud2009

hud2010

hud2011

hud2012

hud2013

hud2014

hud2015

hud2016

hud2017

hud2018

hud2019

hud2020

hud2021

hud2022

hud2023

hud2024

hud2025
```

## Format

A data frame with one row per CoC and 2 variables:

- coc_num:

  CoC number, e.g. `"WA-500"` (character).

- count:

  Overall Homeless PIT count for the year (integer).

An object of class `data.frame` with 389 rows and 2 columns.

An object of class `data.frame` with 390 rows and 2 columns.

An object of class `data.frame` with 390 rows and 2 columns.

An object of class `data.frame` with 391 rows and 2 columns.

An object of class `data.frame` with 390 rows and 2 columns.

An object of class `data.frame` with 391 rows and 2 columns.

An object of class `data.frame` with 390 rows and 2 columns.

An object of class `data.frame` with 394 rows and 2 columns.

An object of class `data.frame` with 393 rows and 2 columns.

An object of class `data.frame` with 394 rows and 2 columns.

An object of class `data.frame` with 395 rows and 2 columns.

An object of class `data.frame` with 396 rows and 2 columns.

An object of class `data.frame` with 391 rows and 2 columns.

An object of class `data.frame` with 386 rows and 2 columns.

An object of class `data.frame` with 386 rows and 2 columns.

An object of class `data.frame` with 384 rows and 2 columns.

An object of class `data.frame` with 384 rows and 2 columns.

An object of class `data.frame` with 385 rows and 2 columns.

## Source

HUD, Annual Homeless Assessment Report (AHAR) Part 1, PIT estimates:
<https://www.huduser.gov/portal/datasets/ahar/2024-ahar-part-1-pit-estimates-of-homelessness-in-the-us.html>

## Details

Note: the 2021 totals are unusually low because HUD waived the
unsheltered count requirement for many CoCs during the COVID-19
pandemic.
