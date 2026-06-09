# CoC boundary objects: structure + the central cross-sectional check that the
# boundary CoC ids reconcile with the same year's Point-in-Time counts.

for (yr in years_for("coc")) {
  test_that(sprintf("coc%d has valid CoC geography", yr), {
    obj <- get_dataset(sprintf("coc%d", yr))
    ids <- coc_ids(obj)

    expect_gt(length(ids), 350)
    expect_mostly_coc(ids, label = sprintf("coc%d", yr))

    if (inherits(obj, "sf")) {
      # modern national sf: one row per CoC, valid geometry, defined CRS
      expect_false(is.na(sf::st_crs(obj)))
      expect_true(all(sf::st_is_valid(obj)))
      expect_equal(anyDuplicated(obj$COCNUM), 0L)
    }
  })
}

test_that("CoC boundary ids cross-match the Point-in-Time counts by year", {
  shared <- intersect(years_for("coc"), years_for("hud"))
  skip_if(length(shared) == 0, "no year with both coc and hud")
  for (yr in shared) {
    bnd <- coc_ids(get_dataset(sprintf("coc%d", yr)))
    pit <- unique(get_dataset(sprintf("hud%d", yr))$coc_num)
    # the vast majority of PIT-reporting CoCs should have a boundary
    matched <- mean(pit %in% bnd)
    expect_true(matched > 0.9,
                info = sprintf("year %d: %.1f%% of PIT CoCs matched a boundary",
                               yr, 100 * matched))
  }
})
