#' Preliminary 2025 homelessness estimates (NOT official HUD data)
#'
#' \strong{Preliminary, directional estimates only.} National, category-level
#' projections of 2025 homelessness produced by Community Solutions using a
#' population-weighted ratio estimator applied to the roughly 170 of 385 CoCs
#' (about 69 percent of the 2024 Point-in-Time population) that had reported
#' early. These figures have \emph{not} undergone HUD's quality-assurance
#' process, are not a Point-in-Time count, and are \strong{not comparable} to
#' the official \code{hud2007}--\code{hud2024} series. They are provided as a
#' clearly flagged early indicator. HUD's official 2025 Point-in-Time counts are
#' now available in \code{\link{hud2025}} (national total 742,998); this object
#' is retained for reference as the pre-release estimate.
#'
#' @format A data frame with one row per category and 7 variables:
#' \describe{
#'   \item{category}{Population: Overall, Sheltered, Unsheltered, or Veterans.}
#'   \item{count_2024}{Official 2024 baseline count.}
#'   \item{est_2025}{Preliminary 2025 estimate.}
#'   \item{pct_change}{Estimated percent change from 2024 to 2025.}
#'   \item{cocs_reporting}{Number of CoCs in the reporting sample.}
#'   \item{cocs_total}{Total number of CoCs nationwide.}
#'   \item{pop_represented_pct}{Percent of the 2024 population the sample covers.}
#' }
#' @source Community Solutions, "2025 Homelessness Estimates":
#'   \url{https://community.solutions/research-posts/2025-homelessness-estimates/}
"hud2025_prelim"
