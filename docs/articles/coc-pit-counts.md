# CoC Point-in-Time homeless counts

``` r

library(COCHomeless)
```

The `hud2007`–`hud2025` data frames hold HUD’s annual Point-in-Time
(PIT) estimate of the total (“Overall Homeless”) population for each
Continuum of Care (CoC). The `coc2007`–`coc2025` objects hold the
matching CoC boundaries as `sf` polygons.

## National overview

National totals over the full series:

``` r

years <- 2007:2025
totals <- sapply(years, function(y) sum(get(paste0("hud", y))$count))
plot(years, totals / 1e6, type = "b", pch = 19,
     xlab = "Year", ylab = "Total PIT homeless (millions)",
     main = "U.S. Point-in-Time homeless counts, 2007-2025")
```

![](coc-pit-counts_files/figure-html/national-trend-1.png)

The 2021 dip reflects HUD’s pandemic waiver of the unsheltered count for
many CoCs, not a real decline.

## Sheltered, unsheltered and total, with the imputed 2021 count

`pit_us` splits the national total into sheltered and unsheltered
counts. The 2021 unsheltered count collapsed because of the waiver; the
sheltered count held up. The package ships a flagged reconstruction of
the missing 2021 unsheltered counts (`unsheltered_imp`, `total_imp`),
built CoC by CoC with a once-differenced ARIMA and Kalman smoothing, and
shown here as hollow points. HUD’s official columns are unchanged. See
[`vignette("unsheltered-imputation")`](https://ssdalab.github.io/COCHomeless/articles/unsheltered-imputation.md)
for the method and its validation.

``` r

library(ggplot2)
series <- c("total", "sheltered", "unsheltered")
obs <- do.call(rbind, lapply(series, function(s)
  data.frame(year = pit_us$year, series = s, value = pit_us[[s]])))
y21 <- pit_us$year == 2021
imp <- data.frame(year = 2021, series = c("total", "unsheltered"),
                  value = c(pit_us$total_imp[y21], pit_us$unsheltered_imp[y21]))

ggplot(obs, aes(year, value, color = series)) +
  geom_line() + geom_point(size = 1.3) +
  geom_point(data = imp, shape = 21, fill = "white", size = 3.2, stroke = 1.1) +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "U.S. PIT homeless by shelter status, 2007-2025",
       subtitle = "Hollow points: imputed 2021 (pit_us$total_imp, $unsheltered_imp)",
       y = NULL, x = NULL, color = NULL) +
  theme_minimal()
```

![](coc-pit-counts_files/figure-html/imputed-2021-1.png)

``` r

pit_us[pit_us$year == 2021, c("total", "total_imp", "unsheltered", "unsheltered_imp", "n_coc_imputed")]
#>     total total_imp unsheltered unsheltered_imp n_coc_imputed
#> 15 380630    552655       54504          226529           159
```

A national map of 2024, CoCs shaded by PIT count. Alaska and Hawaii are
repositioned with
[`tigris::shift_geometry()`](https://rdrr.io/pkg/tigris/man/shift_geometry.html)
for a compact lower-48 layout:

``` r

library(sf); library(ggplot2); library(tigris)
#> Linking to GEOS 3.15.0, GDAL 3.13.3, PROJ 9.9.0; sf_use_s2() is TRUE
#> To enable caching of data, set `options(tigris_use_cache = TRUE)`
#> in your R script or .Rprofile.
# drop the far Pacific/Caribbean territories (shift_geometry only repositions
# AK/HI/PR) so the map stays centered on the lower 48 + insets
conus <- function(x) x[!x$ST %in% c("AS", "GU", "MP", "VI"), ]
m24 <- conus(merge(coc2024, hud2024, by.x = "COCNUM", by.y = "coc_num"))
m24s <- shift_geometry(m24)
ggplot(m24s) +
  geom_sf(aes(fill = count), color = NA) +
  scale_fill_viridis_c(trans = "log10", name = "PIT\nhomeless",
                       labels = scales::comma) +
  labs(title = "Point-in-Time homeless by CoC, 2024") +
  theme_void()
```

![](coc-pit-counts_files/figure-html/national-map-1.png)

## Homeless by gender over time (CoC level)

`pit_coc_detail` carries HUD’s gender breakdown, available 2014–2024
(dropped from the 2025 release). National totals by gender, summing
across CoCs:

``` r

gen_levels <- c("Woman", "Man", "Transgender", "Non Binary",
                "More Than One Gender", "Gender Questioning")
g <- subset(pit_coc_detail, shelter == "Overall" &
            as.character(subpopulation) %in% gen_levels & !is.na(count))
agg <- aggregate(count ~ year + subpopulation, g, sum)
agg$subpopulation <- factor(as.character(agg$subpopulation), levels = gen_levels)
ggplot(agg, aes(year, count, color = subpopulation)) +
  geom_line(linewidth = 0.8) + geom_point(size = 1) +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "U.S. homeless by gender (CoC level), 2014-2024",
       y = NULL, x = NULL, color = NULL) + theme_minimal()
```

![](coc-pit-counts_files/figure-html/gender-coc-1.png)

## A helper for the two state examples

``` r

# the 3 largest CoCs in a state in 2024, and a short label for the map
top_cocs <- function(st, n = 3) {
  s <- m24[m24$ST == st, ]
  s <- s[order(-s$count), ][seq_len(n), ]
  s$label <- paste0(s$COCNUM, "\n", substr(s$COCNAME, 1, 22))
  s
}
# state map: all CoCs shaded by count, top 3 labeled by name
state_map <- function(st, title) {
  s <- m24[m24$ST == st, ]
  tp <- top_cocs(st)
  ggplot(s) +
    geom_sf(aes(fill = count), color = "grey70") +
    geom_sf_text(data = tp, aes(label = label), size = 2.6, fontface = "bold") +
    scale_fill_viridis_c(trans = "log10", name = "PIT", labels = scales::comma) +
    labs(title = title) + theme_void()
}
# per-CoC time series 2007-2025 for a set of CoC numbers
coc_series <- function(coc_nums) {
  do.call(rbind, lapply(coc_nums, function(cc) data.frame(
    year = years, COCNUM = cc,
    count = sapply(years, function(y) {
      d <- get(paste0("hud", y)); v <- d$count[d$coc_num == cc]
      if (length(v)) v else NA_real_ }))))
}
```

## California

``` r

state_map("CA", "California: PIT homeless by CoC, 2024 (top 3 labeled)")
#> Warning in st_point_on_surface.sfc(sf::st_zm(x)): st_point_on_surface may not
#> give correct results for longitude/latitude data
```

![](coc-pit-counts_files/figure-html/ca-map-1.png)

Year-by-year trend for California’s three largest CoCs:

``` r

ca_top <- top_cocs("CA")
ggplot(coc_series(ca_top$COCNUM), aes(year, count, color = COCNUM)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.3) +
  scale_color_discrete(labels = setNames(substr(ca_top$COCNAME, 1, 28), ca_top$COCNUM)) +
  labs(title = "California: largest CoCs, 2007-2025", y = "PIT homeless",
       color = NULL) + theme_minimal()
```

![](coc-pit-counts_files/figure-html/ca-trend-1.png)

## Washington

``` r

state_map("WA", "Washington: PIT homeless by CoC, 2024 (top 3 labeled)")
#> Warning in st_point_on_surface.sfc(sf::st_zm(x)): st_point_on_surface may not
#> give correct results for longitude/latitude data
```

![](coc-pit-counts_files/figure-html/wa-map-1.png)

Year-by-year trend for Washington’s three largest CoCs:

``` r

wa_top <- top_cocs("WA")
ggplot(coc_series(wa_top$COCNUM), aes(year, count, color = COCNUM)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.3) +
  scale_color_discrete(labels = setNames(substr(wa_top$COCNAME, 1, 28), wa_top$COCNUM)) +
  labs(title = "Washington: largest CoCs, 2007-2025", y = "PIT homeless",
       color = NULL) + theme_minimal()
```

![](coc-pit-counts_files/figure-html/wa-trend-1.png)

CoCs merge and are renumbered over time; use `coc_mergers` to follow a
CoC through a merger (see
[`?coc_mergers`](https://ssdalab.github.io/COCHomeless/reference/coc_mergers.md)).
