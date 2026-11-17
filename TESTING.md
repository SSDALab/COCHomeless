# Testing and quality control

COCHomeless ships data, so its tests are mostly about the data: no person may
be lost, misplaced or invented on the way from HUD's CoC counts to the county
estimates. This document is the process; `BUGS.md` is the running record.

## The layers

| Layer | Where | Runs | Purpose |
|---|---|---|---|
| **Unit tests** for the build logic | `tests/testthat/test-build-helpers.R` | `devtools::test()` (source tree only; skipped in `R CMD check`) | Every pure function in `data-raw/00_build_helpers.R` -- rounding, water-filling, boundary fallback, primary-CoC choice, bi-state split, unsheltered imputation -- against hand-built cases. |
| **Build guards** | `stop()` calls inside `data-raw/*.R` | every rebuild | The build refuses to finish on a structural failure: a county without a density weight, a CoC count not fully placed, a negative bi-state split, a county with a count but no CoC. |
| **Data tests** | `tests/testthat/test-*.R` | `devtools::test()` and `R CMD check` | Invariants on the shipped datasets: schema, keys, FIPS vintage, conservation against HUD's national and state totals, plausibility. |
| **Allocation QC** | `tests/testthat/helper-qc.R`, `test-qc-allocation.R`; report `data-raw/13_qc_report.R` | tests: always; report: after every rebuild | Per-CoC conservation, boundary gaps, sliver assignments, and a cause for every extreme county year-over-year swing. The report writes the flagged rows to `data-raw/qc/*.csv`. |
| **Data contract** | `tests/testthat/test-data-contract.R`, snapshot `tests/testthat/fixtures/schema.csv` | always | Shipped columns keep their names and types (new columns are fine); long panels have one row per key; parallel objects (`homeless`/`sp_homeless`/`county_pit`) agree; NEWS leads with the DESCRIPTION version. |
| **Release diff** | `data-raw/15_release_diff.R` | after every rebuild | Compares `data/` with the last commit (or any revision/directory) and writes `data-raw/qc/release_diff*.csv`: which datasets changed and which county-years moved. A rebuild with no logic change must report every dataset identical. Use it for the NEWS impact numbers. |
| **Regression tests** | any test whose name carries `[BUG-NNN]` | always | One or more per registered bug, so a fixed bug cannot come back silently. |
| **Registry meta-tests** | `tests/testthat/test-bug-registry.R` | always | The registry is well-formed; every fixed bug has a tagged test; every tag is registered; `BUGS.md` is in sync. |

## When you find a bug

1. **Register it.** Add a row to `tests/testthat/fixtures/bug_registry.csv`
   with the next ID, `status = open`, the version it was found in, and the
   symptom and cause as far as you know them. IDs are never reused or deleted.
2. **Write the failing test first.** Add a test that fails on the current data
   or code, named with the tag, e.g.
   `test_that("[BUG-015] ...", ...)`. For build logic, put the rule in
   `data-raw/00_build_helpers.R` and unit-test it in `test-build-helpers.R`.
3. **Fix it.** If a rebuild cannot detect the problem, add a build guard
   (`stop()`) as well.
4. **Close it.** Set `status = fixed`, fill in `fixed_in` and `fix`, add a
   `NEWS.md` entry under *Data corrections*, and run
   `Rscript data-raw/99_render_bugs.R` to refresh `BUGS.md`.

A bug that can only be guarded at build time (for example network failures)
may be closed with no data test if its `fix` text says **build-only**.

## When you change the data or the build

* Any new rule in the build that decides **who is counted where** goes in
  `data-raw/00_build_helpers.R` with a unit test.
* Prefer invariants (conservation, equality with an independent HUD
  tabulation) over thresholds. Where a threshold is unavoidable, say in a
  comment what produces the slack.
* **Columns are a contract.** Removing or retyping a column fails
  `test-data-contract.R`. If the break is deliberate, document it in NEWS and
  accept the new schema with `Rscript data-raw/98_snapshot_schema.R`. Run the
  same script after adding columns or datasets, so the contract covers them.
* Never compare an imputed panel to HUD to look for a leak: imputation fills
  gaps with modelled people and can hide one entirely. Test `homeless_na` and
  `county_coc_alloc`.

## Rebuild checklist

```sh
# from the package root
Rscript data-raw/08_pit_us.R                # HUD workbook -> pit_us
Rscript data-raw/09_pit_coc.R               # HUD workbook -> pit_coc
Rscript data-raw/05_county_estimates.R      # apportionment (~30 min uncached)
Rscript data-raw/10_county_pit.R
Rscript data-raw/11_spatial_pit.R
Rscript data-raw/12_pit_detail.R
Rscript data-raw/14_unsheltered_imputation.R   # must follow 08/09/10
Rscript data-raw/13_qc_report.R             # must print PASS
Rscript data-raw/15_release_diff.R          # what changed vs the last commit
Rscript data-raw/99_render_bugs.R
Rscript -e 'devtools::document(); devtools::test(); devtools::check()'
```

`05` caches its apportionment in `data-raw/downloads/` (`county_panel.rds`,
`county_primary_coc.rds`, `county_coc_alloc.rds`, `boundary_fallback.rds`).
Delete those after changing the apportionment logic, or the old result is
reused.
