library(tidyverse)
library(readr)
library(ggplot2)
library(skimr)
library(janitor)
library(lubridate)
library(ggplot2)
library(plotly)


jan_final <- read_csv("january_full_prepared.csv", col_types = cols(
  rentalID = col_character(),  # Force rentalID to be character
  BikeID = col_character(),    # Force BikeID to be character
  start_station_number = col_character(),
  start_station = col_character(),
  bike_model = col_character(),
  total_duration_mins = col_double(),
  start_date = col_datetime(),
  s_date = col_date(),
  s_time = col_time()
))
attach(jan_final)
str(jan_final)
view(jan_final)



just=jan_final_full %>% group_by(start_station_number) %>% select(start_station_number) %>% unique()

length(just$start_station_number)

jan_final_full=read_csv("jan_final_full.csv", col_types = cols(
  rentalID=col_character(),
  s_date=col_date(),
  s_time=col_time(),
  start_station_number=col_character(),
  start_station=col_character(),
  e_date=col_date(),
  e_time=col_time(),
  end_station_number=col_character(),
  end_station=col_character(),
  BikeID=col_character(),
  bike_model=col_character(),
  total_duration_mins=col_double()
))
head(jan_final_full)
view(jan_final_full)



top10_starting_stations_names=jan_final_full %>% select(start_station_number) %>% 
group_by(start_station_number) %>% summarise(count=n()) %>% arrange(desc(count)) %>% head(10)
top10_starting_stations_names
top10_starting_stations_names$start_station_number


top10_starting_stations_data=jan_final_full %>% 
  filter(start_station_number %in% 
           c( "001072","001011","002587","001075","002696","300083","000960","001064","001142","022179")) %>% 
  mutate(
    s_hour=hour(s_time),
    e_hour=hour(e_time),
    weekday_or_weekend_sdate= ifelse(wday(s_date) %in% c(1, 7), "Weekend", "Weekday"),
    weekday_or_weekend_edate = ifelse(wday(e_date) %in% c(1, 7), "Weekend", "Weekday")
  ) %>% 
  relocate(s_hour, .after = s_time) %>% 
  relocate(e_hour, .after = e_time) %>% 
  relocate(weekday_or_weekend_sdate, .after = s_date) %>% 
  relocate(weekday_or_weekend_edate, .after = e_date)
head(top10_starting_stations_data)
view(top10_starting_stations_data)

# that is my new dataset to identify the patterns

# considering the top 1 station
top1_station=top10_starting_stations_data %>% filter(start_station_number=="001072")
view(top1_station)
top1_station_1=top1_station %>% select(s_date,s_time,e_date,e_time,s_hour,e_hour,weekday_or_weekend_sdate,weekday_or_weekend_edate) %>% 
  group_by(s_date,s_hour) %>% summarise(count=n()) %>% arrange(desc(count))
top1_station_1
head(top1_station_1)
ggplot(top1_station_1,
       aes(x = s_hour, y = s_date , fill = count)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(title = "Bike rentals by date of the top 1 station(001072) hourly",
       x = "start hour",
       y = "start date",
       fill = "count") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))


ggplot(top1_station_1, 
       aes(x = s_hour, y = count)) +
  geom_bar(stat = "identity",fill="lightblue") +
  facet_wrap(~ s_date, ncol = 2) +  
  labs(
    title = "top1 station hourly count plot over the januray month",
    x = "hour",
    y = "count"
  ) +
  theme_minimal()


# from above plots we can clarify that the peak hour for top1 station is the 8th hour

# now check for same ending station

top1_station_same_StartEnd=top1_station %>% filter(end_station_number=="001072")
view(top1_station_same_StartEnd)
top1_station_same_StartEnd_1=top1_station_same_StartEnd %>%
  select(s_date,s_time,e_date,e_time,s_hour,e_hour,weekday_or_weekend_sdate,weekday_or_weekend_edate) %>% 
  group_by(s_date,s_hour) %>% summarise(count=n()) %>% arrange(desc(count))
head(top1_station_same_StartEnd_1)

