################################################################################
# 03_coc_boundaries.R
#
# Build national CoC boundary datasets coc2007..coc2024 as single `sf` objects
# (one row per CoC) from HUD's per-state CoC GIS shapefiles.
#
# HUD publishes one shapefile zip per state/territory per year at
#   files.hudexchange.info/reports/published/CoC_GIS_State_Shapefile_{ST}_{YEAR}.zip
# We download all states for a year, combine, normalize the CoC code, and save.
#
# Each coc<year> is an sf with: COCNUM, COCNAME, ST, STATE_NAME, geometry.
# Run from the package root (COCHomeless/). Override years with COC_YEARS env
# var (comma-separated), e.g. COC_YEARS=2024 for a single-year test.
################################################################################

suppressMessages({ library(sf); library(dplyr) })
sf_use_s2(FALSE)
stopifnot(dir.exists("data"))

# Simplify in an equal-area projection to shrink the data ~30x (full-resolution
# national CoC polygons are ~37 MB/year). 1 km tolerance keeps shapes
# recognizable for national-scale mapping; the precise crosswalk (01_*) uses
# full-resolution geometry, so this only affects the display boundaries.
SIMPLIFY_TOL_M <- 1000

simplify_national <- function(x) {
  x <- st_make_valid(x)
  x <- st_transform(x, 5070)
  x <- st_simplify(x, dTolerance = SIMPLIFY_TOL_M, preserveTopology = TRUE)
  x <- st_make_valid(st_transform(x, 4269))
  x <- st_collection_extract(x, "POLYGON")   # drop sliver lines/points
  x[!st_is_empty(st_geometry(x)), ]
}

dl_dir <- "data-raw/downloads/coc_shp"
dir.create(dl_dir, showWarnings = FALSE, recursive = TRUE)

# 50 states + DC + 5 territories (American Samoa, Guam, N. Mariana, PR, VI)
STATES <- c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID",
            "IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO",
            "MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA",
            "RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY",
            "AS","GU","MP","PR","VI")

years <- Sys.getenv("COC_YEARS")
years <- if (nzchar(years)) as.integer(strsplit(years, ",")[[1]]) else 2007:2024

base_url <- "https://files.hudexchange.info/reports/published/"
UA  <- "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"

# normalize CoC code: strip an embedded fiscal year, e.g. "AL07-500" -> "AL-500"
normalize_coc <- function(x) sub("^([A-Z]{2})[0-9]{2}-", "\\1-", as.character(x))

# pick a column by any of several case-insensitive name variants, else NA.
# Field names changed across vintages (e.g. 2007 uses COC_NUM / COC_NAME / STATE
# rather than COCNUM / COCNAME / STATE_NAME).
col_ci <- function(df, names) {
  for (nm in names) {
    hit <- which(tolower(colnames(df)) == tolower(nm))
    if (length(hit)) return(df[[hit[1]]])
  }
  NA_character_
}

# a real zip starts with the bytes "PK"; HUD sometimes returns an HTML error
# page that we must not treat as a (cached) download.
valid_zip <- function(path) {
  if (!file.exists(path) || file.size(path) < 1000) return(FALSE)
  con <- file(path, "rb"); on.exit(close(con))
  identical(readBin(con, "raw", 2), as.raw(c(0x50, 0x4b)))
}

read_state_year <- function(st, yr) {
  zip <- file.path(dl_dir, sprintf("CoC_GIS_State_Shapefile_%s_%d.zip", st, yr))
  url <- sprintf("%sCoC_GIS_State_Shapefile_%s_%d.zip", base_url, st, yr)
  if (!valid_zip(zip)) {
    unlink(zip)
    system(sprintf('curl -sL --max-time 120 -A %s -o %s %s',
                   shQuote(UA), shQuote(zip), shQuote(url)))
    if (!valid_zip(zip)) { unlink(zip); return(NULL) }   # truly missing for st/yr
  }
  ex <- file.path(dl_dir, sprintf("%s_%d", st, yr))
  unlink(ex, recursive = TRUE); dir.create(ex, showWarnings = FALSE)
  tryCatch(utils::unzip(zip, exdir = ex), error = function(e) NULL)
  # a state zip holds one shapefile per CoC (e.g. CA_500.shp ... CA_614.shp)
  shps <- list.files(ex, pattern = "\\.shp$", full.names = TRUE, recursive = TRUE)
  if (!length(shps)) return(NULL)
  feats <- lapply(shps, function(s) {
    g <- tryCatch(st_read(s, quiet = TRUE), error = function(e) NULL)
    if (is.null(g) || !nrow(g)) return(NULL)
    st_val <- col_ci(g, "ST")
    st_sf(
      COCNUM     = normalize_coc(col_ci(g, c("COCNUM", "COC_NUM", "COCNUMBER"))),
      COCNAME    = col_ci(g, c("COCNAME", "COC_NAME")),
      ST         = ifelse(is.na(st_val), st, st_val),
      STATE_NAME = col_ci(g, c("STATE_NAME", "STATE")),
      geometry   = st_geometry(g)
    )
  })
  feats <- feats[!vapply(feats, is.null, logical(1))]
  if (!length(feats)) return(NULL)
  out <- do.call(rbind, feats)
  st_transform(st_make_valid(out), 4269)   # NAD83 lon/lat, HUD native datum
}

for (yr in years) {
  message("== ", yr, " ==")
  parts <- lapply(STATES, function(st) {
    g <- read_state_year(st, yr)
    if (!is.null(g)) message("  ", st, ": ", nrow(g), " CoCs")
    g
  })
  parts <- parts[!vapply(parts, is.null, logical(1))]
  if (!length(parts)) { message("  no data for ", yr); next }

  nat <- do.call(rbind, parts)
  nat <- nat[!is.na(nat$COCNUM) & nat$COCNUM != "", ]
  nat <- simplify_national(nat)
  # always dissolve to exactly one feature per CoC (some vintages split a CoC
  # across multiple shapefiles or multi-part geometries; make_valid can also
  # fragment features) -- done after simplify so it is the final guarantee.
  nat <- nat |>
    group_by(COCNUM) |>
    summarise(COCNAME = dplyr::first(COCNAME), ST = dplyr::first(ST),
              STATE_NAME = dplyr::first(STATE_NAME), .groups = "drop")
  obj <- sprintf("coc%d", yr)
  assign(obj, nat)
  save(list = obj, file = file.path("data", paste0(obj, ".rda")), compress = "xz")
  message(sprintf("  %s: %d CoCs, %.1f MB", obj, nrow(nat),
                  file.size(file.path("data", paste0(obj, ".rda"))) / 1e6))
}
