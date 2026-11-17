################################################################################
# 08_pit_us.R
#
# Build pit_us: national annual Point-in-Time totals split by shelter status
# (overall / sheltered / unsheltered), 2007 onward, from HUD's PIT-by-CoC
# workbook. Used to show the 2021 COVID unsheltered-count waiver and to
# illustrate ARIMA reconstruction of the affected year. Run from package root
# after 02_hud_pit.R has downloaded the workbook.
################################################################################

stopifnot(dir.exists("data"))
xlsb <- "data-raw/downloads/PIT-by-CoC.xlsb"
csv  <- "data-raw/downloads/pit_us.csv"
if (!file.exists(xlsb)) stop("run 02_hud_pit.R first")

source("data-raw/00_build_helpers.R")
run_extractor(build_python(), c("data-raw/pit_us_extract.py", shQuote(xlsb), shQuote(csv)),
              out = csv, src = xlsb)   # BUG-015: never continue on a stale CSV

pit_us <- utils::read.csv(csv)
pit_us[c("year", "total", "sheltered", "unsheltered")] <-
  lapply(pit_us[c("year", "total", "sheltered", "unsheltered")], as.integer)
pit_us <- pit_us[order(pit_us$year), ]
rownames(pit_us) <- NULL

save(pit_us, file = "data/pit_us.rda", compress = "xz")
message(sprintf("pit_us: %d-%d; 2021 unsheltered = %s (waiver dip)",
                min(pit_us$year), max(pit_us$year),
                format(pit_us$unsheltered[pit_us$year == 2021], big.mark = ",")))