ggplot(top1_station_same_StartEnd_1,
       aes(x = s_hour, y = s_date , fill = count)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(title = "Bike rentals by date of the top 1 station(001072) hourly(for same end station)",
       x = "start hour",
       y = "start date",
       fill = "count") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

ggplot(top1_station_same_StartEnd_1, 
       aes(x = s_hour, y = count)) +
  geom_bar(stat = "identity",fill="lightblue") +
  facet_wrap(~ s_date, ncol = 2) +  
  labs(
    title = "top1 station hourly count plot over the januray month(for same end station)",
    x = "hour",
    y = "count"
  ) +
  theme_minimal()

#could not find any pattern


#now check for ending stations for top 1 start station
top1_station_end_stations=top1_station %>% 
  select(end_station_number,s_date,s_hour,e_date,e_hour,total_duration_mins) %>% 
  group_by(end_station_number) %>% summarise(count=n()) %>% 
  arrange(desc(count))
view(top1_station_end_stations)  

head(unique(top1_station_end_stations$end_station_number),10)
top_10end_stations_for_top1_start_station=c(head(unique(top1_station_end_stations$end_station_number),10))
top_10end_stations_for_top1_start_station

top1_station_end_stations_top10=top1_station %>% 
  filter(end_station_number %in% top_10end_stations_for_top1_start_station) %>% 
  select(end_station_number,s_date,s_hour,e_date,e_hour,total_duration_mins) %>% 
  group_by(end_station_number,s_date) %>% summarise(count=n())

view(top1_station_end_stations_top10)


ggplot(top1_station_end_stations_top10,
       aes(x = s_date, y = end_station_number, fill = count)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "green") +
  labs(title = "Bike rentals for top 1 start station(001072) and its top 10 ending stations over month",
       x = "Date",
       y = "end Station",
       fill = "count") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))




heatmap_data <- top1_station %>%
  filter(end_station_number %in% top_10end_stations_for_top1_start_station) %>%  # Filter for top 10 end stations
  group_by(end_station_number,e_date,e_hour) %>%
  summarise(count = n(), .groups = 'drop')  # Count bikes ending at each station per hour and date

# Step 2: Create the heatmap
ggplot(heatmap_data, aes(x = e_hour, y = e_date, fill = count)) +
  geom_tile() +
  facet_wrap(~end_station_number, ncol = 2) +  # Facet by end station
  scale_fill_gradient(low = "white", high = "red") +  # Color gradient for counts
  labs(title = "Ending Bike Counts by Hour and Date for Top 10 End Stations",
       x = "Hour of the Day",
       y = "Date",
       fill = "Bike Count") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels



ggplot(heatmap_data, aes(x = interaction(s_date, s_hour), y = count, group = end_station_number, color = end_station_number)) +
  geom_line() +
  facet_wrap(~end_station_number, ncol = 2) +  # Facet by end station
  labs(title = "Ending Bike Counts by Hour and Date for Top 10 End Stations",
       x = "Date and Hour",
       y = "Bike Count",
       color = "End Station") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))  # Rotate x-axis labels for better readability


ggplot(heatmap_data, aes(x = s_hour, y = count, group = s_date, color = as.factor(s_date))) +
  geom_line() +
  facet_grid(~end_station_number) +  # Facet by end station
  labs(title = "Ending Bike Counts by Hour and Date for Top 10 End Stations",
       x = "Hour of the Day",
       y = "Bike Count",
       color = "Date") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels

#now check for the end station 001072 and their top starting stations
top1_station_as_ending_station=jan_final_full %>% 
  filter(end_station_number=="001072",start_station_number %in% top_10end_stations_for_top1_start_station ) %>%
  select(start_station_number,s_date,s_time,e_date,e_time,total_duration_mins) %>% 
  group_by(start_station_number) %>% summarise(count=n())


selected_10_stations_data <- jan_final_full %>%
  filter(end_station_number=="001072",start_station_number %in% top_10end_stations_for_top1_start_station) %>%  # Filter for top 10 end stations
  group_by(start_station_number,s_date,s_hour=hour(s_time)) %>%
  summarise(count = n(), .groups = 'drop')
unique(selected_10_stations_data$start_station_number)

ggplot(selected_10_stations_data, aes(x = s_hour, y = s_date, fill = count)) +
  geom_tile() +
  facet_wrap(~start_station_number, ncol = 2) +  # Facet by end station
  scale_fill_gradient(low = "white", high = "purple") +  # Color gradient for counts
  labs(title = "Ending Bike Counts by Hour and Date for Top 1 start Station as ending station for top10 ending stations",
       x = "Hour of the Day",
       y = "Date",
       fill = "Bike Count") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels


