# Changelog

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
