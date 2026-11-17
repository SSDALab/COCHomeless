################################################################################
# 13_qc_report.R
#
# Allocation quality-control report. Run after rebuilding the data (01-12),
# from the package root:   Rscript data-raw/13_qc_report.R
#
# Uses the same checks the test suite asserts on (tests/testthat/helper-qc.R)
# and writes every flagged row to data-raw/qc/ so a failure can be traced:
#   boundary_gaps.csv      CoC-years with a PIT count but no polygon in HUD's
#                          file that year, and the year's polygon borrowed
#   conservation.csv       HUD total vs pre-imputation county total, by year
#   sliver_primary.csv     county-years apportioned from a <1% boundary sliver
#   membership_gaps.csv    county-years imputed while their CoC still holds them
#                          in the years either side (BUG-016)
#   county_swings.csv      every extreme county swing, classified by cause
################################################################################

suppressMessages(devtools::load_all(".", quiet = TRUE))
source("tests/testthat/helper-datasets.R")
source("tests/testthat/helper-qc.R")
dir.create("data-raw/qc", showWarnings = FALSE)

unplaced <- qc_unplaced_cocs()
cons     <- qc_conservation()
cov      <- qc_primary_coverage()
sliver   <- cov[cov$has_count & cov$share < QC_MIN_PRIMARY_SHARE, ]
gaps     <- qc_membership_gaps()
swings   <- qc_county_swings()

write.csv(unplaced, "data-raw/qc/boundary_gaps.csv",  row.names = FALSE)
write.csv(cons,     "data-raw/qc/conservation.csv",   row.names = FALSE)
write.csv(sliver,   "data-raw/qc/sliver_primary.csv", row.names = FALSE)
write.csv(gaps,     "data-raw/qc/membership_gaps.csv", row.names = FALSE)
write.csv(swings,   "data-raw/qc/county_swings.csv",  row.names = FALSE)

cat("\n== Allocation QC ==\n")
cat(sprintf("HUD boundary gaps:       %d CoC-years (%s people), %d with no polygon in any year\n",
            nrow(unplaced), format(sum(unplaced$count), big.mark = ","),
            sum(is.na(unplaced$fallback_year))))
cat(sprintf("Years losing >10 people: %d (total lost %s)\n",
            sum(abs(cons$lost) > 10), format(sum(cons$lost), big.mark = ",")))
cat(sprintf("Sliver-apportioned county-years: %d\n", nrow(sliver)))
cat(sprintf("CoC membership gaps (imputed on top of their CoC): %d\n", nrow(gaps)))
cat("Extreme county swings by cause:\n"); print(table(swings$cause))
ok <- !any(is.na(unplaced$fallback_year)) && all(abs(cons$lost) <= 10) &&
  nrow(sliver) == 0 && nrow(gaps) == 0 && !any(swings$cause == "unexplained")
cat(if (ok) "\nPASS\n" else "\nFAIL -- see data-raw/qc/*.csv\n")
