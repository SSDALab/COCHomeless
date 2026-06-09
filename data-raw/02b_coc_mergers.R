################################################################################
# 02b_coc_mergers.R
#
# Build `coc_mergers`: the Continuum of Care (CoC) longitudinal crosswalk that
# records how CoC numbers were reassigned when CoCs merged over time. CoCs
# merge and are renumbered frequently, so a code present in an early year may be
# absorbed into a different CoC later; this table lets you harmonize CoC codes
# across the hud20XX / coc20XX series.
#
# Source: the "CoC Mergers" sheet of HUD's PIT-by-CoC workbook (downloaded by
# 02_hud_pit.R). Run from the package root (COCHomeless/) after 02_hud_pit.R.
################################################################################

stopifnot(dir.exists("data"))
dl_dir <- "data-raw/downloads"
xlsb <- file.path(dl_dir, "PIT-by-CoC.xlsb")
csv  <- file.path(dl_dir, "coc_mergers_raw.csv")
if (!file.exists(xlsb)) stop("run 02_hud_pit.R first to download the workbook")

py <- Sys.which("python3")
if (py == "") stop("python3 with pandas + pyxlsb is required")
system2(py, c("data-raw/xlsb_sheet_to_csv.py", shQuote(xlsb),
              shQuote("CoC Mergers"), shQuote(csv)))

raw <- utils::read.csv(csv, check.names = FALSE)
names(raw) <- c("coc_pre", "coc_post", "merger_year")

coc_ptn <- "^[A-Z]{2}-[0-9A-Za-z]{3}$"
keep <- grepl(coc_ptn, raw$coc_pre) & grepl(coc_ptn, raw$coc_post) &
        !is.na(suppressWarnings(as.integer(raw$merger_year)))
coc_mergers <- data.frame(
  coc_pre     = as.character(raw$coc_pre[keep]),
  coc_post    = as.character(raw$coc_post[keep]),
  merger_year = as.integer(raw$merger_year[keep]),
  stringsAsFactors = FALSE
)
coc_mergers <- coc_mergers[order(coc_mergers$merger_year, coc_mergers$coc_pre), ]
rownames(coc_mergers) <- NULL

save(coc_mergers, file = "data/coc_mergers.rda", compress = "xz")
message(sprintf("coc_mergers: %d mergers, %d-%d, %d pre-codes -> %d surviving CoCs",
                nrow(coc_mergers), min(coc_mergers$merger_year),
                max(coc_mergers$merger_year),
                length(unique(coc_mergers$coc_pre)),
                length(unique(coc_mergers$coc_post))))
