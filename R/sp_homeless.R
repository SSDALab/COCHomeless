#' County homeless estimates as a spatial (sf) object
#'
#' The completed county-level homeless estimates of \code{\link{homeless}}
#' joined to U.S. county boundaries, as a simple-feature (\code{sf}) object for
#' mapping and spatial modeling. One row per county.
#'
#' @format An \code{sf} data frame (CRS EPSG:4269, NAD83) with 3143 rows, the
#'   columns of \code{\link{homeless}} (county \code{fips}, yearly
#'   \code{count07}--\code{count25}, ACS covariates, \code{avg}), and a county
#'   boundary \code{geometry} column.
#' @source HUD Point-in-Time data disaggregated to counties; county geometry
#'   from \code{\link{counties}}; ACS covariates via \pkg{tidycensus}.
#' @seealso \code{\link{homeless}}, \code{\link{counties}}
"sp_homeless"