selected_10_stations_data_notending_001072 <- jan_final_full %>%
  filter(start_station_number %in% top_10end_stations_for_top1_start_station) %>%  # Filter for top 10 end stations
  group_by(start_station_number,s_date,s_hour=hour(s_time)) %>%
  summarise(count = n(), .groups = 'drop')

ggplot(selected_10_stations_data_notending_001072, aes(x = s_hour, y = s_date, fill = count)) +
  geom_tile() +
  facet_wrap(~start_station_number, ncol = 2) +  # Facet by end station
  scale_fill_gradient(low = "white", high = "blue") +  # Color gradient for counts
  labs(title = "starting Counts by Hour and Date for Top 1's ending stations ",
       x = "Hour of the Day",
       y = "Date",
       fill = "Bike Count") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels



testing_the_count1=jan_final_full %>% 
  filter(start_station_number=="001072",end_station_number %in% top_10end_stations_for_top1_start_station ) %>% 
  group_by(end_station_number) %>% summarise(count=n())
testing_the_count1

testing_the_count2=jan_final_full %>% 
  filter(end_station_number=="001072",start_station_number %in% top_10end_stations_for_top1_start_station ) %>% 
  group_by(start_station_number) %>% summarise(count=n())
testing_the_count2

sum(testing_the_count1$count)
sum(testing_the_count2$count)


testing_the_count1_withDay=jan_final_full %>% 
  filter(s_date==e_date,start_station_number=="001072",end_station_number %in% top_10end_stations_for_top1_start_station ) %>% 
  group_by(end_station_number,s_date) %>% summarise(count=n())
view(testing_the_count1_withDay)

testing_the_count2_withDay=jan_final_full %>% 
  filter(s_date==e_date,end_station_number=="001072",start_station_number %in% top_10end_stations_for_top1_start_station ) %>% 
  group_by(start_station_number,s_date) %>% summarise(count=n())
view(testing_the_count2_withDay)


#trying to merge and see

testing_the_count1_withDay_processing=testing_the_count1_withDay %>%
  rename(station_number = end_station_number, in_count = count)

testing_the_count2_withDay_processing=testing_the_count2_withDay %>%
  rename(station_number = start_station_number, out_count = count)

sum(testing_the_count1_withDay_processing$in_count)
sum(testing_the_count2_withDay_processing$out_count)
764-697


leaving_returing_merged_data = full_join(testing_the_count1_withDay_processing, testing_the_count2_withDay_processing, by = c("station_number", "s_date"))
head(leaving_returing_merged_data)
sum(is.na(leaving_returing_merged_data))  #29 na data
leaving_returing_merged_data = leaving_returing_merged_data %>%
  mutate(in_count = ifelse(is.na(in_count), 0, in_count),
         out_count = ifelse(is.na(out_count), 0, out_count))
sum(is.na(leaving_returing_merged_data)) #0 na data

leaving_returing_merged_data <- leaving_returing_merged_data %>%
  mutate(difference = in_count - out_count)
view(leaving_returing_merged_data)

head(leaving_returing_merged_data)

ggplot(leaving_returing_merged_data, aes(x = s_date)) +
  geom_line(aes(y = in_count, color = "in-count")) +
  geom_line(aes(y = out_count, color = "out-count")) +
  facet_wrap(~station_number, scales = "free_y") + 
  labs(title = "Bikes Leaving vs Returning for Station 001072",
       x = "Date",
       y = "Count",
       color = "Legend") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))



explain_my_point=leaving_returing_merged_data %>% filter(difference<=0)
no_of_recors_explain_my_point=nrow(explain_my_point)
no_of_recors_explain_my_point #121
view(explain_my_point)



not_explain_my_point=leaving_returing_merged_data %>% filter(difference>0)
no_of_recors_not_explain_my_point=nrow(not_explain_my_point)
no_of_recors_not_explain_my_point #84
view(explain_my_point)

#adding weekday and weekend
leaving_returing_merged_data_with_week_end=leaving_returing_merged_data %>% 
  mutate(
    weekday_or_weekend=ifelse(wday(s_date) %in% c(1, 7), "Weekend", "Weekday")
  ) %>% 
  relocate(weekday_or_weekend, .after = s_date)
head(leaving_returing_merged_data_with_week_end)


january_dates <- seq(as.Date("2023-01-01"), as.Date("2023-01-31"), by = "day")

