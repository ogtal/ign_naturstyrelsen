import pandas as pd
import csv

df = pd.read_csv('data/NonInhab_Pickwell_2021_UTM32N.csv', sep=';')

df = df[['timestamp', 'aid', 'latitude_D', 'longitude_D']].iloc[0:5000]

df = df.rename({'timestamp': 'ts'}, axis=1)

df.ts = pd.to_datetime(df.ts, unit='s')

df.latitude_D = df.latitude_D.str[0:8]
df.longitude_D = df.longitude_D.str[0:8]

df.latitude_D = df.latitude_D.str.replace(',', '.')
df.longitude_D = df.longitude_D.str.replace(',', '.')


df.to_csv('data/test-data.csv', sep=';', index=False, quoting=csv.QUOTE_NONE)