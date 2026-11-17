################################################################################
# 98_snapshot_schema.R
#
# Write the schema contract tests/testthat/fixtures/schema.csv: one row per
# (dataset, column) with the column's storage class, for every shipped dataset.
# test-data-contract.R fails if a later build drops or retypes any listed column.
# New columns are allowed.
#
# Re-running this script ACCEPTS the current schema. Do that only for a
# deliberate, NEWS-documented breaking change, or after adding columns or
# datasets you want the contract to cover.
#
# Run from the package root:  Rscript data-raw/98_snapshot_schema.R
################################################################################

col_class <- function(v) class(v)[1]
rows <- list()
for (f in sort(list.files("data", "\\.rda$", full.names = TRUE))) {
  e <- new.env(); load(f, envir = e)
  for (nm in ls(e)) {
    x <- e[[nm]]
    if (!is.data.frame(x)) next          # legacy list-of-sp objects: covered elsewhere
    rows[[length(rows) + 1]] <- data.frame(
      dataset = nm, column = names(x),
      class = vapply(as.data.frame(x), col_class, ""),   # strips sf so geometry reads as sfc_*
      row.names = NULL)
  }
}
schema <- do.call(rbind, rows)
utils::write.csv(schema, "tests/testthat/fixtures/schema.csv", row.names = FALSE)
message(sprintf("schema.csv: %d datasets, %d columns", length(unique(schema$dataset)), nrow(schema)))
