# Unit tests for the pure build functions in data-raw/00_build_helpers.R.
#
# data-raw/ is excluded from the built package, so these run under
# devtools::test() in the source tree and skip under R CMD check on the
# tarball. Every rule in the build that decides who gets counted where must
# have a test here (see TESTING.md).

helpers <- testthat::test_path("..", "..", "data-raw", "00_build_helpers.R")
skip_if_not(file.exists(helpers), "data-raw/ not available (installed package)")
source(helpers, local = TRUE)

# ---- CoC code normalisation (BUG-001, BUG-007) ------------------------------
test_that("[BUG-007] normalize_coc_code strips fiscal years embedded in codes", {
  expect_identical(normalize_coc_code(c("AL07-500", "CA08-600", "WA-500")),
                   c("AL-500", "CA-600", "WA-500"))
})

test_that("[BUG-001] normalize_coc_code strips trailing footnote letters", {
  expect_identical(normalize_coc_code(c("MO-604a", "MO-604", "CA-52x")),
                   c("MO-604", "MO-604", "CA-52x"))
  expect_identical(normalize_coc_code(factor("MO-604a")), "MO-604")
})

# ---- rounding and water-filling ---------------------------------------------
test_that("round_preserve keeps the group total and stays within 1 of input", {
  set.seed(1)
  for (i in 1:200) {
    x <- runif(sample(1:30, 1)) * sample(c(1, 10, 1000), 1)
    r <- round_preserve(x)
    expect_identical(sum(r), as.integer(round(sum(x))))
    expect_true(all(abs(r - x) < 1))
    expect_type(r, "integer")
  }
})

test_that("water_fill is proportional to D when no cap binds", {
  expect_equal(water_fill(100, c(1, 3), c(Inf, Inf)), c(25, 75))
})

test_that("water_fill conserves the total and pushes excess to headroom", {
  a <- water_fill(100, c(10, 1, 1), c(20, Inf, Inf))
  expect_equal(sum(a), 100)
  expect_equal(a[1], 20)
  expect_equal(a[2], a[3])
})

test_that("water_fill never exceeds a cap and loses only what no unit can hold", {
  a <- water_fill(100, c(1, 1), c(30, 30))
  expect_true(all(a <= 30 + 1e-9))
  expect_equal(sum(a), 60)
})

test_that("water_fill of zero is all zeros", {
  expect_equal(water_fill(0, c(1, 2, 3), rep(Inf, 3)), c(0, 0, 0))
})

# ---- boundary fallback (BUG-008) --------------------------------------------
test_that("[BUG-008] nearest_boundary_year picks the closest year, earlier on ties", {
  expect_identical(nearest_boundary_year(2010L, c(2007L, 2008L, 2013L)), 2008L)
  expect_identical(nearest_boundary_year(2011L, c(2010L, 2012L)), 2010L)
  expect_identical(nearest_boundary_year(2007L, 2015:2025), 2015L)
  expect_identical(nearest_boundary_year(2010L, 2010L), NA_integer_)
  expect_identical(nearest_boundary_year(2010L, integer()), NA_integer_)
})

# ---- primary CoC (BUG-004, BUG-009) -----------------------------------------
test_that("[BUG-009] choose_primary ignores a CoC that only slivers into a county", {
  # Sutter County 2009-2012: uncovered except a 6 km^2 sliver of Yolo's CoC.
  ov <- data.frame(fips = c("06101", "06113"), COCNUM = c("CA-521", "CA-521"),
                   a = c(6e6, 2.6e9))
  area <- c("06101" = 1.57e9, "06113" = 2.6e9)
  p <- choose_primary(ov, area, min_share = 0.01)
  expect_identical(p$fips, "06113")
})

