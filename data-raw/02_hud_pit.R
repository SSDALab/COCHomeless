################################################################################
# 02_hud_pit.R
#
# Build the CoC-level Point-in-Time (PIT) count datasets hud2007..hud2024 from
# HUD's unified "PIT Counts by CoC" workbook (huduser.gov AHAR Part 1).
#
# Each hudYEAR is a data.frame with:
#   coc_num  CoC number, e.g. "WA-500" (character)
#   count    Overall Homeless PIT total for that year (integer)
#
# The source file is .xlsb (binary Excel) which R cannot read; we shell out to
# data-raw/pit_xlsb_extract.py (pandas + pyxlsb) to produce a tidy long CSV.
# Run from the package root (COCHomeless/).
################################################################################

stopifnot(dir.exists("data"))
dl_dir <- "data-raw/downloads"
dir.create(dl_dir, showWarnings = FALSE, recursive = TRUE)

xlsb <- file.path(dl_dir, "PIT-by-CoC.xlsb")
csv  <- file.path(dl_dir, "pit_by_coc_long.csv")

pit_url <- paste0("https://www.huduser.gov/portal/sites/default/files/xls/",
                  "2007-2025-PIT-Counts-by-CoC.xlsb")

## ---- download (HUD blocks non-browser agents; needs UA + Referer) ----------
if (!file.exists(xlsb)) {
  message("downloading PIT workbook ...")
  ua  <- "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"
  ref <- paste0("https://www.huduser.gov/portal/datasets/ahar/",
                "2025-ahar-part-1-pit-estimates-of-homelessness-in-the-us.html")
  curl_cmd <- sprintf('curl -sL --max-time 120 -A %s -H %s -o %s %s',
                      shQuote(ua), shQuote(paste0("Referer: ", ref)),
                      shQuote(xlsb), shQuote(pit_url))
  if (system(curl_cmd) != 0 || file.size(xlsb) < 1e6)
    stop("download failed; fetch ", pit_url, " manually into ", dl_dir)
}

## ---- extract to tidy CSV via Python helper ---------------------------------
py <- Sys.which("python3")
if (py == "") stop("python3 with pandas + pyxlsb is required to read .xlsb")
status <- system2(py, c("data-raw/pit_xlsb_extract.py", shQuote(xlsb), shQuote(csv)))
if (status != 0 || !file.exists(csv)) stop("xlsb extraction failed")

## ---- build one data.frame per year -----------------------------------------
long <- utils::read.csv(csv, colClasses = c(year = "integer",
                                            coc_num = "character",
                                            count = "integer"))

for (yr in sort(unique(long$year))) {
  d <- long[long$year == yr, c("coc_num", "count")]
  d <- d[order(d$coc_num), ]
  rownames(d) <- NULL
  obj <- sprintf("hud%d", yr)
  assign(obj, d)
  save(list = obj, file = file.path("data", paste0(obj, ".rda")), compress = "xz")
  message(sprintf("  %s: %d CoCs, total homeless = %s",
                  obj, nrow(d), format(sum(d$count), big.mark = ",")))
}
