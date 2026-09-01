# Changelog

## COCHomeless 0.3.0

### Data corrections

Three defects caused data to be silently dropped rather than to raise an
error. All published national and county figures change as a result;
anyone with analyses in flight against 0.2.0 should re-run them.

- **Kansas City (`MO-604`) was missing from the entire series,
  2007-2025.** HUD writes footnoted CoC codes with a trailing letter in
  the source workbook, and Kansas City appears as `MO-604a` because the
  CoC spans Missouri and Kansas. The import filter rejected the code
  outright, so the CoC was absent from `hud2007` through `hud2025`,
  `pit_coc` and `pit_coc_detail` – and, because `pit_us` is computed by
  summing the same filtered rows, the national totals were understated
  by the same amount with nothing to disagree with. Between 1,575 and
  2,992 people per year were missing. `pit_us` for 2024 was 769,299
  against HUD’s published 771,480; it is now 771,480. Footnote markers
  are stripped on import, and the extractors now fail loudly if any
  CoC-shaped code is rejected.

- **Every Connecticut county read 0 in every year.** Connecticut
  replaced its eight counties (`09001`-`09015`) with nine planning
  regions (`09110`-`09190`). The county frame carried the planning
  regions, but the population and area benchmarks that drive the
  apportionment weights were still on the 2010 county vintage, so all
  nine regions had no density weight, fell out of the apportionment,
  were skipped by the imputation, and were written out as zeros.
  Alaska’s Chugach (`02063`), Copper River (`02066`) and Kusilvak
  (`02158`) and South Dakota’s Oglala Lakota (`46102`) were zeroed the
  same way. Connecticut county totals now reproduce the Connecticut CoC
  totals exactly from 2015 on.

- **Counties whose primary CoC had no detail profile were dropped from
  `county_pit_detail`.** An inner join removed them from the dataset
  entirely rather than falling back. This affected all nine Connecticut
  planning regions plus Wyandotte County, Kansas and Jackson County,
  Missouri (both in `MO-604`). Such counties now fall back to the
  national shelter-by-subpopulation profile.

- **Kansas counties were roughly 29% above their officially reported
  state total.** MO-604 (Kansas City) covers territory in both Missouri
  and Kansas; HUD’s by-CoC workbook reports one combined row coded to
  Missouri, while HUD’s by-State workbook reports the two portions
  separately. The apportionment saw only the combined figure, so
  population-density weighting handed dense Wyandotte County, Kansas a
  large share of Missouri’s count. The county estimates now use HUD’s
  published state split, and Kansas and Missouri reproduce their
  official state totals exactly from 2019 on.

### Validation against HUD

The package is built from HUD’s “PIT Counts by CoC” workbook. HUD
separately publishes “PIT Counts by State”, an independent tabulation of
the same count, and the two are now reconciled in the test suite
(`tests/testthat/fixtures/hud_pit_by_state.csv`):

- National totals match HUD’s published figures exactly in all 19 years.
- CoC-derived state totals match exactly for all 49 states outside the
  Missouri/Kansas bi-state CoC.
- County-derived state totals reproduce HUD’s state totals with a median
  deviation of 0.00% from 2011 onward, and all 51 states within about 2%
  for 2023-2025.
- The national rate of 23 per 10,000 for 2024 is reproduced, and every
  state’s rate per 10,000 matches the rate computed from HUD’s own
  published totals.

### Breaking changes

- **One canonical county FIPS vintage.** `counties` is pinned to the
  2024 TIGER/Line vintage and every county-keyed dataset – `area`,
  `homeless`, `homeless_na`, `sp_homeless`, `county_pit`,
  `county_pit_detail`, and the `county_coc*` / `tract_coc*` crosswalks –
  is keyed on it. Previously three vintages were mixed. The retired
  codes `09001`-`09015`, `02261`, `02270`, `46113` and `51515` no longer
  appear anywhere. The crosswalks in particular moved: they used to take
  the county code from the census-tract attributes, so they shared no
  Connecticut keys at all with the rest of the package.

- **`area` is rebuilt and now covers all 3,235 counties** (was 3,143,
  missing the Connecticut planning regions and the renamed Alaska and
  South Dakota counties). It is derived from the Census `ALAND + AWATER`
  fields on the county frame rather than by summing retired 2010 `sp`
  tract objects. Land plus water preserves the semantics of the original
  tract-summed figures; values are unchanged for 92% of counties to
  within 1%, and within 5% for 98%.

- **`counties` and `states` gain an `AWATER` column** (water area in
  square metres), which `area` is built from.

### Other changes

- The HUD PIT series, the CoC boundaries and the Census-to-CoC crosswalk
  now run through 2025; the crosswalk is built for every year 2007-2025.
- `county_pit`, `county_pit_detail` and `homeless` are split on the same
  primary CoC. They previously each derived their own dominant CoC,
  which could disagree.
- Build-time guards: the apportionment refuses to run if any county
  lacks a density weight, refuses to finish if any state has no positive
  count in a year, and the extractors refuse to drop a CoC-shaped code.
- New tests covering county FIPS vintage consistency, silent-zero
  detection, CoC reconciliation in both directions, and value
  plausibility (no negative or missing counts, no county with more
  homeless residents than residents, no county over its cap, and
  county-level volatility no worse than the CoC series it derives from)
  – including a check of the national totals against HUD’s published
  figures.

## COCHomeless 0.2.0

### Breaking changes

- **Spatial data migrated from `sp` to `sf`.** The yearly Continuum of
  Care boundary objects (`coc2007`–`coc2024`) are now single national
  `sf` objects (one row per CoC) instead of 51-element lists of
  `SpatialPolygonsDataFrame`s, and `sp_homeless` is now an `sf` object.
  `Imports` is now `sf` rather than `sp`.

### New data

- Extended the HUD Point-in-Time count series (`hud2016`–`hud2024`) and
  CoC boundary series (`coc2016`–`coc2024`) through 2024.
- Added a Census-to-CoC crosswalk family: `tract_coc20XX` (hard
  tract-to-CoC assignment by tract centroid) and `tract_coc_wt20XX`
  (area- and population-weighted tract/county-to-CoC overlap shares),
  adapted from Tom Byrne’s crosswalk procedure.
- Added `hud2025_prelim`, a clearly flagged *preliminary* 2025 estimate
  derived from Community Solutions’ population-weighted ratio estimator.
  These figures have not undergone HUD’s quality-assurance process and
  are not directly comparable to the official `hud20XX` series.

### Other changes

- American Community Survey covariates are now built with `tidycensus`
  (the former American FactFinder source is retired).
- Added cross-sectional data-integrity tests and three introductory
  vignettes centered on California and Washington.
- Documentation, `DESCRIPTION`, and metadata updated for CRAN
  compliance.
