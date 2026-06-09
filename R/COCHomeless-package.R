#' COCHomeless: Datasets and Spatial Tools for U.S. Homelessness Research
#'
#' Provides HUD Continuum of Care (CoC) Point-in-Time homeless counts, CoC
#' geographic boundaries as simple-feature objects, a Census-to-CoC crosswalk
#' linking census tracts and counties to CoCs, and county-level homeless
#' estimates with American Community Survey covariates.
#'
#' @section Data families:
#' \describe{
#'   \item{CoC counts}{\code{hud2007}--\code{hud2024} (and the preliminary
#'     \code{hud2025_prelim}).}
#'   \item{CoC boundaries}{\code{coc2007}--\code{coc2024}, national \code{sf}.}
#'   \item{Census-to-CoC crosswalk}{\code{\link{tract_coc2019}},
#'     \code{\link{tract_coc_wt2019}}, \code{\link{county_coc2019}} (and 2022).}
#'   \item{County estimates}{\code{\link{homeless}}, \code{homeless_na},
#'     \code{sp_homeless}, \code{area}.}
#' }
#'
#' @section Citation:
#' Cite the package with \code{citation("COCHomeless")}. Individual data types
#' carry their own citations: the county-level estimates follow Almquist, Helwig
#' and You (2020) \doi{10.1080/08898480.2019.1636574}; data-source credits for
#' the Census-to-CoC crosswalk are given on the crosswalk help pages
#' (\code{\link{tract_coc2019}}, \code{\link{county_coc2019}}).
#'
#' @keywords internal
"_PACKAGE"
