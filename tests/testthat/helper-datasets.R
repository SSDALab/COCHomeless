# Helpers for cross-sectional data tests.
# Datasets are discovered dynamically so the suite stays valid as new years are
# added (hud2016-2024, coc2016-2024) without editing the tests.

# Names of all exported datasets in the package.
all_datasets <- function() {
  utils::data(package = "COCHomeless")$results[, "Item"]
}

# Years present for a given dataset prefix, e.g. years_for("hud") -> 2007:2015.
years_for <- function(prefix) {
  items <- all_datasets()
  m <- regmatches(items, regexpr(paste0("^", prefix, "([0-9]{4})$"), items))
  as.integer(sub(prefix, "", m))
}

# Load a dataset object by name from the package namespace.
get_dataset <- function(name) {
  e <- new.env()
  utils::data(list = name, package = "COCHomeless", envir = e)
  get(name, envir = e)
}

# Harmonize CoC numbers across vintages. Some early HUD boundary files embed a
# 2-digit fiscal year in the code (e.g. "AL07-500"); strip it to the canonical
# "AL-500" so codes reconcile with the Point-in-Time counts.
normalize_coc <- function(x) {
  x <- as.character(x)
  sub("^([A-Z]{2})[0-9]{2}-", "\\1-", x)
}

# Extract the set of CoC numbers from a CoC boundary object, whether it is a
# modern national `sf`, a legacy list of SpatialPolygonsDataFrames, or a single
# Spatial object.
coc_ids <- function(obj) {
  pull <- function(x) {
    d <- if (methods::is(x, "Spatial")) x@data else as.data.frame(x)
    as.character(d[["COCNUM"]])   # coerce: legacy sp data stores COCNUM as factor
  }
  ids <-
    if (inherits(obj, "sf")) obj[["COCNUM"]]
    else if (methods::is(obj, "Spatial")) pull(obj)
    else if (is.list(obj) && !is.data.frame(obj)) unlist(lapply(obj, pull))
    else obj[["COCNUM"]]
  unique(stats::na.omit(normalize_coc(ids)))
}

# Regex for a well-formed CoC number, e.g. "WA-500".
COC_PATTERN <- "^[A-Z]{2}-[0-9]{3}$"

# Assert that almost all ids are well-formed CoC codes. HUD data carries a
# handful of genuine quirks (e.g. "CA-52x", boundary "Shared Jurisdiction"
# labels); we want to catch systematic format breakage, not those exceptions.
expect_mostly_coc <- function(ids, frac = 0.97, label = "") {
  ids <- as.character(ids)
  ok <- grepl(COC_PATTERN, ids)
  testthat::expect_gt(
    mean(ok), frac,
    label = sprintf("%s share of well-formed CoC codes (bad e.g. %s)",
                    label, paste(utils::head(unique(ids[!ok]), 5), collapse = ", "))
  )
}

# ---- county FIPS vintage ----------------------------------------------------
# County FIPS codes are not stable. Connecticut replaced its eight counties with
# nine planning regions, Alaska split Valdez-Cordova and renamed Wade Hampton,
# and South Dakota renamed Shannon. The package pins ONE vintage (see
# data-raw/07_base_geography.R); mixing vintages silently empties joins, which is
# how every Connecticut county came to read 0 in every year.

# Codes retired before the pinned vintage. None may appear in any dataset.
RETIRED_FIPS <- c(
  sprintf("090%02d", c(1, 3, 5, 7, 9, 11, 13, 15)),  # CT counties -> planning regions
  "02261",   # Valdez-Cordova -> Chugach (02063) + Copper River (02066)
  "02270",   # Wade Hampton   -> Kusilvak (02158)
  "46113",   # Shannon        -> Oglala Lakota (46102)
  "51515"    # Bedford city   -> merged into Bedford County (51019)
)

# Codes introduced with the pinned vintage. All must be present.
CURRENT_FIPS <- c(sprintf("091%d0", 1:9), "02063", "02066", "02158", "46102")

# County FIPS carried by a dataset, whatever shape it is.
county_fips <- function(x) {
  if (inherits(x, "sf")) x <- sf::st_drop_geometry(x)
  unique(stats::na.omit(as.character(x[["fips"]])))
}

# US territories. The county estimates cover the 50 states + DC only, matching
# the frame of Almquist, Helwig and You (2020), so territories are expected to be
# absent from the county-level families.
TERRITORY_STATEFP <- c("60", "66", "69", "72", "74", "78")
is_territory <- function(fips) substr(fips, 1, 2) %in% TERRITORY_STATEFP
