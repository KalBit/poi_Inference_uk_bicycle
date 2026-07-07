import pandas as pd


def extract_holiday_data():

    holiday_list = {
        "name": ["New Year's Day","Good Friday","Easter Monday","Early May bank holiday","Bank holiday for the coronation of King Charles III","Spring bank holiday",
        "Summer bank holiday","Christmas Day","Boxing Day"
            ],
        "date": ["02/01/2023","07/04/2023","10/04/2023","01/05/2023","08/05/2023","29/05/2023","28/08/2023","25/12/2023","26/12/2023"
            ]
        }


    holiday_data = pd.DataFrame(holiday_list)

    holiday_data.to_csv("../data/uk_holiday.csv", index=False)

    print("Holiday Data File Saved!")