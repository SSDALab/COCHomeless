# COCHomeless

Datasets and spatial tools for United States homelessness research. `COCHomeless`
packages HUD Continuum of Care (CoC) Point-in-Time (PIT) homeless counts, CoC
boundaries, a Census-to-CoC crosswalk, and county-level homeless estimates,
covering **2007–2025**.

## Installation

```r
# install.packages("remotes")
remotes::install_github("SSDALab/COCHomeless", build_vignettes = TRUE)
library(COCHomeless)
```

`sf` is required (spatial objects). `tidycensus`, `ggplot2`, `tigris`,
`imputeTS` and a few others are only needed to rebuild data or run the vignettes.

## Coverage

All series run **2007 through 2025** (annual). The 2025 PIT counts are HUD's
official release; `hud2025_prelim` keeps the earlier Community Solutions estimate
for reference. In 2021 HUD waived the unsheltered count for many CoCs during
COVID-19, so 2021 understates homelessness — the vignettes show an ARIMA
reconstruction.

## Three forms of data

**1. CoC level (HUD administrative areas)**

| Object | What |
|---|---|
| `hud2007` … `hud2025` | PIT "Overall Homeless" count per CoC, by year |
| `coc2007` … `coc2025` | CoC boundary polygons (national `sf`), by year |
| `coc_mergers` | CoC merger crosswalk over time (code lineage) |
| `pit_us` | national totals split into sheltered / unsheltered |
| `hud2025_prelim` | preliminary 2025 estimate (superseded by `hud2025`) |

**2. Census ↔ CoC crosswalk** (links Census tracts/counties to CoCs)

| Object | What |
|---|---|
| `tract_coc2007` … `tract_coc2025` | tract → CoC hard assignment, by year |
| `tract_coc_wt2007` … `tract_coc_wt2025` | tract ↔ CoC area weights, by year |
| `county_coc2007` … `county_coc2025` | county ↔ CoC weights (both directions), by year |

Tract geography uses 2010-census tracts for 2007–2019 and 2020-census tracts for
2020–2025.

**3. County-level estimates** (CoC counts disaggregated to counties)

| Object | What |
|---|---|
| `homeless` | county estimates `count07`…`count25` + ACS covariates (imputed) |
| `homeless_na` | same, before imputation (missing counties as `NA`) |
| `sp_homeless` | `homeless` as an `sf` object for mapping |
| `counties`, `states` | full-US `sf` base layers |
| `area` | county land area (km²) |

## Vignettes

After installing with `build_vignettes = TRUE`:

```r
browseVignettes("COCHomeless")
```

- **CoC Point-in-Time homeless counts** (`coc-pit-counts`) — national & state
  maps, per-CoC trends, sheltered/unsheltered series with ARIMA reconstruction
  of 2021.
- **County-level homeless estimates** (`county-estimates`) — county-vs-CoC
  comparison, per-capita maps, US/CA/WA trends, a 2025 summary grid.
- **Census-to-CoC crosswalk** (`census-coc-crosswalk`) — using the crosswalk and
  `coc_mergers`.

Vignette sources are in [`vignettes/`](vignettes); build scripts that regenerate
every dataset from source are in [`data-raw/`](data-raw).

## Methodology & citation

County estimates disaggregate CoC PIT counts by population density and impute
counties with no CoC, following Almquist, Helwig & You (2020). Please cite:

> Almquist, Z. W., Helwig, N. E., & You, Y. (2020). Connecting Continuum of Care
> point-in-time homeless counts to United States Census areal units.
> *Mathematical Population Studies*, 27(1), 46–58.
> <https://doi.org/10.1080/08898480.2019.1636574>

The Census-to-CoC crosswalk follows Tom Byrne's
[HUD-CoC-Geography-Crosswalk](https://github.com/tomhbyrne/HUD-CoC-Geography-Crosswalk);
please credit it when using the `tract_coc*` / `county_coc*` data. Run
`citation("COCHomeless")` for full details.

ACS pulls need a Census API key in `~/.Renviron` (`CENSUS_API_KEY`); never commit it.
