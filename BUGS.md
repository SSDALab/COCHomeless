# Known bugs and fixes

Running list of every defect found in COCHomeless and how it was fixed.
**Source of truth:** `tests/testthat/fixtures/bug_registry.csv` -- edit that,
then run `Rscript data-raw/99_render_bugs.R`. See `TESTING.md` for the process.

15 registered: 15 fixed, 0 open.

| ID | Status | Found in | Fixed in | Bug |
|---|---|---|---|---|
| BUG-001 | fixed | 0.2.0 | 0.3.0 | Kansas City (MO-604) missing from the whole PIT series |
| BUG-002 | fixed | 0.2.0 | 0.3.0 | Every Connecticut county read 0 in every year |
| BUG-003 | fixed | 0.2.0 | 0.3.0 | Counties dropped from county_pit_detail when their CoC had no detail profile |
| BUG-004 | fixed | 0.1.0 | 0.2.0 | Density weighting handed CoCs to counties they only slivered into |
| BUG-005 | fixed | 0.1.0 | 0.2.0 | hud coc_num stored as factor |
| BUG-006 | fixed | 0.1.0 | 0.2.0 | County datasets invisible to data() |
| BUG-007 | fixed | 0.1.0 | 0.2.0 | Fiscal year embedded in early CoC codes |
| BUG-008 | fixed | 0.3.0 | 0.4.0 | CoCs missing from a year's HUD boundary file had their whole count dropped |
| BUG-009 | fixed | 0.3.0 | 0.4.0 | A county could draw its count from a CoC that only slivered into it |
| BUG-010 | fixed | 0.3.0 | 0.4.0 | Kansas City's Kansas portion charged to the wrong CoC before 2016 |
| BUG-011 | fixed | 0.2.0 | 0.3.0 | County datasets split on different CoCs |
| BUG-012 | fixed | 0.2.0 | 0.3.0 | Kansas ~29% above its official state total |
| BUG-013 | fixed | 0.3.0 | 0.4.0 | Transient Census API errors aborted the rebuild |
| BUG-014 | fixed | 0.4.0 | 0.4.0 | Counties with no CoC in any year dropped from county_pit_detail |
| BUG-015 | fixed | 0.4.0 | 0.4.0 | Failed .xlsb extraction silently reused a stale CSV |

## BUG-015 -- Failed .xlsb extraction silently reused a stale CSV

**Status:** fixed. Found in 0.4.0; fixed in 0.4.0.

- **Symptom:** On a machine without pandas, 08_pit_us.R and 09_pit_coc.R printed a Python traceback and carried on, building pit_us/pit_coc from whatever CSV was already in data-raw/downloads.
- **Cause:** system2()'s exit status was ignored; the CSV is overwritten in place, so an old extract (or one from a previous workbook) was read as if fresh.
- **Fix:** run_extractor() in 00_build_helpers.R, used by 02, 02b, 05, 08, 09 and 12: stops on failure unless the existing CSV is newer than the workbook it came from (then warns), and stops if a 'successful' run did not refresh the CSV. Unit-tested. build_python() selects $COCHOMELESS_PYTHON, then the project venv data-raw/.venv (data-raw/requirements.txt), then python3.
- **Regression tests:**
  - `test-build-helpers.R`: [BUG-015] run_extractor never lets the build continue on a stale output
  - `test-build-helpers.R`: [BUG-015] build_python prefers COCHOMELESS_PYTHON, then the project venv

## BUG-014 -- Counties with no CoC in any year dropped from county_pit_detail

**Status:** fixed. Found in 0.4.0; fixed in 0.4.0.

- **Symptom:** Baker County FL (12003) absent from county_pit_detail after the BUG-009 fix made it imputed in every year.
- **Cause:** 12_pit_detail.R inner-joined the primary-CoC table, so a county with no CoC at all had no rows (same pattern as BUG-003).
- **Fix:** Left join from the full county frame; counties with no CoC use the national shelter-by-subpopulation profile.
- **Regression tests:**
  - `test-no-silent-zeros.R`: [BUG-003] [BUG-014] county_pit and county_pit_detail cover the same counties

## BUG-013 -- Transient Census API errors aborted the rebuild

**Status:** fixed. Found in 0.3.0; fixed in 0.4.0.

- **Symptom:** 05_county_estimates.R died on api.census.gov timeouts / connection resets after a 30-minute apportionment.
- **Cause:** Uncached, unretried get_acs() calls.
- **Fix:** cached_acs(): ACS pulls cached under data-raw/downloads and retried 5 times. Build-only; no data test.
- **Regression tests:**
  - (build-only; no data test)

## BUG-012 -- Kansas ~29% above its official state total

