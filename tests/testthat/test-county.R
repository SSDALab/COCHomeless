# County-level estimates: 3143 counties, key integrity, imputed vs observed,
# and coverage by the area table.

test_that("homeless / homeless_na / sp_homeless share the county frame", {
  homeless    <- get_dataset("homeless")
  homeless_na <- get_dataset("homeless_na")
  sp_homeless <- get_dataset("sp_homeless")

  # 50 states + DC counties (~3143-3144 depending on TIGER vintage)
  expect_true(nrow(homeless) >= 3140 && nrow(homeless) <= 3150)
  expect_equal(nrow(homeless_na), nrow(homeless))
  expect_equal(NROW(sp_homeless), nrow(homeless))

  # county FIPS: unique, 5-digit
  expect_equal(anyDuplicated(homeless$fips), 0L)
  expect_true(all(grepl("^[0-9]{5}$", homeless$fips)))
  expect_setequal(homeless$fips, homeless_na$fips)
})

test_that("homeless is fully imputed while homeless_na carries the missingness", {
  homeless    <- get_dataset("homeless")
  homeless_na <- get_dataset("homeless_na")
  count_cols  <- grep("^count[0-9]+$", names(homeless), value = TRUE)
  expect_gt(length(count_cols), 0)

  # completed data has no missing counts ...
  expect_false(any(vapply(homeless[count_cols], anyNA, logical(1))))
  # ... while the pre-imputation data does
  expect_gt(sum(vapply(homeless_na[count_cols], function(x) sum(is.na(x)), integer(1))), 0)

  # counts are non-negative
  expect_true(all(vapply(homeless[count_cols],
                         function(x) all(x[!is.na(x)] >= 0), logical(1))))
})

test_that("percentage covariates lie in [0, 100]", {
  homeless <- get_dataset("homeless")
  for (col in c("pctblack", "pctageunder18", "pctmarried")) {
    v <- homeless[[col]]
    v <- v[!is.na(v)]
    expect_true(all(v >= 0 & v <= 100), info = col)
  }
})

test_that("area covers every county used in the estimates", {
  area     <- get_dataset("area")
  homeless <- get_dataset("homeless")

  expect_true(nrow(area) >= 3140)
  expect_equal(anyDuplicated(area$fips), 0L)
  expect_true(all(area$skm > 0))
  expect_true(mean(homeless$fips %in% area$fips) > 0.99)
})
