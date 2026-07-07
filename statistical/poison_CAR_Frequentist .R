
library(dplyr)
library(glmmTMB)
library(spdep)


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
train_data_car <- my_data %>% filter(s_date < cutoff_date)
test_data_car  <- my_data %>% filter(s_date >= cutoff_date)


num_vars <- c("dist_to_nearest_cafe","dist_to_nearest_university","dist_to_nearest_railway_station",
              "dist_to_nearest_pub","dist_to_nearest_bank",
              "railway_station_count_5min_walk","bank_count_5min_walk",
              "university_count_5min_walk","pub_count_5min_walk","cafe_count_5min_walk")

train_data_car[num_vars] <- scale(train_data_car[num_vars])
train_center <- sapply(train_data_car[num_vars], mean)
train_scale  <- sapply(train_data_car[num_vars], sd)
test_data_car[num_vars] <- sweep(test_data_car[num_vars], 2, train_center, "-")
test_data_car[num_vars] <- sweep(test_data_car[num_vars], 2, train_scale, "/")


train_data_car %>% select(is_holiday) %>% str()

glmm_car <- glmmTMB(
  count ~ is_holiday + dist_to_nearest_cafe + dist_to_nearest_university +
    dist_to_nearest_railway_station + dist_to_nearest_pub + dist_to_nearest_bank +
    factor(s_hour) + factor(day_of_week) +
    railway_station_count_5min_walk + bank_count_5min_walk +
    university_count_5min_walk + pub_count_5min_walk + cafe_count_5min_walk +
    (1 | start_station_number),
  family = poisson,
  data = train_data_car,
  control = glmmTMBControl(
    optimizer = optim,        
    optArgs = list(method = "BFGS", maxit = 1000)
  )
)

summary(glmm_car)




predicted <- predict(glmm_car, newdata = test_data_car, type = "response")
actual <- test_data_car$count
rmse <- sqrt(mean((predicted - actual)^2))
mae  <- mean(abs(predicted - actual))
r2   <- r2(glmm_car)
cat("RMSE:", rmse, "MAE:", mae, "R2:")
r2







library(dplyr)
library(spdep)


resid_pearson <- residuals(glmm_car, type = "pearson")


resid_station <- data.frame(
  station = train_data_car$start_station_number,
  resid   = resid_pearson
) %>%
  group_by(station) %>%
  summarise(mean_resid = mean(resid, na.rm = TRUE))



dist_matrix <- as.matrix(
  read.csv(
    "station_walking_distance_matrix.csv",
    row.names = 1,
    check.names = FALSE
  )
)

station_ids <- rownames(dist_matrix)

resid_station <- resid_station %>%
  filter(station %in% station_ids) %>%
  arrange(match(station, station_ids))

final_residuals <- resid_station$mean_resid


threshold <- 1000  # meters

W_mat <- ifelse(dist_matrix <= threshold, 1, 0)
diag(W_mat) <- 0

W_list <- mat2listw(
  W_mat,
  style = "B",
  zero.policy = TRUE
)


#  Global Moran's I (Analytical)

moran_global <- moran.test(
  final_residuals,
  W_list,
  zero.policy = TRUE
)

print(moran_global)


# Global Moran's I (Monte Carlo)

moran_mc <- moran.mc(
  final_residuals,
  W_list,
  nsim = 999,
  zero.policy = TRUE
)

print(moran_mc)

