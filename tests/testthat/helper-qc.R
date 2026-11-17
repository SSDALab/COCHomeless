# Quality-control checks on the CoC -> county allocation.
#
# These are the single source of truth for the allocation QC: the test suite
# (test-qc-allocation.R) asserts on them, and data-raw/13_qc_report.R sources
# this file to write a full diagnostic report after a rebuild.
#
# They exist because of two defects that let people silently vanish from, or be
# misplaced in, the county estimates without any existing test failing:
#
#  * A CoC that reports a PIT count but has no polygon in that year's HUD
#    boundary file (CA-524 Yuba/Sutter 2009-2012, LA-509, AL-505, ...) reaches
#    no county; its whole count is dropped. National tolerances of +/-3% on the
#    IMPUTED panel hid it: imputation backfilled the gap with modelled people.
#  * A county's "primary" CoC is the one covering the largest share of it, with
#    no floor. When HUD's file leaves a county uncovered, a boundary sliver of a
#    neighbouring CoC wins (Sutter County 2009-2012 drew on Yolo's CA-521 via a
#    6 km^2 overlap), handing the county a share of the wrong CoC's count and
#    producing a spurious year-over-year swing when the boundary is repaired.
#
# All checks read the shipped datasets only, so they run anywhere the package
# is installed.

QC_YEARS <- function() sort(intersect(years_for("hud"), years_for("coc")))

# CoC codes for the US territories (no counties in the county frame).
QC_TERRITORY_COC <- c("AS", "GU", "MP", "PR", "VI")
qc_is_territory_coc <- function(coc) substr(coc, 1, 2) %in% QC_TERRITORY_COC

# A primary CoC must cover at least this share of the county's area. The
# observed distribution has a clean break: 586 county-years sit below 1%
# (geometric slivers, typically ~0.01-0.1%), only ~50 between 1% and 5%.
QC_MIN_PRIMARY_SHARE <- 0.01

# Year-over-year swing that counts as "extreme": at least 3x up or down AND a
# change of at least 50 people (so tiny bases do not dominate).
qc_is_extreme <- function(prev, cur) {
  abs(log((cur + 1) / (prev + 1))) > log(3) & abs(cur - prev) >= 50
}

qc_area <- function() {
  a <- get_dataset("area")
  a$fips <- sprintf("%05d", as.integer(as.character(a$fips)))
  a
}

# ---- 1. CoCs with a PIT count but no polygon --------------------------------
# One row per (year, CoC) that reports people but has no polygon in that year's
# HUD boundary file. These are gaps in HUD's published files; the build fills
# them with the nearest year's polygon (BUG-008), recorded in
# county_primary_coc$boundary_year. `fallback_year` is NA when no year has one.
qc_unplaced_cocs <- function(years = QC_YEARS()) {
  ids <- lapply(setNames(years, years), function(yr) coc_ids(get_dataset(sprintf("coc%d", yr))))
  out <- lapply(years, function(yr) {
    h <- get_dataset(sprintf("hud%d", yr))
    h$coc_num <- as.character(h$coc_num)
    m <- h[h$count > 0 & !qc_is_territory_coc(h$coc_num) &
             !h$coc_num %in% ids[[as.character(yr)]], ]
    if (!nrow(m)) return(NULL)
    fb <- vapply(m$coc_num, function(k) {
      y <- years[vapply(ids, function(s) k %in% s, TRUE) & years != yr]
      if (!length(y)) NA_integer_ else as.integer(min(y[abs(y - yr) == min(abs(y - yr))]))
    }, 1L)
    data.frame(year = yr, coc_num = m$coc_num, count = m$count, fallback_year = unname(fb))
  })
  res <- do.call(rbind, out)
  if (is.null(res)) data.frame(year = integer(), coc_num = character(),
                               count = integer(), fallback_year = integer()) else res
}

# ---- 2. Conservation: does every reported person reach a county? -----------
# Compares HUD's state CoC total with the PRE-imputation county panel
# (homeless_na). Imputation must not be allowed to mask a leak.
qc_conservation <- function(years = QC_YEARS()) {
  hna <- get_dataset("homeless_na")
  do.call(rbind, lapply(years, function(yr) {
    h <- get_dataset(sprintf("hud%d", yr))
    h <- h[!qc_is_territory_coc(as.character(h$coc_num)), ]
    alloc <- sum(hna[[sprintf("count%02d", yr %% 100)]], na.rm = TRUE)
    data.frame(year = yr, hud = sum(h$count), county = alloc,
               lost = sum(h$count) - alloc)
  }))
}

# ---- 3. Primary-CoC coverage: is a county's count drawn from a sliver? ------
# Reads the assignment the build actually used (county_coc_alloc), so it tests
# what happened rather than re-deriving it. One row per county-year with its
# PRIMARY CoC; `has_count` marks county-years that received an apportioned
# (non-imputed) count.
qc_primary_coverage <- function(years = QC_YEARS()) {
  hna <- get_dataset("homeless_na")
  p <- get_dataset("county_coc_alloc")
  p <- p[p$year %in% years & p$role == "primary", ]
  hc <- logical(nrow(p))
  for (yr in unique(p$year)) {
    i <- p$year == yr
    hc[i] <- !is.na(hna[[sprintf("count%02d", yr %% 100)]][match(p$fips[i], hna$fips)])
  }
  data.frame(year = p$year, fips = p$fips, primary = p$coc_num, share = p$share,
             boundary_year = p$boundary_year, has_count = hc)
}

