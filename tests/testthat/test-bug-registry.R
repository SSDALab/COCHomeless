# The bug registry (fixtures/bug_registry.csv) is the running list of every
# defect found and how it was fixed. These meta-tests keep it honest:
#   * every fixed bug has at least one regression test tagged "[BUG-NNN]"
#     (unless its fix is marked build-only),
#   * every tag in the test suite refers to a registered bug,
#   * BUGS.md (rendered by data-raw/99_render_bugs.R) is in sync.

registry <- utils::read.csv(testthat::test_path("fixtures", "bug_registry.csv"),
                            stringsAsFactors = FALSE)

test_tags <- function() {
  files <- list.files(testthat::test_path(), pattern = "^test-.*\\.R$", full.names = TRUE)
  txt <- unlist(lapply(files, readLines, warn = FALSE))
  calls <- txt[grepl("test_that\\(", txt)]
  unique(unlist(regmatches(calls, gregexpr("BUG-[0-9]{3}", calls))))
}

test_that("the bug registry is well-formed", {
  expect_identical(names(registry),
                   c("id", "title", "status", "found_in", "fixed_in",
                     "symptom", "cause", "fix"))
  expect_true(all(grepl("^BUG-[0-9]{3}$", registry$id)))
  expect_equal(anyDuplicated(registry$id), 0L)
  expect_true(all(registry$status %in% c("open", "fixed", "wontfix")))
  expect_true(all(nzchar(registry$symptom) & nzchar(registry$cause)))
  fixed <- registry$status == "fixed"
  expect_true(all(nzchar(registry$fixed_in[fixed]) & nzchar(registry$fix[fixed])))
  # ids are sequential: a gap means a bug was deleted instead of closed
  n <- as.integer(sub("BUG-", "", registry$id))
  expect_identical(sort(n), seq_len(max(n)))
})

test_that("every fixed bug has a tagged regression test", {
  need <- registry$id[registry$status == "fixed" &
                        !grepl("build-only", registry$fix, ignore.case = TRUE)]
  missing <- setdiff(need, test_tags())
  expect_identical(missing, character(0),
                   label = paste("fixed bugs with no [BUG-NNN] test:",
                                 paste(missing, collapse = ", ")))
})

test_that("every [BUG-NNN] tag in the tests is a registered bug", {
  stray <- setdiff(test_tags(), registry$id)
  expect_identical(stray, character(0))
})

test_that("BUGS.md is in sync with the registry", {
  md <- testthat::test_path("..", "..", "BUGS.md")
  skip_if_not(file.exists(md), "BUGS.md not shipped (installed package)")
  txt <- paste(readLines(md, warn = FALSE), collapse = "\n")
  for (i in seq_len(nrow(registry)))
    expect_true(grepl(sprintf("%s.*%s", registry$id[i], registry$status[i]), txt),
                label = sprintf("%s (%s) in BUGS.md -- run data-raw/99_render_bugs.R",
                                registry$id[i], registry$status[i]))
})
