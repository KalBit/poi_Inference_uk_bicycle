# fmesher is automatically installed with sdmTMB/INLA
library(fmesher)
library(spdep)
library(sf)
library(dplyr)
library(sdmTMB)


season<- "winter"

summer_file_path = "../data/jun_jul_aug_summer_dataset.csv"
winter_file_path = "../data/jan_feb_winter_dataset.csv"
autumn_file_path = "../data/sep_oct_nov_autumn_dataset.csv"
spring_file_path = "../data/april_may_spring_dataset.csv"



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

bike_subset <- data 



# Project Longitude and Latitude to UTM Zone 30N (EPSG:32630)
bike_sf <- st_as_sf(bike_subset, coords = c("longitude", "latitude"), crs = 4326)
bike_sf <- st_transform(bike_sf, crs = 32630)

# Convert metres to kilometres for the mesh
coords <- st_coordinates(bike_sf) / 1000
bike_subset$X <- coords[, "X"]
bike_subset$Y <- coords[, "Y"]







# Extract unique spatial coordinates as a matrix
loc_xy <- bike_subset %>%
  select(X, Y) %>%
  distinct() %>%
  as.matrix()

# 1. TIGHTER NON-CONVEX HULL (The Blue Line)
# Using positive numbers here sets the distance in absolute units (kilometers).
mesh_boundary <- fm_nonconvex_hull(
  loc_xy,
  convex = 0.2,  # Curves the outer corners exactly 200 meters from the outermost stations
  concave = 0.2  # Allows the boundary to dip into internal gaps up to 200 meters
)

# 2. TIGHTER MESH BUFFER (The Outer Gray Triangles)
custom_mesh <- fm_mesh_2d(
  loc = loc_xy,
  boundary = mesh_boundary,
  max.edge = c(0.5, 2.0),
  cutoff = 0.4,           # Merges stations closer than 100m to keep knots reasonable
  
  # SHRINK THE OFFSET:
  # c(inner_buffer, outer_buffer)
  # This stops the outer gray triangles from extending too far into greater London.
  offset = c(0.2, 1.0)    
)

# 3. Build and plot
mesh_2 <- make_mesh(
  bike_subset,
  xy_cols = c("X", "Y"),
  mesh = custom_mesh
)

print(paste0("Number of nodes (knots): ", mesh_2$mesh$n))
plot(mesh_2)


boundary_mesh <- readRDS("../data/boundary_mesh.rds")

boundary_mesh <- make_mesh(bike_subset, xy_cols = c("X", "Y"),mesh=boundary_mesh)
plot(boundary_mesh)

print(paste0("Number of knots: ", boundary_mesh$mesh$n))
