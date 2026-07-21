library(sdmTMB)
library(dplyr)
library(sf)
library(spdep)
library(DHARMa)
library(car)
library(future)


season<- "winter"
number_of_days <- 59     # note that for winter only 59 days,summer 61 days,spring 61 days and summer 61 days

summer_file_path = "../data/jun_jul_aug_summer_dataset.csv"
winter_file_path = "../data/jan_feb_winter_dataset.csv"
autumn_file_path = "../data/sep_oct_nov_autumn_dataset.csv"
spring_file_path = "../data/mar_apr_may_spring_dataset.csv"



if (season=="summer"){
  data_file_path  = summer_file_path
}else if (season=="winter"){
  data_file_path  = winter_file_path 
}else if (season=="autumn"){
  data_file_path =  autumn_file_path
}else if (season=="spring"){
  data_file_path =  spring_file_path
}else{
  print("wrong season selected please stop running!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
}



data <- read.csv(data_file_path)


data %>% colnames()
bike_subset <- data %>%
  mutate(
    s_date = as.Date(s_date),
    time_of_day = as.factor(time_of_day),
    day_of_week = as.factor(day_of_week),
    week_of_month = as.factor(week_of_month),
    month = as.factor(month),
    weekend_or_weekday_sdate = as.factor(weekend_or_weekday_sdate),
    is_holiday = as.factor(is_holiday),
    start_station_number = as.factor(start_station_number),
    dist_to_nearest_supermarket = as.numeric(scale(dist_to_nearest_supermarket)),
    dist_to_nearest_station = as.numeric(scale(dist_to_nearest_station)),
    dist_to_nearest_cafe = as.numeric(scale(dist_to_nearest_cafe)),
    dist_to_nearest_bank = as.numeric(scale(dist_to_nearest_bank)),
    dist_to_nearest_pub = as.numeric(scale(dist_to_nearest_pub)),
    dist_to_nearest_university = as.numeric(scale(dist_to_nearest_university)),
    tod_daytype = as.factor(paste(weekend_or_weekday_sdate, time_of_day, sep = "_"))
  ) %>%
  arrange(s_date, s_hour) %>%
  mutate(
    time_idx = dense_rank(paste(s_date, sprintf("%02d", s_hour))),
    time_idx_hourly = s_hour,
    hour_block = floor(s_hour / 4),
    time_idx_4hr = dense_rank(paste(s_date, sprintf("%02d", hour_block))),
    hour_block_3hr = floor(s_hour / 3),
    time_idx_3hr = dense_rank(paste(s_date, sprintf("%02d", hour_block_3hr))),
    hour_block_2hr = floor(s_hour / 2),
    time_idx_2hr = dense_rank(paste(s_date, sprintf("%02d", hour_block_2hr))),
    time_idx_daily = dense_rank(as.character(s_date))
  )




## Selecting Days
bike_subset %>% select(s_date) %>% unique() %>% count()

bike_subset <- bike_subset %>%
  filter(s_date < min(s_date) + number_of_days)

bike_subset$tod_daytype %>% as.factor() %>% levels()

bike_subset %>% select(s_date) %>% unique() %>% count()

bike_subset$s_date %>% max()
bike_subset$month %>% unique()

# Project Longitude and Latitude to UTM Zone 30N (EPSG:32630)
bike_sf <- st_as_sf(bike_subset, coords = c("longitude", "latitude"), crs = 4326)
bike_sf <- st_transform(bike_sf, crs = 32630)

# Convert metres to kilometres for the mesh
coords <- st_coordinates(bike_sf) / 1000
bike_subset$X <- coords[, "X"]
bike_subset$Y <- coords[, "Y"]


boundary_mesh <- readRDS("../data/boundary_mesh.rds")

mesh_2 <- make_mesh(bike_subset, xy_cols = c("X", "Y"),mesh=boundary_mesh)
plot(mesh_2)

print(paste0("Number of knots: ", mesh_2$mesh$n))

plan(multisession, workers = 4)

set.seed(123)
model <- sdmTMB(
  formula = count ~ s(s_hour, by = day_of_week, bs = "cc", k = 24) +
    month +
    (dist_to_nearest_cafe:time_of_day) +
    (dist_to_nearest_bank:time_of_day) +
    (dist_to_nearest_station:time_of_day) +
    (dist_to_nearest_supermarket:time_of_day) +
    (dist_to_nearest_pub:time_of_day) +
    (dist_to_nearest_university:time_of_day),
  data = bike_subset,
  mesh = mesh_2,
  time = "time_idx_2hr",
  family = delta_truncated_nbinom2(),
  spatial = "on",
  spatiotemporal = list("ar1", "ar1"),
  share_range = TRUE,
  silent = FALSE
)



saveRDS(model, paste("model_",season,"_2hr_blk_100stations_few_amenities_custom_spline_cstm_mesh.rds"))


sanity(model)


tidy(model, effects = "ran_pars")


summary(model)

########################################### DHARMa residual check spatial
set.seed(123)
sims <- simulate(model, nsim = 500)
obs  <- model$data$count

dharma_res <- DHARMa::createDHARMa(
  simulatedResponse = sims,
  observedResponse = obs,
  fittedPredictedResponse = rowMeans(sims),
  integerResponse = TRUE
)

# Spatial check (groups by station)
dharma_grouped <- DHARMa::recalculateResiduals(
  dharma_res,
  group = model$data$start_station_number
)

unique_coords <- model$data %>%
  group_by(start_station_number) %>%
  summarize(X = mean(X), Y = mean(Y), .groups = "drop")

# Save plot 1 Spatial Autocorrelation
png(paste0("../outputs/",season,"dharma_spatial_autocorrelation.png"), width = 800, height = 600, res = 100)
DHARMa::testSpatialAutocorrelation(
  dharma_grouped,
  x = unique_coords$X,
  y = unique_coords$Y
)
dev.off()


########################################### DHARMa residual check temporal

# Recalculate residuals grouped by time index(here we chose time_idx because our main goal is to address lag 1)
dharma_time_grouped <- DHARMa::recalculateResiduals(
  dharma_res,
  group = model$data$time_idx
)

# Run temporal test using sorted unique time values
sorted_time_steps <- sort(unique(model$data$time_idx))

# save plot 2 Temporal Autocorrelation
png(paste0("../outputs/", season, "_dharma_temporal_autocorrelation.png"), width = 800, height = 600, res = 100)
DHARMa::testTemporalAutocorrelation(
  dharma_time_grouped,
  time = sorted_time_steps
)
dev.off()


# Visual ACF check

# save plot 3 ACF Plot
png(paste0("../outputs/",season,"dharma_acf_plot.png"), width = 800, height = 600, res = 100)
par(mfrow = c(1, 1))
acf(
  dharma_time_grouped$scaledResiduals,
  main = "ACF of DHARMa Time-Grouped Residuals"
)
dev.off()




aic_val    <- AIC(model)
bic_val    <- BIC(model)
loglik_val <- logLik(model)

aic_val
bic_val
loglik_val


