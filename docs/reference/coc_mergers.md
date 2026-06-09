# Continuum of Care (CoC) merger crosswalk over time

Records how HUD Continuum of Care (CoC) numbers were reassigned when
CoCs merged. CoCs merge and are renumbered frequently, so a code that
appears in an early year of the `hud20XX` / `coc20XX` series may have
been absorbed into a different CoC later. Use this table to harmonize
CoC codes across years – for example to follow a CoC's homeless counts
through a merger, or to roll historical codes forward to the surviving
CoC.

## Usage

``` r
coc_mergers
```

## Format

A data frame with one row per merger and 3 variables:

- coc_pre:

  CoC number before the merger, e.g. `"AR-502"`.

- coc_post:

  Surviving CoC number after the merger, e.g. `"AR-503"`.

- merger_year:

  Year the merger took effect (integer).

## Source

"CoC Mergers" sheet of HUD's PIT-by-CoC workbook (AHAR Part 1):
<https://www.huduser.gov/portal/datasets/ahar/2024-ahar-part-1-pit-estimates-of-homelessness-in-the-us.html>

## Examples

``` r
# Resolve any historical CoC code to its current (post-merger) code
resolve_coc <- function(code, mergers = coc_mergers) {
  repeat {
    hit <- mergers$coc_post[match(code, mergers$coc_pre)]
    if (is.na(hit) || hit == code) return(code)
    code <- hit
  }
}
resolve_coc("AR-502")  # -> "AR-503"
#> [1] "AR-503"
```
