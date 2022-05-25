from sqlalchemy import create_engine
from geoalchemy2 import Geometry
import geopandas
import psycopg2
import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)
import pandas as pd
import numpy as np
import time
from sklearn.cluster import AgglomerativeClustering
#%%
def get_point_sql(aid, manufacturer, model):
    base_point_sql = """SELECT ts, latitude_d, longitude_d, horizontal_accuracy, geo
    FROM raw_data WHERE aid = '{0}' AND manufacturer {1} AND model {2}"""
    if len(manufacturer) > 0:
        manufacturer_str = f"= '{manufacturer}'"
    else:
        manufacturer_str = 'IS NULL'
    if len(model) > 0:
        model_str = f"= '{model}'"
    else:
        model_str = 'IS NULL'
    return base_point_sql.format(aid, manufacturer_str, model_str)

def convert_geo_projection(geo_df):
    #set initial global crs
    geo_df = geo_df.set_crs(crs='EPSG:4326')
    #covert to danish
    geo_df = geo_df.to_crs('EPSG:23032')
    geo_df = geo_df.set_crs('EPSG:23032')
    return geo_df

def get_point_clusters(geo_df, time_column='ts', max_point_time_difference = 600):
    #convert timestamps to unix
    unix_ts_array = np.array([geo_df[time_column].astype(np.int64) // 10 ** 9]).T
    #perform agglomerative clustering
    time_clustering = AgglomerativeClustering(n_clusters = None, distance_threshold=max_point_time_difference, linkage = 'single').fit(unix_ts_array)
    time_cluster_labels = time_clustering.labels_
    n_time_clusters = time_clustering.n_clusters_
    return time_cluster_labels, n_time_clusters

def persist_routes(route_dict_list, con):
     #create route dataframe
    route_df = pd.DataFrame(route_dict_list)
    #add routes to database
    route_df.to_sql(name='route', con = con, if_exists= 'append', index=False)
    

def persist_points(point_df_list, con, crs = 'epsg:4326'):
    #create points dataframe
    points_df = geopandas.GeoDataFrame(pd.concat(points_df_list, ignore_index=True))
    #set crs and rename lon lat columns
    points_df = points_df.set_crs(crs)
    points_df = points_df.rename(columns={'latitude_d' : 'latitude', 'longitude_d' : 'longitude'})
    ##add points to database
    points_df.to_postgis(name='point_2d', con = con, if_exists= 'append', index=False)

#%%
db = 'ign_naturstyrelsen'
user = 'edin'
password = ''
host = '10.0.1.30'

connection_string = f'postgresql+psycopg2://{user}:{password}@{host}/{db}'

con = create_engine(connection_string)


next_id_sql = "select MAX(route_id) FROM route"
try:
    route_id = con.execute(next_id_sql).first()[0]+1
except TypeError:
    route_id = 0

batch_size = 100

device_sql = "SELECT * FROM device WHERE device.device_id NOT IN (select device_id FROM route) limit 20000"
device_df = pd.read_sql(device_sql, con)
device_df.fillna("", inplace=True)
#%%
route_dict_list = []
points_df_list = []
crs = {'init': 'epsg:4326'}

device_count = 0
tic = time.time()
for _, row in device_df.iterrows():
    
    #get device points¨
    device_points_sql = get_point_sql(row['aid'], row['manufacturer'], row['model'])
    device_points = geopandas.GeoDataFrame.from_postgis(device_points_sql, con, geom_col= 'geo')
    # add route id column
    device_points['route_id'] = ''
    #perfom time based clustering 
    if len(device_points) > 1:
        time_cluster_labels, n_time_clusters = get_point_clusters(device_points)
    else:
        time_cluster_labels = np.array([0])
        n_time_clusters = 1
    for c in range(n_time_clusters):
            cluster_index = time_cluster_labels == c
            cluster_points = device_points.loc[cluster_index]
            device_points
            n_points = len(cluster_points)
            route_dict = {'route_id' : route_id, 'device_id' : row['device_id'], 'n_points' : n_points,
                          'start_ts' : min(cluster_points['ts']), 'end_ts' : max(cluster_points['ts'])}
            route_dict_list.append(route_dict)
            device_points.loc[cluster_index, 'route_id'] = route_id
            route_id += 1
    
    points_df_list.append(device_points)
    device_count += 1
    #persist in batches of 100 devices
    if device_count >= 1000:
        print('persisting chunk')
        persist_routes(route_dict_list, con)
        print('routes persisted')
        persist_points(points_df_list, con)
        print('points persisted')
        #reset control variables
        route_dict_list = []
        points_df_list = []
        device_count = 0
        print(int(time.time()-tic), 'seconds elapsed')
        tic = time.time()

#persist remaining data
if device_count > 0:
    print('Peristing data for remaining {0} devices'.format(device_count))
    persist_routes(route_dict_list, con)
    persist_points(points_df_list, con)
con.dispose()