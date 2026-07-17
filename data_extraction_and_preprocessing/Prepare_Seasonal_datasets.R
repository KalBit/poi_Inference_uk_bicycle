library(dplyr)
library(sf)
library(spdep)
#library(car)
library(jsonlite)

set.seed(123)

# loading data
print("data loading")

jan   <- read.csv("../data/January_h.csv")
feb   <- read.csv("../data/February_h.csv")
march <- read.csv("../data/March_h.csv")
april <- read.csv("../data/April_h.csv")
may   <- read.csv("../data/May_h.csv")
june  <- read.csv("../data/June_h.csv")
july  <- read.csv("../data/July_h.csv")
aug   <- read.csv("../data/August_h.csv")
sep   <- read.csv("../data/September_h.csv")
oct   <- read.csv("../data/October_h.csv")
nov   <- read.csv("../data/November_h.csv")
dec   <- read.csv("../data/December_h.csv")

# Define problem stations (brought back from previous script step)
problem_stations_seasons <- c(300247, 300006, 1228, 1105, 1100, 1197, 200019, 1202)

# Filtering problem stations across all months
jan   <- jan   %>% filter(!start_station_number %in% problem_stations_seasons)
feb   <- feb   %>% filter(!start_station_number %in% problem_stations_seasons)
march <- march %>% filter(!start_station_number %in% problem_stations_seasons)
april <- april %>% filter(!start_station_number %in% problem_stations_seasons)
may   <- may   %>% filter(!start_station_number %in% problem_stations_seasons)
june  <- june  %>% filter(!start_station_number %in% problem_stations_seasons)
july  <- july  %>% filter(!start_station_number %in% problem_stations_seasons)
aug   <- aug   %>% filter(!start_station_number %in% problem_stations_seasons)
sep   <- sep   %>% filter(!start_station_number %in% problem_stations_seasons)
oct   <- oct   %>% filter(!start_station_number %in% problem_stations_seasons)
nov   <- nov   %>% filter(!start_station_number %in% problem_stations_seasons)
dec   <- dec   %>% filter(!start_station_number %in% problem_stations_seasons)


# Filtering using the JSON file data
imported_stations <- read_json(
  path = "closest_100_stations_metadata.json", 
  simplifyVector = TRUE
)

imported_stations <- as_tibble(imported_stations)

str(imported_stations)
head(imported_stations)

master_top_100_list <- imported_stations$start_station_number

# Seasonal aggregation
print("creating, filtering, and structuring seasonal datasets")

# Winter: Jan (1), Feb (2)
winter_dataset <- bind_rows(jan %>% mutate(month = 1), feb %>% mutate(month = 2)) %>% 
  filter(start_station_number %in% master_top_100_list) %>% relocate(count, .after = last_col())

# Spring: March (1), April (2), May (3) -> FIXED: Added March and fixed sequence
spring_dataset <- bind_rows(march %>% mutate(month = 1), april %>% mutate(month = 2), may %>% mutate(month = 3)) %>% 
  filter(start_station_number %in% master_top_100_list) %>% relocate(count, .after = last_col())

# Summer: June (1), July (2), Aug (3)
summer_dataset <- bind_rows(june %>% mutate(month = 1), july %>% mutate(month = 2), aug %>% mutate(month = 3)) %>% 
  filter(start_station_number %in% master_top_100_list) %>% relocate(count, .after = last_col())

# Autumn: Sep (1), Oct (2), Nov (3)
autumn_dataset <- bind_rows(sep %>% mutate(month = 1), oct %>% mutate(month = 2), nov %>% mutate(month = 3)) %>% 
  filter(start_station_number %in% master_top_100_list) %>% relocate(count, .after = last_col())


# Making sure all seasons have the same 100 stations selected
cat("\n", rep("=", 60), "\n", sep = "")
cat("                seasonal 100 stations integrity\n")
cat(rep("=", 60), "\n", sep = "")

winter_unique_count <- length(unique(winter_dataset$start_station_number))
spring_unique_count <- length(unique(spring_dataset$start_station_number))
summer_unique_count <- length(unique(summer_dataset$start_station_number))
autumn_unique_count <- length(unique(autumn_dataset$start_station_number))

cat("Unique stations in Winter Dataset: ", winter_unique_count, "/100\n")
cat("Unique stations in Spring Dataset: ", spring_unique_count, "/100\n")
cat("Unique stations in Summer Dataset: ", summer_unique_count, "/100\n")
cat("Unique stations in Autumn Dataset: ", autumn_unique_count, "/100\n")

if (all(c(winter_unique_count, spring_unique_count, summer_unique_count, autumn_unique_count) == 100)) {
  cat("\n all 4 seasons contain the exact same 100 stations.\n")
} else {
  cat("\n One or more seasons are missing a station drop.\n")
}
cat(rep("=", 60), "\n\n", sep = "")


## Saving the seasonal datasets to CSV
print("Saving filtered seasonal datasets to CSV")

write.csv(winter_dataset, "../data/jan_feb_winter_dataset.csv", row.names = FALSE)
write.csv(spring_dataset, "../data/mar_apr_may_spring_dataset.csv", row.names = FALSE)
write.csv(summer_dataset, "../data/jun_jul_aug_summer_dataset.csv", row.names = FALSE)
write.csv(autumn_dataset, "../data/sep_oct_nov_autumn_dataset.csv", row.names = FALSE)
