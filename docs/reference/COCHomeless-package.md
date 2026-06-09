# COCHomeless: Datasets and Spatial Tools for U.S. Homelessness Research

Provides HUD Continuum of Care (CoC) Point-in-Time homeless counts, CoC
geographic boundaries as simple-feature objects, a Census-to-CoC
crosswalk linking census tracts and counties to CoCs, and county-level
homeless estimates with American Community Survey covariates.

## Data families

- CoC counts:

  `hud2007`–`hud2024` (and the preliminary `hud2025_prelim`).

- CoC boundaries:

  `coc2007`–`coc2024`, national `sf`.

- Census-to-CoC crosswalk:

  [`tract_coc2019`](https://ssdalab.github.io/COCHomeless/reference/tract_coc.md),
  [`tract_coc_wt2019`](https://ssdalab.github.io/COCHomeless/reference/tract_coc_wt.md),
  [`county_coc2019`](https://ssdalab.github.io/COCHomeless/reference/county_coc.md)
  (and 2022).

- County estimates:

  [`homeless`](https://ssdalab.github.io/COCHomeless/reference/homeless.md),
  `homeless_na`, `sp_homeless`, `area`.

## Citation

Cite the package with `citation("COCHomeless")`. Individual data types
carry their own citations: the county-level estimates follow Almquist,
Helwig and You (2020)
[doi:10.1080/08898480.2019.1636574](https://doi.org/10.1080/08898480.2019.1636574)
; data-source credits for the Census-to-CoC crosswalk are given on the
crosswalk help pages
([`tract_coc2019`](https://ssdalab.github.io/COCHomeless/reference/tract_coc.md),
[`county_coc2019`](https://ssdalab.github.io/COCHomeless/reference/county_coc.md)).

## See also

Useful links:

- <https://ssdalab.github.io/COCHomeless>

- <https://github.com/SSDALab/COCHomeless>

- Report bugs at <https://github.com/SSDALab/COCHomeless/issues>

## Author

**Maintainer**: Zack W. Almquist <zalmquist@uw.edu>
([ORCID](https://orcid.org/0000-0002-1967-7762))

Other contributors:

- Yun You \[contributor\]

- Tom Byrne (Census-to-CoC crosswalk procedure) \[contributor\]