test_that("[BUG-004] choose_primary gives each county ONE primary, the largest overlap", {
  # LA County is CA-600's; a sliver of CA-600 into Orange must not make Orange
  # a CA-600 county.
  ov <- data.frame(fips = c("06037", "06059", "06059"),
                   COCNUM = c("CA-600", "CA-600", "CA-602"),
                   a = c(1e10, 1e7, 2e9))
  area <- c("06037" = 1.06e10, "06059" = 2.05e9)
  p <- choose_primary(ov, area)
  expect_identical(setNames(p$COCNUM, p$fips), c("06037" = "CA-600", "06059" = "CA-602"))
  expect_true(all(p$share >= 0.01))
})

test_that("assign_orphans places a nested CoC in the county holding most of it", {
  ov <- data.frame(fips = c("06037", "06059"), COCNUM = c("CA-606", "CA-606"),
                   a = c(1.3e8, 1e5))
  dom <- data.frame(fips = c("06037", "06059"), COCNUM = c("CA-600", "CA-602"))
  o <- assign_orphans(ov, dom, c("CA-600", "CA-602", "CA-606"))
  expect_identical(o$fips, "06037")
  expect_identical(o$COCNUM, "CA-606")
})

# ---- bi-state split (BUG-010) -----------------------------------------------
test_that("[BUG-010] pick_split_coc charges a state residual to the right CoC", {
  resid <- c(KS = 187, MO = -187, OK = 0)
  area  <- c("MO-603" = 1.1e7, "MO-604" = 7e5, "OK-503" = 1.2e8)
  tot   <- c("MO-603" = 100, "MO-604" = 1500, "OK-503" = 231)
  # OK-503 has the largest area but Oklahoma is not short; MO-603 is coded to
  # the short state but cannot hold 187 people. Only MO-604 qualifies.
  expect_identical(pick_split_coc("KS", resid, area, tot), "MO-604")
  expect_identical(pick_split_coc("KS", c(KS = 10, MO = 0), area, tot), NA_character_)
})

test_that("[BUG-010] pick_split_coc holds the bi-state CoC fixed when it is eligible", {
  # Pre-2016: MO-606 (Missouri BoS) slivers further into Kansas than MO-604.
  resid <- c(KS = 215, MO = -215)
  area  <- c("MO-604" = 7e5, "MO-606" = 9.2e6)
  tot   <- c("MO-604" = 1500, "MO-606" = 1800)
  expect_identical(pick_split_coc("KS", resid, area, tot), "MO-606")   # area alone: wrong
  expect_identical(pick_split_coc("KS", resid, area, tot, prefer = c(KS = "MO-604")), "MO-604")
  # an ineligible preference falls back to the rule rather than forcing it
  expect_identical(pick_split_coc("KS", resid, area, c("MO-604" = 100, "MO-606" = 1800),
                                  prefer = c(KS = "MO-604")), "MO-606")
})

# ---- unsheltered imputation -------------------------------------------------
test_that("flag_missing_unsheltered flags only 2021 zeros of CoCs that count unsheltered", {
  yr <- 2017:2023
  expect_identical(flag_missing_unsheltered(yr, c(50, 50, 60, 60, 0, 70, 70)),
                   yr == 2021)
  # a CoC that never finds unsheltered people keeps its genuine zero
  expect_false(any(flag_missing_unsheltered(yr, c(0, 0, 0, 0, 0, 0, 0))))
  # a 2021 zero after a zero year is not flagged
  expect_false(any(flag_missing_unsheltered(yr, c(50, 50, 60, 0, 0, 70, 70))))
  # non-zero 2021 is a real count
  expect_false(any(flag_missing_unsheltered(yr, c(50, 50, 60, 60, 10, 70, 70))))
  # 2021 at the end of a series cannot be bracketed
  expect_false(any(flag_missing_unsheltered(2017:2021, c(50, 50, 60, 60, 0))))
})

