# script to create full dataset for January 2023

# load necessary libraries
library(tidyverse)
library(readr)
library(janitor)
library(lubridate)
library(ggplot2)

jan01=read_csv("350JourneyDataExtract26Dec2022-01Jan2023.csv")
head(jan01)
View(jan01)
str(jan01)

data[format(data$date_column, "%Y") == "2023", ]
#filter(format(jan01$`Start date`,"%Y")=="2023"

data1= jan01 %>% filter(format(jan01$`Start date`,"%Y")=="2023")
View(data1)

data2=read_csv("351JourneyDataExtract02Jan2023-08Jan2023.csv")
data3=read_csv("352JourneyDataExtract09Jan2023-15Jan2023.csv")
data4=read_csv("353JourneyDataExtract16Jan2023-22Jan2023.csv")
data5=read_csv("354JourneyDataExtract23Jan2023-29Jan2023.csv")

jan30_31=read_csv("355JourneyDataExtract30Jan2023-05Feb2023.csv")
view(jan30_31)
str(jan30_31)
format(jan01$`Start date`,"%m")=="01"
attach(jan30_31)
data6=jan30_31 %>% filter(format(`Start date`,"%m")=="01")
View(data6)

155446-107647

view(data1)
view(data2)
view(data3)
view(data4)
view(data5)
view(data6)

attach(data1)
attach(data2)
attach(data3)
attach(data4)
attach(data5)
attach(data6)
data1=data1 %>% arrange(`Start date`)
view(data1)
data2=data2 %>% arrange(`Start date`)
view(data2)
data3=data3 %>% arrange(`Start date`)
view(data3)
data4=data4 %>% arrange(`Start date`)
view(data4)
data5=data5 %>% arrange(`Start date`)
view(data5)
data6=data6 %>% arrange(`Start date`)
view(data6)

m1=merge(data1,data2,all = TRUE)
m2=merge(m1,data3,all = TRUE)
m3=merge(m2,data4,all = TRUE)
m4=merge(m3,data5,all = TRUE)

jan_full=merge(m4,data6,all = TRUE)
view(jan_full)

# converts names to a consistent snake_case format (e.g., "Start Date" becomes `start_date`)
jan_full <- jan_full %>% clean_names()

# renamed columns
names(jan_full)[1] <- "rentalID"
names(jan_full)[8] <- "BikeID"

# convert ID columns to character strings
jan_full$rentalID <- as.character(jan_full$rentalID)
jan_full$BikeID <- as.character(jan_full$BikeID)

# separate columns for start and end dates and times
jan_full <- jan_full %>%
  mutate(
    s_date = as.Date(start_date),
    s_time = format(start_date, "%H:%M:%S"),
    e_date = as.Date(end_date),
    e_time = format(end_date, "%H:%M:%S")
  )

# convert ride duration from milliseconds to minutes
jan_full <- jan_full %>%
  mutate(total_duration_mins = total_duration_ms / 60000)

# select the final set of columns
final_columns <- c(
  "rentalID", "s_date", "s_time", "start_station_number", "start_station",
  "e_date", "e_time", "end_station_number", "end_station", "BikeID",
  "bike_model", "total_duration_mins"
)
jan_full <- jan_full %>% select(all_of(final_columns))

# saved
write_csv(jan_full, "data/january_full.csv")