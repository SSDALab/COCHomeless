# County FIPS codes are not stable over time, and the package mixes several data
# families that are all keyed on them. When two families were built against
# different county vintages, joins between them returned nothing and the missing
# rows were written out as zeros rather than raising an error -- every
# Connecticut county read 0 in every year of `county_pit` while the Connecticut
# CoCs in `pit_coc` were fine.
#
# These tests pin the whole package to one vintage.

county_families <- function() {
  fams <- c("counties", "area", "homeless", "homeless_na", "sp_homeless",
            "county_pit", "county_pit_detail")
  items <- all_datasets()
  fams <- c(fams, grep("^(county_coc|tract_coc)[0-9]{4}$", items, value = TRUE))
  fams[fams %in% items]
}

test_that("no retired county FIPS survives in any dataset", {
  for (nm in county_families()) {
    found <- intersect(RETIRED_FIPS, county_fips(get_dataset(nm)))
    expect_identical(
      found, character(0),
      label = sprintf("%s carries retired county FIPS (%s)",
                      nm, paste(found, collapse = ", "))
    )
  }
})

test_that("current-vintage county FIPS are present in every county family", {
  # The crosswalk families are keyed on counties that overlap a CoC, so a county
  # with no CoC in a given year is legitimately absent; require the codes to
  # exist in the frame and in the derived county datasets.
  for (nm in c("counties", "area", "homeless", "homeless_na", "sp_homeless",
               "county_pit", "county_pit_detail")) {
    missing <- setdiff(CURRENT_FIPS, county_fips(get_dataset(nm)))
    expect_identical(
      missing, character(0),
      label = sprintf("%s is missing current-vintage county FIPS (%s)",
                      nm, paste(missing, collapse = ", "))
    )
  }
})

test_that("Connecticut is keyed on the nine planning regions everywhere", {
  ct_expected <- sprintf("091%d0", 1:9)
  for (nm in county_families()) {
    ct <- grep("^09", county_fips(get_dataset(nm)), value = TRUE)
    expect_identical(sort(ct), sort(ct_expected),
                     label = sprintf("%s Connecticut county keys", nm))
  }
})

test_that("the county datasets share one FIPS universe", {
  frame <- county_fips(counties)
  expect_identical(sort(county_fips(area)), sort(frame))

  # homeless / county_pit / county_pit_detail are the 50 states + DC.
  states_only <- sort(frame[!is_territory(frame)])
  for (nm in c("homeless", "homeless_na", "sp_homeless",
               "county_pit", "county_pit_detail")) {
    expect_identical(sort(county_fips(get_dataset(nm))), states_only,
                     label = sprintf("%s FIPS universe", nm))
  }
})

test_that("crosswalk county keys are a subset of the canonical frame", {
  frame <- county_fips(counties)
  for (yr in years_for("county_coc")) {
    f <- county_fips(get_dataset(sprintf("county_coc%d", yr)))
    expect_identical(setdiff(f, frame), character(0),
                     label = sprintf("county_coc%d has keys outside `counties`", yr))
    # Connecticut must be reachable from the crosswalk, which it was not when
    # the crosswalk took its county code from the tract attributes.
    expect_true(all(sprintf("091%d0", 1:9) %in% f),
                label = sprintf("county_coc%d covers all CT planning regions", yr))
  }
})
