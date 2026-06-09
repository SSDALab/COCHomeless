# CoC-level Point-in-Time counts: schema + key integrity, every year present.

test_that("hud years are available", {
  expect_gt(length(years_for("hud")), 0)
})

for (yr in years_for("hud")) {
  test_that(sprintf("hud%d has the expected schema and keys", yr), {
    d <- get_dataset(sprintf("hud%d", yr))

    expect_s3_class(d, "data.frame")
    expect_true(all(c("coc_num", "count") %in% names(d)))

    # CoC number: present, unique, well-formed
    expect_false(anyNA(d$coc_num))
    expect_equal(anyDuplicated(d$coc_num), 0L)
    expect_mostly_coc(d$coc_num, label = sprintf("hud%d", yr))

    # count: numeric, non-negative
    expect_true(is.numeric(d$count))
    expect_true(all(d$count[!is.na(d$count)] >= 0))

    # plausible national CoC count (~380-410 CoCs since 2007)
    expect_gt(nrow(d), 350)
    expect_lt(nrow(d), 450)
  })
}

test_that("CoC identifiers are stable across adjacent years", {
  yrs <- sort(years_for("hud"))
  skip_if(length(yrs) < 2, "need >= 2 years")
  for (i in seq_len(length(yrs) - 1)) {
    a <- get_dataset(sprintf("hud%d", yrs[i]))$coc_num
    b <- get_dataset(sprintf("hud%d", yrs[i + 1]))$coc_num
    jacc <- length(intersect(a, b)) / length(union(a, b))
    expect_gt(jacc, 0.8)  # most CoCs persist year to year
  }
})

test_that("pit_us national series is consistent", {
  skip_if_not("pit_us" %in% all_datasets(), "pit_us not built")
  d <- get_dataset("pit_us")
  expect_true(all(c("year", "total", "sheltered", "unsheltered") %in% names(d)))
  expect_equal(d$sheltered + d$unsheltered, d$total)   # components sum to total
  expect_true(all(d$total > 0))
  # the 2021 unsheltered waiver dip: far below its neighbours
  u <- setNames(d$unsheltered, d$year)
  expect_lt(u["2021"], 0.5 * u["2020"])
  expect_lt(u["2021"], 0.5 * u["2022"])
})