# ---- 3b. Membership gaps (BUG-016) --------------------------------------------
# County-years left to the imputation model (NA in homeless_na), covered by no
# CoC in that year's boundary file, although the county belongs to the same CoC
# in the nearest years either side and that CoC reported a count: HUD's polygon
# dropped the county for a while, and imputing it adds people on top of its
# CoC's count.
qc_membership_gaps <- function(years = QC_YEARS()) {
  hna <- get_dataset("homeless_na"); al <- get_dataset("county_coc_alloc")
  pc <- get_dataset("pit_coc")
  p <- al[al$role %in% c("primary", "bridged"), c("fips", "year", "coc_num")]
  rep_key <- paste(pc$coc_num[pc$total > 0], pc$year[pc$total > 0])
  out <- lapply(split(p, p$fips), function(f) {
    yrs <- sort(f$year); k <- setNames(f$coc_num, f$year)
    g <- setdiff(years[years > min(yrs) & years < max(yrs)], yrs)
    if (!length(g)) return(NULL)
    b <- vapply(g, function(y) k[[as.character(max(yrs[yrs < y]))]], "")
    a <- vapply(g, function(y) k[[as.character(min(yrs[yrs > y]))]], "")
    d <- data.frame(fips = f$fips[1], year = g, coc_num = b)[b == a, ]
    d[paste(d$coc_num, d$year) %in% rep_key, ]
  })
  out <- do.call(rbind, out)
  empty <- data.frame(fips = character(), year = integer(), coc_num = character())
  if (is.null(out) || !nrow(out)) return(empty)
  # Only a real gap: the county was imputed that year AND no CoC in that year's
  # boundary file covers 1% of it. (A county HUD maps into a different CoC --
  # even one that did not report -- is a boundary assignment, not a gap.)
  imputed <- vapply(seq_len(nrow(out)), function(i)
    is.na(hna[[sprintf("count%02d", out$year[i] %% 100)]][hna$fips == out$fips[i]]), TRUE)
  # share of the COUNTY's area (w_county is normalised over the covered part only)
  ar <- get_dataset("area"); km2 <- setNames(ar$skm, ar$fips)
  covered <- vapply(seq_len(nrow(out)), function(i) {
    cc <- get_dataset(sprintf("county_coc%d", out$year[i]))
    a <- cc$area_m2[cc$fips == out$fips[i]] / (km2[[out$fips[i]]] * 1e6)
    any(a >= QC_MIN_PRIMARY_SHARE)
  }, TRUE)
  out <- out[imputed & !covered, ]
  rownames(out) <- NULL
  out
}

# ---- 4. County swings, classified by cause ----------------------------------
# Every extreme county year-over-year swing, labelled with the first matching
# explanation:
#   imputed              - the county was imputed in either year
#   source CoC swing     - a CoC the county draws on moved >= 2x (a county can
#                          exceed 3x on a 2.9x CoC move through rounding)
#   CoC footprint changed- HUD redrew the CoC: the set of counties sharing its
#                          count changed, so the same total is spread differently
#   source CoC changed   - the county draws on different CoCs than last year
#   unexplained          - none of the above: manufactured by the allocation
qc_county_swings <- function(years = QC_YEARS()) {
  hom <- get_dataset("homeless"); hna <- get_dataset("homeless_na")
  pc <- get_dataset("pit_coc"); al <- get_dataset("county_coc_alloc")
  key <- function(...) paste(..., sep = "|")
  coc_tot <- setNames(pc$total, key(pc$coc_num, pc$year))
  src <- split(al$coc_num, key(al$fips, al$year))
  members <- split(al$fips, key(al$coc_num, al$year))
  big_move <- function(a, b) !is.na(a) & !is.na(b) & abs(log((b + 1) / (a + 1))) >= log(2)
  yrs <- years[(years - 1) %in% years]
  do.call(rbind, lapply(yrs, function(yr) {
    c0 <- sprintf("count%02d", (yr - 1) %% 100); c1 <- sprintf("count%02d", yr %% 100)
    ext <- qc_is_extreme(hom[[c0]], hom[[c1]])
    if (!any(ext)) return(NULL)
    idx <- which(ext)
    cause <- vapply(idx, function(i) {
      f <- hom$fips[i]
      if (is.na(hna[[c0]][i]) || is.na(hna[[c1]][i])) return("imputed")
      s0 <- src[[key(f, yr - 1)]]; s1 <- src[[key(f, yr)]]
      if (!identical(sort(s0), sort(s1))) return("source CoC changed")
      if (any(big_move(coc_tot[key(s1, yr - 1)], coc_tot[key(s1, yr)])))
        return("source CoC swing")
      if (any(vapply(s1, function(k) !setequal(members[[key(k, yr - 1)]],
                                               members[[key(k, yr)]]), TRUE)))
        return("CoC footprint changed")
      "unexplained"
    }, "")
    data.frame(year = yr, fips = hom$fips[idx], prev = hom[[c0]][idx],
               count = hom[[c1]][idx], cause = cause)
  }))
}