**Status:** fixed. Found in 0.2.0; fixed in 0.3.0.

- **Symptom:** Kansas county totals far above HUD's published Kansas total.
- **Cause:** MO-604 apportioned as one unit; density weighting gave dense Wyandotte KS a large share of Missouri's count.
- **Fix:** Split MO-604 by HUD's published by-state totals.
- **Regression tests:**
  - `test-hud-official.R`: [BUG-012] the bi-state split reaches the counties

## BUG-011 -- County datasets split on different CoCs

**Status:** fixed. Found in 0.2.0; fixed in 0.3.0.

- **Symptom:** county_pit / county_pit_detail could use a different CoC than the one homeless was apportioned from.
- **Cause:** 10_ and 12_ recomputed their own dominant CoC from county_coc w_county.
- **Fix:** 05_ exports the primary CoC; 10_ and 12_ read it.
- **Regression tests:**
  - `test-bug-regressions.R`: [BUG-011] county_pit totals are the homeless county estimates
  - `test-bug-regressions.R`: [BUG-011] county_pit splits each county on the CoC it was apportioned from

## BUG-010 -- Kansas City's Kansas portion charged to the wrong CoC before 2016

**Status:** fixed. Found in 0.3.0; fixed in 0.4.0.

- **Symptom:** OK-503/OK-500 lost 1,981 people 2007-2015 (some years to zero); MO-606's Missouri counties lost ~215/yr to Kansas.
- **Cause:** state_split() charged a state's residual to the out-of-state CoC with the largest overlap; pre-2016 files draw MO-604 barely into Kansas, so OK-503, MO-603 or MO-606 slivers won.
- **Fix:** Eligible CoC must be coded to the short state and hold the residual (pick_split_coc); bi-state CoC identified from the latest boundary file and held fixed; build stops on a negative split.
- **Regression tests:**
  - `test-build-helpers.R`: [BUG-010] pick_split_coc charges a state residual to the right CoC
  - `test-build-helpers.R`: [BUG-010] pick_split_coc holds the bi-state CoC fixed when it is eligible
  - `test-hud-official.R`: [BUG-008] [BUG-010] APPORTIONED state totals reproduce HUD's state totals
  - `test-qc-allocation.R`: [BUG-008] [BUG-010] the pre-imputation county panel conserves every year's PIT total
  - `test-qc-allocation.R`: [BUG-008] [BUG-010] county_coc_alloc conserves every CoC's count exactly
  - `test-qc-allocation.R`: [BUG-010] only Kansas City's CoC is split across states, onto Kansas

## BUG-009 -- A county could draw its count from a CoC that only slivered into it

**Status:** fixed. Found in 0.3.0; fixed in 0.4.0.

- **Symptom:** 556 county-years apportioned from a <1% boundary sliver, e.g. Sutter County CA 2009-2012 drew on Yolo's CA-521 via 6 km2; spurious year-over-year swings when the boundary was repaired.
- **Cause:** Primary CoC = largest overlap with no floor; when HUD's file left a county uncovered, a neighbour's sliver won.
- **Fix:** Primary CoC must cover >= 1% of the county (choose_primary); uncovered counties are imputed.
- **Regression tests:**
  - `test-build-helpers.R`: [BUG-009] choose_primary ignores a CoC that only slivers into a county
  - `test-qc-allocation.R`: [BUG-009] no county draws its count from a CoC that only slivers into it
  - `test-qc-allocation.R`: [BUG-009] extreme county swings are explained by the CoC they come from

## BUG-008 -- CoCs missing from a year's HUD boundary file had their whole count dropped

**Status:** fixed. Found in 0.3.0; fixed in 0.4.0.

- **Symptom:** 53 CoC-years (21,906 people, 0.1-0.4% of the national count per year) reached no county, e.g. CA-524 2009-2012, LA-509 2007-2014, five Maryland CoCs in 2020. Hidden by the imputed panel.
- **Cause:** Apportionment intersected counties only with that year's polygons; a CoC with a PIT count but no polygon was never a member of any county.
- **Fix:** Borrow the nearest year's polygon (earlier on ties); recorded in county_coc_alloc$boundary_year. Build stops if any CoC's count is not fully placed.
- **Regression tests:**
  - `test-build-helpers.R`: [BUG-008] nearest_boundary_year picks the closest year, earlier on ties
  - `test-hud-official.R`: [BUG-008] [BUG-010] APPORTIONED state totals reproduce HUD's state totals
  - `test-qc-allocation.R`: [BUG-008] every CoC with a boundary gap can borrow a polygon
  - `test-qc-allocation.R`: [BUG-008] [BUG-010] the pre-imputation county panel conserves every year's PIT total
  - `test-qc-allocation.R`: [BUG-008] [BUG-010] county_coc_alloc conserves every CoC's count exactly

