################################################################################
# 06_cs2025_prelim.R
#
# Build hud2025_prelim: PRELIMINARY 2025 homelessness estimates from Community
# Solutions, pending HUD's official 2025 AHAR release.
#
# These are NOT official HUD PIT counts. They come from a population-weighted
# ratio estimator applied to ~170 of 385 CoCs (~69% of the 2024 PIT
# population) and are national/category-level "directional indicators" only --
# not comparable to the official hud20XX series. National figures only (there
# is no published per-CoC 2025 dataset).
#
# Source: https://community.solutions/research-posts/2025-homelessness-estimates/
################################################################################

stopifnot(dir.exists("data"))

hud2025_prelim <- data.frame(
  category            = c("Overall", "Sheltered", "Unsheltered", "Veterans"),
  count_2024          = c(771480L, 497256L, 274224L, 32882L),
  est_2025            = c(755300L, 489600L, 265500L, 31800L),
  pct_change          = c(-2.1, -1.5, -3.2, -3.2),
  cocs_reporting      = c(170L, 170L, 170L, 177L),
  cocs_total          = c(385L, 385L, 385L, 385L),
  pop_represented_pct = c(69, 69, 69, 64),
  stringsAsFactors    = FALSE
)

save(hud2025_prelim, file = "data/hud2025_prelim.rda", compress = "xz")
message(sprintf("hud2025_prelim: %d categories; 2025 overall est = %s (%.1f%% vs 2024)",
                nrow(hud2025_prelim),
                format(hud2025_prelim$est_2025[1], big.mark = ","),
                hud2025_prelim$pct_change[1]))
