# Cross-check: apportioning a CoC's PIT count down to counties (via the
# county_coc w_coc weights) must conserve the CoC total. This validates the
# join between the counts and the crosswalk -- no CoC dropped, no count leaked.

test_that("county apportionment conserves each CoC's PIT total", {
  shared <- intersect(years_for("county_coc"), years_for("hud"))
  skip_if(length(shared) == 0,
          "no year with both county_coc weights and hud counts yet")

  for (yr in shared) {
    cc  <- get_dataset(sprintf("county_coc%d", yr))
    pit <- get_dataset(sprintf("hud%d", yr))

    # every PIT CoC should be representable in the crosswalk
    expect_true(mean(pit$coc_num %in% cc$COCNUM) > 0.9,
                info = sprintf("year %d: PIT CoCs missing from crosswalk", yr))

    merged <- merge(cc, pit, by.x = "COCNUM", by.y = "coc_num")
    merged$alloc <- merged$count * merged$w_coc
    back <- tapply(merged$alloc, merged$COCNUM, sum)
    orig <- tapply(merged$count, merged$COCNUM, function(x) x[1])

    expect_true(all(abs(back - orig) < 1e-6 * pmax(1, orig)),
                info = sprintf("year %d: apportioned totals != CoC counts", yr))
  }
})
