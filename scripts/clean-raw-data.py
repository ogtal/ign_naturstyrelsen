import pandas as pd
import csv

df = pd.read_csv('data/NonInhab_Pickwell_2021_UTM32N.csv', sep=';')

df.latitude_D = df.latitude_D.str.replace(',', '.')
df.longitude_D = df.longitude_D.str.replace(',', '.')

df.timestamp = pd.to_datetime(df.timestamp, unit='s')

df.to_csv('data/ready-to-injest.csv', sep=';', index=False, quoting=csv.QUOTE_NONE)

# copy data into PostgreSQL:
# \copy raw_data(point_id, ts, aid, aid_type, latitude_D, longitude_D, horizontal_accuracy, altitude, altitude_accuracy, manufacturer, model, UtcDateTime_str) FROM 'data/ready-to-injest.csv' DELIMITERS ';' CSV HEADER;

# population geo:
# UPDATE raw_data
# SET geo = ST_Point(longitude_D, latitude_D);