# Identify weekends in January
weekend_data <- data.frame(
  s_date = january_dates,
  weekday_or_weekend = ifelse(wday(january_dates) %in% c(1, 7), "Weekend", "Weekday")
) %>%
  filter(weekday_or_weekend == "Weekend")  # Keep only weekends

# Step 3: Create the plot with weekend shading
ggplot(leaving_returing_merged_data_with_week_end, aes(x = s_date)) +
  # Add shaded rectangles for weekends
  geom_rect(
    data = weekend_data,
    aes(xmin = s_date - 0.5, xmax = s_date + 0.5, ymin = -Inf, ymax = Inf),
    fill = "pink", alpha = 0.4
  ) +
  # Add lines for leaving and returning counts
  geom_line(aes(y = in_count, color = "in-count")) +
  geom_line(aes(y = out_count, color = "out-count")) +
  facet_wrap(~station_number, scales = "free_y") +
  labs(
    title = "Bikes Leaving vs Returning for Station 001072",
    x = "Date",
    y = "Count",
    color = "Legend"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))




#now trying to connect average total duration from 001072 to top 10 end stations
duration_from_001072_to_top_10_end_stations=jan_final_full %>% 
  filter(start_station_number=="001072",end_station_number %in% top_10end_stations_for_top1_start_station) %>% 
  group_by(end_station_number) %>% summarise(total_duration_mins)
view(duration_from_001072_to_top_10_end_stations)


ggplot(duration_from_001072_to_top_10_end_stations,aes(x=end_station_number,y=total_duration_mins,fill=end_station_number))+
  geom_boxplot(outlier.color = "red")

duration_from_top_10_end_stations_to_001072=jan_final_full %>% 
  filter(end_station_number=="001072",start_station_number %in% top_10end_stations_for_top1_start_station) %>% 
  group_by(start_station_number) %>% summarise(total_duration_mins)
view(duration_from_top_10_end_stations_to_001072)
ggplot(duration_from_top_10_end_stations_to_001072,aes(x=start_station_number,y=total_duration_mins,fill=start_station_number))+
  geom_boxplot(outlier.color = "red")

p1=jan_final_full %>% 
  filter(end_station_number=="001072",start_station_number %in% top_10end_stations_for_top1_start_station) %>% 
  group_by(start_station_number) %>% summarise(median(total_duration_mins))
view(p1)
meds=c(p1$`median(total_duration_mins)`)
meds

#chcking daily
daily_duration_from_001072_to_top_10_end_stations=jan_final_full %>% 
  filter(start_station_number=="001072",end_station_number %in% top_10end_stations_for_top1_start_station) %>% 
  group_by(end_station_number,s_date) %>% summarise(total_duration_mins)
view(daily_duration_from_001072_to_top_10_end_stations)

ggplot(daily_duration_from_001072_to_top_10_end_stations,aes(x=end_station_number,y=total_duration_mins,fill=end_station_number))+
  geom_boxplot(outlier.color = "red")+
  facet_wrap(~s_date)





# Given data
W <- matrix(c(
  1.2, 15.4, -40.2,
  -0.1, 8.8, -26.9,
  1.9, 11.8, -25.9,
  6.7, 18.4, -21.7
), nrow = 4, byrow = TRUE)

# Given mean vector and covariance matrix
mean_W <- c(2.425, 13.6, -28.675)
cov_W <- matrix(c(
  8.8091, 10.46, -15.9677,
  10.46, 17.52, -13.86,
  -15.9677, -13.86, 64.109
), nrow = 3)

# Compute standard deviations
sigma_W <- sqrt(diag(cov_W))

# Standardize the matrix (Zw)
Zw <- sweep(W, 2, mean_W, "-") %>% sweep(2, sigma_W, "/")

# Compute Zw'Zw
Zw_crossprod <- crossprod(Zw)

# Results
print("Standardized Matrix Zw:")
print(Zw, digits = 6)

print("\nCross-product Zw'Zw:")
print(Zw_crossprod, digits = 6)

print("\nCovariance Matrix of Zw (should match correlation matrix):")
print(cov(Zw), digits = 6)  # Alternatively: (1/(n-1)) * Zw_crossprod






# Given data matrix X
X <- matrix(c(
  11, 13, 3.2,
  4, 9, 4.9,
  7, 8, 2.9,
  9, 5, 2.7
), nrow = 4, byrow = TRUE)