## BUG-007 -- Fiscal year embedded in early CoC codes

**Status:** fixed. Found in 0.1.0; fixed in 0.2.0.

- **Symptom:** coc2007 uses AL07-500, which never matches the PIT code AL-500.
- **Cause:** Early HUD boundary files embed a 2-digit year in COCNUM.
- **Fix:** Normalize codes (normalize_coc_code) across the whole series.
- **Regression tests:**
  - `test-bug-regressions.R`: [BUG-007] no boundary or PIT code carries an embedded fiscal year
  - `test-build-helpers.R`: [BUG-007] normalize_coc_code strips fiscal years embedded in codes

## BUG-006 -- County datasets invisible to data()

**Status:** fixed. Found in 0.1.0; fixed in 0.2.0.

- **Symptom:** data(homeless) failed.
- **Cause:** Files named homeless.Rda (capital R).
- **Fix:** Rename to lowercase .rda.
- **Regression tests:**
  - `test-bug-regressions.R`: [BUG-006] the county datasets are discoverable through data()

## BUG-005 -- hud coc_num stored as factor

**Status:** fixed. Found in 0.1.0; fixed in 0.2.0.

- **Symptom:** c()/unlist() silently turned CoC codes into integer level codes.
- **Cause:** Legacy data stored coc_num as a factor.
- **Fix:** Store coc_num as character.
- **Regression tests:**
  - `test-bug-regressions.R`: [BUG-005] CoC codes are character, never factors

## BUG-004 -- Density weighting handed CoCs to counties they only slivered into

**Status:** fixed. Found in 0.1.0; fixed in 0.2.0.

- **Symptom:** Orange County CA got 62k and LA 36k (backwards).
- **Cause:** Raw density weights over every county a CoC polygon overlapped; a sliver into a dense county captured a large share.
- **Fix:** Each county has ONE primary CoC (largest overlap); nested sub-county CoCs assigned to the county holding most of them.
- **Regression tests:**
  - `test-bug-regressions.R`: [BUG-004] Los Angeles County outranks Orange County in every year
  - `test-bug-regressions.R`: [BUG-004] LA County 2024 is exactly CA-600 plus its nested CoCs
  - `test-build-helpers.R`: [BUG-004] choose_primary gives each county ONE primary, the largest overlap

## BUG-003 -- Counties dropped from county_pit_detail when their CoC had no detail profile

**Status:** fixed. Found in 0.2.0; fixed in 0.3.0.

- **Symptom:** CT planning regions, Wyandotte KS and Jackson MO absent from county_pit_detail.
- **Cause:** Inner join against CoC detail profiles.
- **Fix:** Fall back to the national shelter-by-subpopulation profile.
- **Regression tests:**
  - `test-no-silent-zeros.R`: [BUG-003] [BUG-014] county_pit and county_pit_detail cover the same counties
  - `test-no-silent-zeros.R`: [BUG-003] counties whose primary CoC lacks a detail profile are still present

## BUG-002 -- Every Connecticut county read 0 in every year

**Status:** fixed. Found in 0.2.0; fixed in 0.3.0.

- **Symptom:** All nine CT planning regions (and AK 02063/02066/02158, SD 46102) zero in every year.
- **Cause:** Population/area benchmarks on the 2010 county vintage; new FIPS had no density weight and fell out of apportionment and imputation.
- **Fix:** One pinned county FIPS vintage; 2010 population aggregated from tracts; build stops if any county lacks a density weight.
- **Regression tests:**
  - `test-fips-vintage.R`: [BUG-002] Connecticut is keyed on the nine planning regions everywhere
  - `test-no-silent-zeros.R`: [BUG-002] Connecticut planning regions carry non-zero counts

## BUG-001 -- Kansas City (MO-604) missing from the whole PIT series

**Status:** fixed. Found in 0.2.0; fixed in 0.3.0.

- **Symptom:** MO-604 absent from hud2007-hud2025, pit_coc, pit_coc_detail; national totals 1,575-2,992/yr low.
- **Cause:** HUD writes footnoted codes with a trailing letter (MO-604a); the import filter rejected the code.
- **Fix:** Strip footnote markers on import; extractors fail loudly on any rejected CoC-shaped code.
- **Regression tests:**
  - `test-build-helpers.R`: [BUG-001] normalize_coc_code strips trailing footnote letters
  - `test-coc-reconciliation.R`: [BUG-001] Kansas City (MO-604) is present throughout the series
  - `test-coc-reconciliation.R`: [BUG-001] no CoC code carries an unstripped footnote marker

