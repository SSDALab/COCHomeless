# Shelter-status and subpopulation PIT datasets + spatial breakouts.

test_that("pit_coc and county_pit split into sheltered + unsheltered = total", {
  for (nm in c("pit_coc", "county_pit")) {
    skip_if_not(nm %in% all_datasets(), paste(nm, "not built"))
    d <- get_dataset(nm)
    expect_true(all(c("year", "total", "sheltered", "unsheltered") %in% names(d)))
    ok <- !is.na(d$sheltered) & !is.na(d$unsheltered)
    expect_equal(d$sheltered[ok] + d$unsheltered[ok], d$total[ok])
    expect_true(all(d$total >= 0, na.rm = TRUE))
  }
})

test_that("pit_coc_detail / county_pit_detail are well-formed", {
  for (info in list(c("pit_coc_detail", "coc_num"),
                    c("county_pit_detail", "fips"))) {
    nm <- info[1]; key <- info[2]
    skip_if_not(nm %in% all_datasets(), paste(nm, "not built"))
    d <- get_dataset(nm)
    expect_true(all(c(key, "year", "shelter", "subpopulation", "count") %in% names(d)))
    expect_true(all(c("Overall", "Sheltered Total", "Unsheltered") %in%
                      levels(factor(d$shelter))))
    expect_true("All" %in% as.character(d$subpopulation))
    expect_true(all(d$count >= 0, na.rm = TRUE))
    # gender/race/age categories are present
    expect_true(any(grepl("Veterans|Female|Black|Asian|Age ",
                          as.character(unique(d$subpopulation)))))
  }
})

test_that("spatial objects carry the core shelter breakouts", {
  skip_if_not("coc2024" %in% all_datasets(), "coc2024 not built")
  coc <- get_dataset("coc2024")
  expect_true(all(c("total", "sheltered", "unsheltered") %in% names(coc)))
  sp <- get_dataset("sp_homeless")
  expect_true(all(c("sheltered24", "unsheltered24") %in% names(sp)))
  # totals reconcile on sp_homeless: count = sheltered + unsheltered
  expect_equal(sp$count24, sp$sheltered24 + sp$unsheltered24)
})
