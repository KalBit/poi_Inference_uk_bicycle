import requests
import pandas as pd


def extract_station_location_data():

    url = 'https://api.tfl.gov.uk/BikePoint/'

    def fetch_tfl_bike_points(url):
        """
        Fetches the JSON data containing all TFL Bike Points from the specified URL.
        """
        try:
            response = requests.get(url)
            response.raise_for_status()
            bike_points_data = response.json()
            print("Successfully loaded TFL Bike Point data.")
            return bike_points_data

        except requests.exceptions.RequestException as e:
            print(f"Error fetching data: {e}")
            return None

    data = fetch_tfl_bike_points(url)

    name_list = []
    id_list = []
    lon_list = []
    lat_list = []
        
        
        
    for i in range(len(data)):
        name_list.append(data[i]["commonName"])
        id_list.append(data[i]["additionalProperties"][0]["value"])
        lon_list.append(data[i]["lon"])
        lat_list.append(data[i]["lat"])
        

    stations_with_coords = pd.DataFrame(
                    {"start_station_name": name_list,
                     "start_station_number":id_list,
                    "latitude" : lat_list,
                    "longitude" : lon_list}
                    )


    stations_with_coords.to_csv("../data/station_location.csv",index=False)  
    
    print("Bike Station Location Data Saved! ")
    
extract_station_location_data()