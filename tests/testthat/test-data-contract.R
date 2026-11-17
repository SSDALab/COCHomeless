# The contract the package makes with its users: datasets keep their columns and
# types, panels have one row per key, and parallel objects agree with each other.

test_that("every shipped column keeps its name and type (schema contract)", {
  f <- test_path("fixtures", "schema.csv")
  skip_if_not(file.exists(f), "schema snapshot not available")
  schema <- utils::read.csv(f, stringsAsFactors = FALSE)
  for (nm in unique(schema$dataset)) {
    x <- as.data.frame(get_dataset(nm))
    want <- schema[schema$dataset == nm, ]
    missing <- setdiff(want$column, names(x))
    expect(length(missing) == 0,
           sprintf("%s lost column(s): %s", nm, paste(missing, collapse = ", ")))
    have <- want[want$column %in% names(x), ]
    got <- vapply(have$column, function(cl) class(x[[cl]])[1], "")
    bad <- have$column[got != have$class]
    expect(length(bad) == 0,
           sprintf("%s retyped column(s): %s", nm,
                   paste(sprintf("%s (%s -> %s)", bad, have$class[got != have$class],
                                 got[got != have$class]), collapse = ", ")))
  }
})

test_that("long panels have exactly one row per key", {
  keys <- list(pit_coc = c("coc_num", "year"),
               county_pit = c("fips", "year"),
               county_coc_alloc = c("fips", "year", "coc_num"),
               pit_coc_detail = c("coc_num", "year", "shelter", "subpopulation"),
               county_pit_detail = c("fips", "year", "shelter", "subpopulation"),
               pit_us = "year")
  for (nm in names(keys)) {
    d <- as.data.frame(get_dataset(nm))[, keys[[nm]], drop = FALSE]
    expect_false(anyNA(d), label = sprintf("%s key has NA", nm))
    # hashed check: anyDuplicated() on a data.frame pastes every row (minutes on
    # the 23M-row detail tables)
    dup <- if (requireNamespace("vctrs", quietly = TRUE)) vctrs::vec_duplicate_any(d)
           else anyDuplicated(d) > 0L
    expect_false(dup, label = sprintf("%s duplicated key", nm))
  }
})

test_that("county_pit is the full county x year grid of homeless", {
  cc <- grep("^count[0-9]{2}$", names(homeless), value = TRUE)
  yrs <- 2000L + as.integer(sub("count", "", cc))
  expect_setequal(unique(county_pit$fips), homeless$fips)
  expect_setequal(unique(county_pit$year), yrs)
  expect_equal(nrow(county_pit), length(yrs) * nrow(homeless))
})

test_that("sp_homeless carries exactly the counts in homeless", {
  sp <- as.data.frame(get_dataset("sp_homeless"))
  cc <- grep("^count[0-9]{2}$", names(homeless), value = TRUE)
  expect_true(all(cc %in% names(sp)))
  a <- as.data.frame(homeless)[order(homeless$fips), cc]
  b <- sp[order(sp$fips), cc]
  rownames(a) <- rownames(b) <- NULL
  expect_equal(b, a, ignore_attr = TRUE)
})

test_that("NEWS.md leads with the DESCRIPTION version", {
  root <- test_path("..", "..")
  skip_if_not(file.exists(file.path(root, "NEWS.md")), "NEWS.md not in this tree")
  v <- read.dcf(file.path(root, "DESCRIPTION"), "Version")[1, 1]
  first <- grep("^# ", readLines(file.path(root, "NEWS.md")), value = TRUE)[1]
  expect_match(first, paste0("COCHomeless ", gsub(".", "\\.", v, fixed = TRUE), "\\b"))
})
