# Census-to-CoC crosswalk

``` r

library(COCHomeless)
```

The crosswalk datasets link Census geography to HUD Continuum of Care
(CoC) areas, in both directions:

- `tract_coc2019` / `tract_coc2022` – a hard assignment of each census
  tract to the CoC containing it.
- `tract_coc_wt2019` – area weights for tracts that straddle a CoC
  border.
- `county_coc2019` – county \<-\> CoC area weights (`w_coc` apportions a
  CoC down to counties; `w_county` aggregates a county up to CoCs).

The crosswalk procedure is due to Tom Byrne (Boston University); please
credit Byrne when using these data.

## National overview

``` r

nrow(tract_coc2019)                       # ~73k tracts assigned
#> [1] 73666
length(unique(tract_coc2019$COCNUM))      # ~394 CoCs
#> [1] 395
# tracts that split across more than one CoC (area-weighted file)
sum(table(tract_coc_wt2019$GEOID) > 1)
#> [1] 10168
```

## Focus: a California and a Washington CoC

List the counties that make up Seattle/King County (WA-500) and how much
of the CoC falls in each, using the area weights:

``` r

# use subset() (or which()): some tracts have NA COCNUM, and indexing a data
# frame with a logical vector containing NA returns spurious NA rows.
wa500 <- subset(county_coc2019, COCNUM == "WA-500")
wa500[order(-wa500$w_coc), c("fips", "w_coc")]
#> # A tibble: 5 × 2
#>   fips     w_coc
#>   <chr>    <dbl>
#> 1 53033 0.990   
#> 2 53061 0.00411 
#> 3 53053 0.00340 
#> 4 53037 0.00225 
#> 5 53007 0.000557
```

The tracts assigned to San Francisco’s CoC (CA-501):

``` r

ca501 <- subset(tract_coc2019, COCNUM == "CA-501")
head(ca501[, c("GEOID", "fips", "COCNAME")])
#>            GEOID  fips           COCNAME
#> 9833 06075010100 06075 San Francisco CoC
#> 9834 06075010200 06075 San Francisco CoC
#> 9835 06075010300 06075 San Francisco CoC
#> 9836 06075010400 06075 San Francisco CoC
#> 9837 06075010500 06075 San Francisco CoC
#> 9838 06075010600 06075 San Francisco CoC
nrow(ca501)
#> [1] 195
```

## Aggregating an ACS variable up to a CoC

Pull a tract-level American Community Survey variable and aggregate it
to CoCs using the area weights. (Requires a Census API key; not run
here.)

``` r

library(tidycensus)
library(dplyr)
# tract population for Washington
pop <- get_acs("tract", variables = "B01003_001", state = "WA",
               year = 2019, survey = "acs5")
tract_coc_wt2019 %>%
  inner_join(pop, by = c("GEOID")) %>%
  group_by(COCNUM, COCNAME) %>%
  summarise(coc_population = sum(estimate * w_tract), .groups = "drop") %>%
  arrange(desc(coc_population))
```

## CoC codes over time

CoCs merge and are renumbered. Roll a historical code forward to its
surviving CoC with `coc_mergers`:

``` r

head(coc_mergers)
#>   coc_pre coc_post merger_year
#> 1  MI-520   MI-500        2002
#> 2  TN-505   TN-503        2006
#> 3  KS-500   KS-507        2008
#> 4  MI-521   MI-500        2008
#> 5  MI-524   MI-500        2008
#> 6  MN-507   MN-503        2008
resolve_coc <- function(code, mergers = coc_mergers) {
  repeat {
    hit <- mergers$coc_post[match(code, mergers$coc_pre)]
    if (is.na(hit) || hit == code) return(code)
    code <- hit
  }
}
resolve_coc("AR-502")
#> [1] "AR-503"
```
