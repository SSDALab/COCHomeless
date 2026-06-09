################################################################################
# 03b_coc_national_file.R
#
# Build CoC boundaries from HUD's authoritative NATIONAL boundary geodatabase,
# which is the canonical source (see Tom Byrne's crosswalk repo). One complete
# file per year -- preferable to the per-state zips used in 03_coc_boundaries.R.
#
#   https://files.hudexchange.info/resources/documents/CoC_GIS_National_Boundary_{YEAR}.zip
#
# Available for 2019-2024 (older years use the per-state files in 03_*). This is
# in particular how coc2023 is built, since HUD's per-state 2023 files are
# missing for 11 states (AK,AR,CT,KY,MA,NV,NY,SC,VA,WY,PR). Run from package root.
# Set COC_NATL_YEARS (comma-separated) to override; default 2023.
################################################################################

suppressMessages({ library(sf); library(dplyr) }); sf_use_s2(FALSE)
stopifnot(dir.exists("data"))

dl_dir <- "data-raw/downloads/coc_natl"
dir.create(dl_dir, showWarnings = FALSE, recursive = TRUE)
UA <- "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Safari/605"
base <- "https://files.hudexchange.info/resources/documents/CoC_GIS_National_Boundary_"

years <- Sys.getenv("COC_NATL_YEARS")
years <- if (nzchar(years)) as.integer(strsplit(years, ",")[[1]]) else 2023L

norm_coc <- function(x) sub("^([A-Z]{2})[0-9]{2}-", "\\1-", as.character(x))
col_ci <- function(d, nm) { for (n in nm) { h <- which(tolower(names(d)) == tolower(n))
                            if (length(h)) return(d[[h[1]]]) }; NA_character_ }
simplify_national <- function(x) {
  x <- st_transform(st_make_valid(x), 5070)
  x <- st_simplify(x, dTolerance = 1000, preserveTopology = TRUE)
  x <- st_collection_extract(st_make_valid(st_transform(x, 4269)), "POLYGON")
  x[!st_is_empty(st_geometry(x)), ]
}

for (yr in years) {
  zip <- file.path(dl_dir, sprintf("CoC_GIS_National_Boundary_%d.zip", yr))
  if (!file.exists(zip) || file.size(zip) < 1e5) {
    system(sprintf('curl -sL --max-time 180 -A %s -H %s -o %s %s%d.zip',
                   shQuote(UA), shQuote("Referer: https://www.hudexchange.info/programs/coc/gis-tools/"),
                   shQuote(zip), shQuote(base), yr))
  }
  ex <- file.path(dl_dir, sprintf("nb_%d", yr)); unlink(ex, recursive = TRUE)
  utils::unzip(zip, exdir = ex)
  gdb <- list.files(ex, pattern = "\\.gdb$", full.names = TRUE, recursive = TRUE,
                    include.dirs = TRUE)[1]
  g <- st_read(gdb, layer = st_layers(gdb)$name[1], quiet = TRUE)
  nat <- st_sf(COCNUM = norm_coc(col_ci(g, c("COCNUM", "COC_NUM"))),
               COCNAME = col_ci(g, c("COCNAME", "COC_NAME")),
               ST = col_ci(g, "ST"),
               STATE_NAME = col_ci(g, c("STATE_NAME", "STATE")),
               geometry = st_geometry(g))
  nat <- simplify_national(nat) |>
    group_by(COCNUM) |>
    summarise(COCNAME = first(COCNAME), ST = first(ST),
              STATE_NAME = first(STATE_NAME), .groups = "drop")
  obj <- sprintf("coc%d", yr); assign(obj, nat)
  save(list = obj, file = file.path("data", paste0(obj, ".rda")), compress = "xz")
  message(sprintf("  %s (national file): %d CoCs, %d states, %.1f MB", obj,
                  nrow(nat), length(unique(nat$ST)),
                  file.size(file.path("data", paste0(obj, ".rda"))) / 1e6))
}
