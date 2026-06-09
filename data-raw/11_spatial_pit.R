################################################################################
# 11_spatial_pit.R
#
# Attach the core PIT counts (total / sheltered / unsheltered) for each year to
# that year's CoC boundary object (coc<year>), so the spatial data can be mapped
# directly without a join. Values come from pit_coc; CoCs in the boundary file
# with no PIT record that year get NA. Run after 09_pit_coc.R.
################################################################################

suppressMessages(library(sf))
stopifnot(dir.exists("data"))
load("data/pit_coc.rda")

for (yr in 2007:2025) {
  f <- sprintf("data/coc%d.rda", yr); nm <- sprintf("coc%d", yr)
  load(f); coc <- get(nm)
  coc$total <- coc$sheltered <- coc$unsheltered <- NULL          # refresh if rerun
  p <- pit_coc[pit_coc$year == yr, c("coc_num", "total", "sheltered", "unsheltered")]
  i <- match(coc$COCNUM, p$coc_num)
  coc$total       <- p$total[i]
  coc$sheltered   <- p$sheltered[i]
  coc$unsheltered <- p$unsheltered[i]
  # keep geometry last
  g <- attr(coc, "sf_column")
  coc <- coc[, c(setdiff(names(coc), g), g)]
  assign(nm, coc)
  save(list = nm, file = f, compress = "xz")
}
## ---- county spatial: add sheltered<yy>/unsheltered<yy> to sp_homeless --------
# sp_homeless already carries count<yy> (= total). Add the shelter split from
# county_pit, wide, so the county spatial object maps sheltered/unsheltered too.
suppressMessages({ library(tidyr); library(dplyr) })
load("data/sp_homeless.rda"); load("data/county_pit.rda")
wide <- county_pit |>
  mutate(yy = sprintf("%02d", year %% 100)) |>
  pivot_wider(id_cols = fips, names_from = yy,
              values_from = c(sheltered, unsheltered),
              names_glue = "{.value}{yy}")
g <- attr(sp_homeless, "sf_column")
keep <- setdiff(names(sp_homeless), c(grep("^sheltered|^unsheltered", names(sp_homeless), value = TRUE)))
sp_homeless <- sp_homeless[, keep]
sp_homeless <- merge(sp_homeless, wide, by = "fips", all.x = TRUE)
sp_homeless <- sp_homeless[, c(setdiff(names(sp_homeless), g), g)]
save(sp_homeless, file = "data/sp_homeless.rda", compress = "xz")

load("data/coc2024.rda")
message("coc20XX carry total/sheltered/unsheltered; coc2024 cols: ",
        paste(setdiff(names(coc2024), attr(coc2024, "sf_column")), collapse = ", "))
message("sp_homeless now also has sheltered<yy>/unsheltered<yy>")
