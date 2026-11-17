# The 2021 unsheltered imputation (data-raw/14_unsheltered_imputation.R) must
# add flagged columns without ever touching HUD's official figures.

test_that("HUD's official columns are untouched by the imputation", {
  for (yr in years_for("hud")) {
    h <- get_dataset(sprintf("hud%d", yr))
    p <- pit_coc[pit_coc$year == yr, ]
    expect_equal(sum(p$total), sum(h$count), label = sprintf("pit_coc total %d", yr))
  }
  expect_true(all(pit_coc$sheltered + pit_coc$unsheltered == pit_coc$total))
  expect_identical(pit_us$total, as.integer(tapply(pit_coc$total, pit_coc$year, sum)[as.character(pit_us$year)]))
})

test_that("imputed columns equal the official ones wherever not flagged", {
  n <- !pit_coc$unsheltered_imputed
  expect_identical(pit_coc$unsheltered_imp[n], pit_coc$unsheltered[n])
  expect_identical(pit_coc$total_imp[n], pit_coc$total[n])
  expect_true(all(is.na(pit_coc$imputation_method[n])))
  m <- !county_pit$unsheltered_imputed
  expect_identical(county_pit$unsheltered_imp[m], county_pit$unsheltered[m])
  expect_identical(county_pit$total_imp[m], county_pit$total[m])
})

test_that("imputation is confined to the 2021 waiver zeros", {
  f <- pit_coc[pit_coc$unsheltered_imputed, ]
  expect_true(all(f$year == 2021L))
  expect_true(all(f$unsheltered == 0L))
  expect_true(all(f$imputation_method %in% c("arima_kalman", "log_linear_interp")))
  expect_true(all(county_pit$year[county_pit$unsheltered_imputed] == 2021L))
  # it actually fills the hole: a large majority of the waiver zeros are imputed
  z21 <- pit_coc$year == 2021L & pit_coc$unsheltered == 0L
  expect_gt(mean(pit_coc$unsheltered_imputed[z21]), 0.8)
})

test_that("imputed values are internally consistent", {
  expect_true(all(pit_coc$unsheltered_imp >= 0))
  expect_identical(pit_coc$total_imp, pit_coc$sheltered + pit_coc$unsheltered_imp)
  expect_identical(county_pit$total_imp, county_pit$sheltered + county_pit$unsheltered_imp)
  expect_identical(pit_us$total_imp, pit_us$sheltered + pit_us$unsheltered_imp)
  expect_equal(pit_us$unsheltered_imp,
               as.numeric(tapply(pit_coc$unsheltered_imp, pit_coc$year, sum)[as.character(pit_us$year)]))
})

test_that("the county imputation conserves each CoC's imputed addition", {
  terr <- c("AS", "GU", "MP", "PR", "VI")
  f <- pit_coc[pit_coc$unsheltered_imputed & !substr(pit_coc$coc_num, 1, 2) %in% terr, ]
  add_coc <- sum(f$unsheltered_imp - f$unsheltered)
  c21 <- county_pit[county_pit$year == 2021L, ]
  expect_equal(sum(c21$unsheltered_imp - c21$unsheltered), add_coc)
})

test_that("the imputed 2021 national unsheltered count is plausible", {
  u <- setNames(pit_us$unsheltered_imp, pit_us$year)
  expect_gt(u[["2021"]], 0.85 * min(u[["2020"]], u[["2022"]]))
  expect_lt(u[["2021"]], 1.15 * max(u[["2020"]], u[["2022"]]))
})

test_that("the imputation carries its note", {
  for (x in list(pit_coc, county_pit, pit_us))
    expect_match(attr(x, "note"), "unsheltered_imputed|unsheltered_imp")
})

test_that("the published holdout backtest meets its accuracy bar", {
  f <- system.file("extdata", "unsheltered_backtest.csv", package = "COCHomeless")
  skip_if(!nzchar(f), "backtest file not installed")
  bt <- utils::read.csv(f)
  for (h in unique(bt$hold_year)) {
    b <- bt[bt$hold_year == h, ]
    expect_lt(abs(sum(b$imputed) - sum(b$actual)) / sum(b$actual), 0.10)
    expect_lt(stats::median(abs(b$imputed - b$actual) / b$actual), 0.25)
  }
})
