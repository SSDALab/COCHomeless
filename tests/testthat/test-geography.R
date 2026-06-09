# Base geography (counties, states) and the preliminary 2025 object.

test_that("counties is a valid national county sf", {
  skip_if_not("counties" %in% all_datasets(), "counties not built")
  skip_if_not_installed("sf")
  counties <- get_dataset("counties")
  expect_s3_class(counties, "sf")
  expect_gt(nrow(counties), 3100)               # ~3143 + territories
  expect_true(all(grepl("^[0-9]{5}$", counties$fips)))
  expect_equal(anyDuplicated(counties$fips), 0L)
  expect_false(is.na(sf::st_crs(counties)))
  expect_true(all(sf::st_is_valid(counties)))
})

test_that("states is a valid sf and covers the counties", {
  skip_if_not("states" %in% all_datasets(), "states not built")
  skip_if_not_installed("sf")
  states <- get_dataset("states")
  counties <- get_dataset("counties")
  expect_s3_class(states, "sf")
  expect_true(all(sf::st_is_valid(states)))
  # every county's state appears in the states layer
  expect_true(all(unique(substr(counties$fips, 1, 2)) %in% states$state_fips))
})

test_that("hud2025_prelim is clearly preliminary and well-formed", {
  skip_if_not("hud2025_prelim" %in% all_datasets(), "not built")
  d <- get_dataset("hud2025_prelim")
  expect_true(all(c("category", "count_2024", "est_2025", "pct_change") %in% names(d)))
  expect_true("Overall" %in% d$category)
  expect_true(all(d$est_2025 > 0))
  expect_true(all(d$cocs_reporting <= d$cocs_total))   # sample <= universe
})
