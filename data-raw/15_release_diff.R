################################################################################
# 15_release_diff.R
#
# What did this rebuild change? Compare every dataset in data/ with a reference
# release and write data-raw/qc/release_diff.csv (one row per dataset) plus
# data-raw/qc/release_diff_county.csv (the changed county-years of homeless_na
# and homeless). Use it to write the NEWS "impact" numbers, and to confirm a
# rebuild with no logic change reproduces the release exactly.
#
# Reference: the data/ at a git revision (default HEAD), or a directory of .rda
# files.  Rscript data-raw/15_release_diff.R [REV | DIR]
################################################################################

suppressMessages(library(dplyr))
arg <- commandArgs(trailingOnly = TRUE)
ref <- if (length(arg)) arg[1] else "HEAD"
if (dir.exists(ref)) {
  ref_dir <- ref
} else {
  ref_dir <- file.path(tempdir(), "ref_data"); dir.create(ref_dir, showWarnings = FALSE)
  tar <- file.path(tempdir(), "ref.tar")
  stopifnot(system2("git", c("archive", "-o", tar, ref, "data"), stdout = FALSE) == 0)
  utils::untar(tar, exdir = ref_dir); ref_dir <- file.path(ref_dir, "data")
}
load_all <- function(dir) {
  e <- new.env()
  for (f in list.files(dir, "\\.rda$", full.names = TRUE)) load(f, envir = e)
  e
}
new <- load_all("data"); old <- load_all(ref_dir)

strip <- function(x) {
  if (inherits(x, "sf")) x <- sf::st_drop_geometry(x)
  if (is.data.frame(x)) { x <- as.data.frame(x); rownames(x) <- NULL; attr(x, "note") <- NULL }
  x
}
rows <- lapply(union(ls(new), ls(old)), function(nm) {
  if (!exists(nm, new, inherits = FALSE)) return(data.frame(dataset = nm, status = "removed"))
  if (!exists(nm, old, inherits = FALSE)) return(data.frame(dataset = nm, status = "added"))
  a <- strip(old[[nm]]); b <- strip(new[[nm]])
  # align rows on the natural key, so a change of row order is not a change
  key <- function(x) intersect(c("fips", "coc_num", "COCNUM", "GEOID", "year", "shelter",
                                 "subpopulation", "coc_pre"), names(x))
  if (is.data.frame(a) && is.data.frame(b) && length(k <- intersect(key(a), key(b)))) {
    a <- a[do.call(order, unname(as.list(a[k]))), , drop = FALSE]; rownames(a) <- NULL
    b <- b[do.call(order, unname(as.list(b[k]))), , drop = FALSE]; rownames(b) <- NULL
  }
  if (identical(a, b)) return(data.frame(dataset = nm, status = "identical"))
  if (is.data.frame(a) && is.data.frame(b) && isTRUE(all.equal(a, b, check.attributes = FALSE)))
    return(data.frame(dataset = nm, status = "identical"))
  out <- data.frame(dataset = nm, status = "changed")
  if (is.data.frame(a) && is.data.frame(b)) {
    out$cols_added   <- paste(setdiff(names(b), names(a)), collapse = " ")
    out$cols_removed <- paste(setdiff(names(a), names(b)), collapse = " ")
    out$rows_old <- nrow(a); out$rows_new <- nrow(b)
    common <- intersect(names(a), names(b))
    if (nrow(a) == nrow(b)) {
      diff <- vapply(common, function(cl)
        sum(!mapply(identical, a[[cl]], b[[cl]])), 0L)
      out$cells_changed <- sum(diff)
      out$cols_changed  <- paste(names(diff)[diff > 0], collapse = " ")
    }
  }
  out
})
res <- bind_rows(rows) |> arrange(match(status, c("removed", "changed", "added", "identical")), dataset)

# county-level detail: which county-years moved
long <- function(h) h |> as.data.frame() |>
  tidyr::pivot_longer(starts_with("count"), names_to = "year", values_to = "count") |>
  mutate(year = 2000L + as.integer(sub("count", "", year))) |> select(fips, year, count)
cty <- bind_rows(lapply(c("homeless_na", "homeless"), function(nm) {
  if (!exists(nm, new) || !exists(nm, old)) return(NULL)
  full_join(long(old[[nm]]), long(new[[nm]]), by = c("fips", "year"), suffix = c("_old", "_new")) |>
    filter(!mapply(identical, count_old, count_new)) |> mutate(dataset = nm, .before = 1)
}))

dir.create("data-raw/qc", showWarnings = FALSE)
utils::write.csv(res, "data-raw/qc/release_diff.csv", row.names = FALSE)
utils::write.csv(cty, "data-raw/qc/release_diff_county.csv", row.names = FALSE)
cat(sprintf("Reference: %s\n", ref))
print(table(res$status))
show <- res[res$status != "identical", intersect(names(res),
      c("dataset", "status", "rows_old", "rows_new", "cells_changed", "cols_added", "cols_changed"))]
for (cl in intersect(c("cols_added", "cols_changed"), names(show)))
  show[[cl]] <- ifelse(nchar(show[[cl]]) > 50, paste0(substr(show[[cl]], 1, 47), "..."), show[[cl]])
print(show, row.names = FALSE)
h <- cty[cty$dataset == "homeless", ]
cat(sprintf("homeless: %d county-years changed in %d counties\n", nrow(h), length(unique(h$fips))))
