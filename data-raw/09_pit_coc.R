################################################################################
# 09_pit_coc.R
#
# Build pit_coc: per-CoC, per-year PIT homeless counts split by shelter status
# (total / sheltered / unsheltered), 2007 onward, long format. Complements the
# CoC-total hud<year> objects and the national pit_us series. Run from the
# package root after 02_hud_pit.R has downloaded the workbook.
################################################################################

stopifnot(dir.exists("data"))
xlsb <- "data-raw/downloads/PIT-by-CoC.xlsb"
csv  <- "data-raw/downloads/pit_coc.csv"
if (!file.exists(xlsb)) stop("run 02_hud_pit.R first")

py <- Sys.which("python3"); if (py == "") stop("python3 + pandas + pyxlsb required")
system2(py, c("data-raw/pit_coc_extract.py", shQuote(xlsb), shQuote(csv)))

pit_coc <- utils::read.csv(csv, colClasses = c(coc_num = "character"))
for (c in c("year", "total", "sheltered", "unsheltered"))
  pit_coc[[c]] <- as.integer(pit_coc[[c]])
pit_coc <- pit_coc[order(pit_coc$coc_num, pit_coc$year), ]
rownames(pit_coc) <- NULL

save(pit_coc, file = "data/pit_coc.rda", compress = "xz")
message(sprintf("pit_coc: %d rows, %d CoCs, %d-%d",
                nrow(pit_coc), length(unique(pit_coc$coc_num)),
                min(pit_coc$year), max(pit_coc$year)))
