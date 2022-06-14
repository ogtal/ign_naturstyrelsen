from sqlalchemy import create_engine
from geoalchemy2 import Geometry
import geopandas
import psycopg2
#%%
db = 'ign_naturstyrelsen'
user = 'edin'
password = ''
host = '10.0.1.30'

connection_string = f'postgresql+psycopg2://{user}:{password}@{host}/{db}'

con = create_engine(connection_string)
#%%
sql = "SELECT * FROM square_route_count;"
gdf = geopandas.read_postgis(sql, con)
#%%
gdf.to_file("route_count.shp")