# Transformation matrix A
A <- matrix(c(
  1, -1, 1,
  2, -1, 2,
  -1, -2, -1
), nrow = 3, byrow = TRUE)

# Part (a): Sample statistics for X
# ---------------------------------
# Sample mean vector
mean_X <- colMeans(X)

# Centered data matrix
X_centered <- scale(X, center = TRUE, scale = FALSE)

# Sample covariance matrix S
S <- cov(X)

# Sample correlation matrix R
R <- cor(X)

# Part (b): Transformed variables W
# ---------------------------------
# Compute W = XA'
W <- X %*% t(A)

# Mean vector of W
mean_W <- colMeans(W)

# Covariance matrix of W
cov_W <- cov(W)

# Correlation matrix of W
cor_W <- cor(W)

# Part (c): Standardized matrix Z_W
# ---------------------------------
# Standardize W to get Z_W
Z_W <- scale(W)

# Verify cov(Z_W) equals cor(W)
cov_Z_W <- cov(Z_W)


# Results
# -------
cat("Part (a): Sample Statistics for X\n")
cat("---------------------------------\n")

cat("Sample mean vector:\n")
print(mean_X)
cat("\nSample covariance matrix S:\n")
print(S)
cat("\nSample correlation matrix R:\n")
print(R)

cat("\n\nPart (b): Transformed Variables W\n")
cat("---------------------------------\n")
cat("W matrix:\n")
print(W)
cat("\nMean vector of W:\n")
print(mean_W)
cat("\nCovariance matrix of W:\n")
print(cov_W)
cat("\nCorrelation matrix of W:\n")
print(cor_W)

cat("\n\nPart (c): Standardized Matrix Z_W\n")
cat("---------------------------------\n")
cat("Standardized matrix Z_W:\n")
print(Z_W)
cat("\nCovariance matrix of Z_W (should match cor(W)):\n")
print(cov_Z_W)
cat("\nVerification (cov(Z_W) - cor(W)):\n")
print(cov_Z_W - cor_W)  # Should be approximately zero
# Problem 4: Electricity Consumption Analysis
# Full Solution in R

# 1. Input the data
data <- data.frame(
  
  X1 = c(11.55, 6.82, 5.54, 6.61, 7.91, 7.16, 8.06, 7.77, 8.68, 6.01, 7.68, 6.88, 6.98, 7.77, 6.92),
  X2 = c(1.55, 1.65, 1.84, 3.68, 1.93, 1.43, 1.78, 2.6, 1.62, 1.78, 6.9, 1.61, 2.79, 2.07, 1.88),
  Y1 = c(20.11, 29.74, 21.72, 24.17, 17.43, 18.88, 16.93, 20.83, 19.74, 23.43, 21.04, 18.73, 37.57, 21.59, 25.78),
  Y2 = c(4.85, 2.81, 3.19, 4.82, 3.61, 2.88, 4.23, 3.22, 3.69, 3.24, 4.88, 3.47, 2.65, 1.38, 2.95)
)

# 2. Compute mean vector
mean_W <- colMeans(data)
names(mean_W) <- c("X1", "X2", "Y1", "Y2")

# 3. Compute full covariance matrix
S <- cov(data)

# 4. Partition covariance matrix
S_XX <- S[3:4, 3:4]  # Covariance of X (X1, X2)
S_YY <- S[1:2, 1:2]  # Covariance of Y (Y1, Y2)
S_XY <- S[3:4, 1:2]  # Cross-covariance X vs Y
S_YX <- t(S_XY)      # Transpose of S_XY

# 5. Print all results
cat("=== Sample Mean Vector ===\n")
print(mean_W)

cat("\n=== Partitioned Covariance Matrices ===\n")
cat("\nS_XX (Covariance of X1, X2):\n")
print(S_XX)

cat("\nS_YY (Covariance of Y1, Y2):\n")
print(S_YY)

cat("\nS_XY (Cross-covariance X vs Y):\n")
print(S_XY)

cat("\n=== Full Covariance Matrix S ===\n")
print(S)

# 6. Verification
cat("\n=== Verification ===\n")
cat("Sum of squared deviations (Y1):", sum((data$Y1 - mean_W["Y1"])^2)/14, "\n")
cat("Should match S[1,1]:", S[1,1], "\n")
