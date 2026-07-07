
library(glmmTMB)
library(dplyr)
library(spdep)
library(performance)

set.seed(123)

my_data <- read.csv("../data/january_h.csv")


my_data <- my_data %>% mutate(
  s_hour = factor(s_hour),
  day_of_week = factor(day_of_week),
  week_of_month = factor(week_of_month),
  weekend_or_weekday_sdate = factor(weekend_or_weekday_sdate),
  peak_off_peak = factor(peak_off_peak),
  is_holiday = factor(is_holiday),
  time_of_day = factor(time_of_day)
)

#-------------------------------
# Train/Test split
#-------------------------------
my_data$s_date <- as.Date(my_data$s_date)
cutoff_date <- max(my_data$s_date) - 7


train_data_st <- my_data %>% filter(s_date < cutoff_date)
test_data_st  <- my_data %>% filter(s_date >= cutoff_date)


factor_vars <- c(
  "is_holiday",
  "s_hour",
  "day_of_week",
  "time_of_day",
  "weekend_or_weekday_sdate",
  "week_of_month",
  "start_station_number"
)

for (v in factor_vars) {
  train_data_st[[v]] <- factor(train_data_st[[v]])
  test_data_st[[v]]  <- factor(test_data_st[[v]], levels = levels(train_data_st[[v]]))
}

# Drop unseen levels in test
test_data_st <- droplevels(test_data_st)


num_vars <- c(
  "dist_to_nearest_cafe",
  "dist_to_nearest_university",
  "dist_to_nearest_railway_station",
  "dist_to_nearest_pub",
  "dist_to_nearest_bank",
  "railway_station_count_5min_walk",
  "bank_count_5min_walk",
  "university_count_5min_walk",
  "pub_count_5min_walk",
  "cafe_count_5min_walk"
)

scaler <- scale(train_data_st[, num_vars])

train_data_st[, num_vars] <- scaler
test_data_st[, num_vars] <- scale(
  test_data_st[, num_vars],
  center = attr(scaler, "scaled:center"),
  scale  = attr(scaler, "scaled:scale")
)


glmm_st <- glmmTMB(
  count ~
    is_holiday +
    dist_to_nearest_cafe +
    dist_to_nearest_university +
    dist_to_nearest_railway_station +
    dist_to_nearest_pub +
    dist_to_nearest_bank +
    railway_station_count_5min_walk +
    bank_count_5min_walk +
    university_count_5min_walk +
    pub_count_5min_walk +
    cafe_count_5min_walk +
    factor(s_hour) +
    factor(day_of_week) +
    (1 | start_station_number) +             # spatial effect
    (1 | start_station_number:s_hour)+      # spatio-temporal interaction
    (1 | s_hour),                           #i added this time effect      
  family = poisson,
  data = train_data_st,
  control = glmmTMBControl(
    optCtrl = list(iter.max = 200, eval.max = 200)
  )
)

summary(glmm_st)


r2_results <- r2(glmm_st)
print(r2_results)


pred_test <- predict(glmm_st, newdata = test_data, type = "response")

rmse <- sqrt(mean((test_data$count - pred_test)^2))
mae  <- mean(abs(test_data$count - pred_test))

cat("RMSE:", rmse, "\n")
cat("MAE :", mae, "\n")


#Residuals for Spatial Autocorrelation

resid_pearson <- residuals(glmm_st, type = "pearson")

# Aggregate residuals by station 
station_residuals <- tapply(
  resid_pearson,
  train_data$start_station_number,
  mean,
  na.rm = TRUE
)

final_residuals <- as.numeric(station_residuals)
station_ids <- names(station_residuals)
names(final_residuals) <- station_ids


#Spatial Weights (Walkable Distance)

dist_matrix <- as.matrix(
  read.csv("station_walking_distance_matrix.csv", row.names = 1)
)

# Align matrix to stations
dist_matrix <- dist_matrix[station_ids, station_ids]

W_mat <- ifelse(dist_matrix <= 1000, 1, 0)
diag(W_mat) <- 0

W_list <- mat2listw(W_mat, style = "B", zero.policy = TRUE)


#GLOBAL MORAN’S I (MONTE CARLO – REPORT THIS)

moran_mc <- moran.mc(
  final_residuals,
  W_list,
  nsim = 999,
  zero.policy = TRUE
)

print(moran_mc)


