# A quick script for now to run the geostatistical index standardization across all species
# This will be cleaned up in the future

library(ggplot2)
library(dplyr)
library(sdmTMB)
library(foreach)

spp <- gfsynopsis::get_spp_names()
spp <- dplyr::pull(dplyr::filter(spp, type %in% c("A", "B")), spp_w_hyphens)
survs <- c('SYN QCS', 'SYN HS', 'SYN WCHG', 'SYN WCVI')
all <- expand.grid(spp = spp, survs = survs,
  stringsAsFactors = FALSE)
cores <- min(nrow(all), parallel::detectCores())
cl <- parallel::makeCluster(cores)
doParallel::registerDoParallel(cl)
out <- foreach::foreach(sp = all$spp, surv = all$survs,
  .packages = c("gfplot", "sdmTMB", "gfsynopsis")) %dopar% {
    tryCatch(gfsynopsis::fit_sdmTMB_westcoast(
      here::here("report", "data-cache", paste0(sp, ".rds")),
      species_name = sp,
      survey = surv, n_knots = 200L, bias_correct = FALSE,
      anisotropy = FALSE
    ), error = function(e) NA)
  }
doParallel::stopImplicitCluster()
dir.create(here::here("report/geostat-cache"), showWarnings = FALSE)
saveRDS(out, file = here::here("report/geostat-cache/spt-index-out.rds"))

index <- purrr::map_df(out, function(x) {
  if (length(x) > 1L)
    data.frame(x$index, species = x$species_name, survey = x$survey,
      stringsAsFactors = FALSE) %>% tibble::as_tibble()
})
saveRDS(index, file = here::here("report/geostat-cache/spt-index-out-no-depth.rds"))

index$survey <- factor(index$survey, levels = survs)
# ggplot(index, aes(year, est)) + geom_line() +
#   geom_ribbon(aes(ymin = lwr, ymax = upr), alpha = 0.4) +
#   xlab('Year') + ylab('Biomass estimate (metric tonnes)') +
#   facet_grid(species~survey, scales = "free")

design_based <- purrr::map_df(unique(index$species), function(sp) {
  message(sp)
  .d <- readRDS(here::here("report", "data-cache", paste0(sp, ".rds")))
  .d$survey_index
})

index <- index %>%
  group_by(survey, species) %>%
  mutate(
    lwr = lwr / exp(mean(log(est))),
    upr = upr / exp(mean(log(est))),
    est = est / exp(mean(log(est)))
  ) %>%
  ungroup()

des <- design_based %>%
  group_by(survey_abbrev, species_common_name) %>%
  mutate(
    lowerci = lowerci / exp(mean(log(biomass))),
    upperci = upperci / exp(mean(log(biomass))),
    biomass = biomass / exp(mean(log(biomass)))
  ) %>%
  ungroup() %>%
  select(year, biomass, lowerci, upperci, survey_abbrev, species_common_name, re) %>%
  filter(survey_abbrev %in% unique(index$survey)) %>%
  rename(est = biomass, lwr = lowerci, upr = upperci, survey = survey_abbrev,
    species = species_common_name, cv = re) %>%
  mutate(species = gsub(" ", "-", species)) %>%
  mutate(species = gsub("/", "-", species)) %>%
  mutate(type = "Design based")

index$type <- "Spatiotemporal"
ind <- suppressWarnings(dplyr::bind_rows(index, des))
inds <- dplyr::group_by(ind, survey, species, type) %>%
  dplyr::summarise(
    max_cv = max(cv, na.rm = TRUE) < 1,
    max_est = max(est) < 50,
    cv_na = all(!is.na(cv)))
inds <- inds %>% dplyr::filter(max_cv, max_est, cv_na)
ind <- dplyr::semi_join(ind, inds)
ind <- dplyr::filter(ind, species != "pacific-hake")
ind$survey <- factor(ind$survey, levels = survs)
saveRDS(ind, file = here::here("report/geostat-cache/geostat-index-estimates.rds"))

# g <- ggplot(ind, aes_string('year', 'est', fill = 'type')) +
#   geom_line(aes_string(colour = 'type')) +
#   geom_point(aes_string(colour = 'type')) +
#   geom_ribbon(aes_string(ymin = 'lwr', ymax = 'upr'), alpha = 0.4) +
#   xlab('Year') + ylab('Relative biomass estimate') +
#   facet_grid(species~survey, scales = "free_y") +
#   scale_x_continuous(breaks = seq(2000, 2020, 5)) +
#   labs(colour = "Type", fill = "Type")
#
# ggsave(here::here("report/surv-2018-10-19-no-depth-150-knots.pdf"),
#   width = 9.5, height = 65, limitsize = FALSE)
