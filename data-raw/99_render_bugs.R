################################################################################
# 99_render_bugs.R -- render BUGS.md from tests/testthat/fixtures/bug_registry.csv
#
# The CSV is the source of truth (the test suite reads it); BUGS.md is the
# human-readable view. Run from the package root after editing the registry:
#   Rscript data-raw/99_render_bugs.R
################################################################################

reg <- utils::read.csv("tests/testthat/fixtures/bug_registry.csv",
                       stringsAsFactors = FALSE)
reg <- reg[order(reg$id), ]

files <- list.files("tests/testthat", pattern = "^test-.*\\.R$", full.names = TRUE)
tests_for <- function(id) {
  hits <- unlist(lapply(files, function(f) {
    l <- readLines(f, warn = FALSE)
    l <- l[grepl("test_that\\(", l) & grepl(id, l, fixed = TRUE)]
    if (length(l)) sprintf("`%s`: %s", basename(f),
                           sub('.*test_that\\("(.*)".*', "\\1", l))
  }))
  if (length(hits)) paste0("  - ", hits, collapse = "\n") else "  - (build-only; no data test)"
}

open_ <- reg[reg$status == "open", ]
out <- c(
  "# Known bugs and fixes",
  "",
  "Running list of every defect found in COCHomeless and how it was fixed.",
  "**Source of truth:** `tests/testthat/fixtures/bug_registry.csv` -- edit that,",
  "then run `Rscript data-raw/99_render_bugs.R`. See `TESTING.md` for the process.",
  "",
  sprintf("%d registered: %d fixed, %d open.", nrow(reg),
          sum(reg$status == "fixed"), nrow(open_)),
  "",
  "| ID | Status | Found in | Fixed in | Bug |",
  "|---|---|---|---|---|",
  sprintf("| %s | %s | %s | %s | %s |", reg$id, reg$status, reg$found_in,
          ifelse(nzchar(reg$fixed_in), reg$fixed_in, "--"), reg$title),
  "")
for (i in rev(seq_len(nrow(reg)))) {
  r <- reg[i, ]
  out <- c(out,
    sprintf("## %s -- %s", r$id, r$title), "",
    sprintf("**Status:** %s. Found in %s%s.", r$status, r$found_in,
            if (nzchar(r$fixed_in)) paste0("; fixed in ", r$fixed_in) else ""), "",
    sprintf("- **Symptom:** %s", r$symptom),
    sprintf("- **Cause:** %s", r$cause),
    sprintf("- **Fix:** %s", if (nzchar(r$fix)) r$fix else "(open)"),
    "- **Regression tests:**", tests_for(r$id), "")
}
writeLines(out, "BUGS.md")
message("wrote BUGS.md (", nrow(reg), " bugs)")
