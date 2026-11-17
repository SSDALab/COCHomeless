# Regression tests for registered bugs that are not already covered by a
# tagged test elsewhere. Every test here names its bug as "[BUG-NNN]"; see
# fixtures/bug_registry.csv and BUGS.md.

test_that("[BUG-004] Los Angeles County outranks Orange County in every year", {
  la <- homeless[homeless$fips == "06037", grep("^count", names(homeless))]
  or <- homeless[homeless$fips == "06059", grep("^count", names(homeless))]
  expect_true(all(unlist(la) > unlist(or)))
})

test_that("[BUG-004] LA County 2024 is exactly CA-600 plus its nested CoCs", {
  al <- county_coc_alloc[county_coc_alloc$fips == "06037" &
                           county_coc_alloc$year == 2024L, ]
  expect_setequal(al$coc_num, c("CA-600", "CA-606", "CA-607", "CA-612"))
  hud <- hud2024[hud2024$coc_num %in% al$coc_num, ]
  expect_equal(homeless$count24[homeless$fips == "06037"], sum(hud$count))
})

test_that("[BUG-005] CoC codes are character, never factors", {
  for (yr in years_for("hud"))
    expect_type(get_dataset(sprintf("hud%d", yr))$coc_num, "character")
  expect_type(pit_coc$coc_num, "character")
  expect_type(county_coc_alloc$coc_num, "character")
})

test_that("[BUG-006] the county datasets are discoverable through data()", {
  expect_true(all(c("homeless", "homeless_na", "sp_homeless", "county_pit",
                    "county_coc_alloc") %in% all_datasets()))
})

test_that("[BUG-007] no boundary or PIT code carries an embedded fiscal year", {
  for (yr in years_for("coc")) {
    ids <- as.character(get_dataset(sprintf("coc%d", yr))$COCNUM)
    expect_false(any(grepl("^[A-Z]{2}[0-9]{2}-", ids)),
                 label = sprintf("coc%d year-embedded codes", yr))
  }
  expect_false(any(grepl("^[A-Z]{2}[0-9]{2}-", county_coc_alloc$coc_num)))
})

test_that("[BUG-011] county_pit totals are the homeless county estimates", {
  for (yr in years_for("hud")) {
    cp <- county_pit[county_pit$year == yr, ]
    h <- homeless[[sprintf("count%02d", yr %% 100)]][match(cp$fips, homeless$fips)]
    expect_equal(cp$total, h, label = sprintf("county_pit vs homeless, %d", yr))
  }
})

test_that("[BUG-011] county_pit splits each county on the CoC it was apportioned from", {
  # sheltered share of a single-source county equals its primary CoC's share
  al <- county_coc_alloc[county_coc_alloc$year == 2024L, ]
  single <- names(which(table(al$fips) == 1))
  p <- al[al$fips %in% single & al$role == "primary", ]
  cp <- county_pit[county_pit$year == 2024L & county_pit$fips %in% p$fips &
                     county_pit$total >= 200, ]
  coc <- pit_coc[pit_coc$year == 2024L, ]
  src <- p$coc_num[match(cp$fips, p$fips)]
  want <- coc$sheltered[match(src, coc$coc_num)] / coc$total[match(src, coc$coc_num)]
  expect_lt(max(abs(cp$sheltered / cp$total - want), na.rm = TRUE), 0.01)
})
