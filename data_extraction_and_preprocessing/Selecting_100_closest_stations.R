#loading libraries


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


# cleaning the problematic stations

problem_stations_seasons <- c(300247, 300006, 1228, 1105, 1100, 1197, 200019, 1202)

print("Filtering problem stations across all months")
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


# computing 100 closest stations from the chosen central point

print("building master station list and computing spatial distances")

all_months_stations <- bind_rows(
  jan, feb, march, april, may, june, july, aug, sep, oct, nov, dec
) %>% 
  select(start_station_number, longitude, latitude) %>% 
  distinct(start_station_number, .keep_all = TRUE)

target_lon         <- -0.09844180843941625
target_lat         <- 51.51370562455308
number_of_stations <- 100

target_sf <- st_as_sf(
  data.frame(longitude = target_lon, latitude = target_lat),
  coords = c("longitude", "latitude"),
  crs = 4326
)
stations_sf <- st_as_sf(
  all_months_stations,
  coords = c("longitude", "latitude"),
  crs = 4326,
  remove = FALSE   
)

top_100_stations_geo <- stations_sf %>%
  mutate(dist_to_target = as.numeric(st_distance(geometry, target_sf))) %>%
  arrange(dist_to_target) %>%
  slice(1:number_of_stations) %>%
  st_drop_geometry() %>% 
  select(start_station_number, longitude, latitude, dist_to_target)

# Save the 100 stations with coordinates
write_json(
  top_100_stations_geo, 
  path = "../data/closest_100_stations_metadata.json", 
  dataframe = "rows", 
  pretty = TRUE 
)

print("Saved successfully as JSON")
