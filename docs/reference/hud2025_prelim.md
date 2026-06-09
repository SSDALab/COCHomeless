# Preliminary 2025 homelessness estimates (NOT official HUD data)

**Preliminary, directional estimates only.** National, category-level
projections of 2025 homelessness produced by Community Solutions using a
population-weighted ratio estimator applied to the roughly 170 of 385
CoCs (about 69 percent of the 2024 Point-in-Time population) that had
reported early. These figures have *not* undergone HUD's
quality-assurance process, are not a Point-in-Time count, and are **not
comparable** to the official `hud2007`–`hud2024` series. They are
provided as a clearly flagged early indicator. HUD's official 2025
Point-in-Time counts are now available in
[`hud2025`](https://ssdalab.github.io/COCHomeless/reference/hud.md)
(national total 742,998); this object is retained for reference as the
pre-release estimate.

## Usage

``` r
hud2025_prelim
```

## Format

A data frame with one row per category and 7 variables:

- category:

  Population: Overall, Sheltered, Unsheltered, or Veterans.

- count_2024:

  Official 2024 baseline count.

- est_2025:

  Preliminary 2025 estimate.

- pct_change:

  Estimated percent change from 2024 to 2025.

- cocs_reporting:

  Number of CoCs in the reporting sample.

- cocs_total:

  Total number of CoCs nationwide.

- pop_represented_pct:

  Percent of the 2024 population the sample covers.

## Source

Community Solutions, "2025 Homelessness Estimates":
<https://community.solutions/research-posts/2025-homelessness-estimates/>