test_that("impute_unsheltered_arima fills only flagged points, plausibly", {
  yr <- 2007:2025
  y <- round(200 * exp(0.03 * (yr - 2007)))
  miss <- yr == 2021; y0 <- y; y0[miss] <- 0
  r <- impute_unsheltered_arima(yr, y0, miss)
  expect_identical(r$value[!miss], y0[!miss])
  expect_true(all(is.na(r$method[!miss])))
  expect_true(r$method[miss] %in% c("arima_kalman", "log_linear_interp"))
  # on a smooth trend the fill lands between its neighbours
  expect_gte(r$value[miss], min(y[yr %in% c(2020, 2022)]) * 0.8)
  expect_lte(r$value[miss], max(y[yr %in% c(2020, 2022)]) * 1.2)
})

test_that("impute_unsheltered_arima falls back on short series and never goes negative", {
  r <- impute_unsheltered_arima(2019:2023, c(10, 12, 0, 14, 15),
                                c(FALSE, FALSE, TRUE, FALSE, FALSE))
  expect_identical(r$method[3], "log_linear_interp")
  expect_true(r$value[3] >= 12 && r$value[3] <= 14)
  r2 <- impute_unsheltered_arima(2007:2025, rep(0L, 19), 2007:2025 == 2021)
  expect_gte(r2$value[15], 0)
})

test_that("impute_unsheltered_arima is a no-op when nothing is missing", {
  r <- impute_unsheltered_arima(2019:2021, c(1, 2, 3), rep(FALSE, 3))
  expect_identical(r$value, c(1, 2, 3))
})

# ---- external extractors (BUG-015) ------------------------------------------------
test_that("[BUG-015] run_extractor never lets the build continue on a stale output", {
  rs <- file.path(R.home("bin"), "Rscript")
  td <- tempfile("extract"); dir.create(td); on.exit(unlink(td, recursive = TRUE))
  src <- file.path(td, "book.xlsb"); out <- file.path(td, "book.csv")
  writeLines("x", src)
  fail <- c("-e", shQuote("quit(status=1)"))
  write_out <- c("-e", shQuote(sprintf("writeLines('y', '%s')", out)))
  # failure with no output, and failure with an output older than the source
  expect_error(run_extractor(rs, fail, out, src), "extractor failed")
  writeLines("old", out); Sys.setFileTime(out, file.mtime(src) - 3600)
  expect_error(run_extractor(rs, fail, out, src), "older than")
  # a missing interpreter is a failure too
  expect_error(run_extractor("", fail, out, src), "extractor failed")
  # failure with an output newer than the source: reuse, loudly
  Sys.setFileTime(out, file.mtime(src) + 3600)
  expect_warning(run_extractor(rs, fail, out, src), "reusing")
  # success must actually refresh the output
  Sys.setFileTime(out, file.mtime(src) - 3600)
  expect_error(run_extractor(rs, c("-e", shQuote("invisible()")), out, src), "reported success")
  Sys.setFileTime(src, Sys.time() - 7200)
  expect_silent(run_extractor(rs, write_out, out, src))
})

test_that("[BUG-015] build_python prefers COCHOMELESS_PYTHON, then the project venv", {
  td <- tempfile("root"); dir.create(file.path(td, "data-raw", ".venv", "bin"), recursive = TRUE)
  on.exit(unlink(td, recursive = TRUE))
  venv <- file.path(td, "data-raw", ".venv", "bin", "python"); file.create(venv)
  withr_env <- Sys.getenv("COCHOMELESS_PYTHON", unset = NA)
  on.exit(if (is.na(withr_env)) Sys.unsetenv("COCHOMELESS_PYTHON")
          else Sys.setenv(COCHOMELESS_PYTHON = withr_env), add = TRUE)
  Sys.unsetenv("COCHOMELESS_PYTHON")
  expect_identical(build_python(td), venv)
  other <- file.path(td, "py"); file.create(other)
  Sys.setenv(COCHOMELESS_PYTHON = other)
  expect_identical(build_python(td), other)
  Sys.unsetenv("COCHOMELESS_PYTHON"); unlink(venv)
  expect_identical(build_python(td), unname(Sys.which("python3")))
})
