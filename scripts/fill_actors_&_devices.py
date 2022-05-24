from sqlalchemy import create_engine
import geopandas
import psycopg2
import pandas as pd
#%%
db = 'ign_naturstyrelsen'
user = 'edin'
password = ''
host = '10.0.1.30'

connection_string = f'postgresql+psycopg2://{user}:{password}@{host}/{db}'

con = create_engine(connection_string)

unique_devices = 'SELECT DISTINCT aid, aid_type, manufacturer, model FROM raw_data'

device_df = pd.read_sql(unique_devices, con)
#%%
#insert individual aids in actor table
actor_df = pd.DataFrame(device_df['aid'].unique())
actor_df.columns = ['aid']
actor_df.to_sql(name='actor', con = con, if_exists= 'append', index=False)
#%%
device_df.iloc[100:].to_sql(name='device', con = con, if_exists= 'append', index=False)