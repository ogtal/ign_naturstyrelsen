--- Dette script loader henholdsvis lokationsdata og vejnet data ind i tabellerne raw_data og infrastruktur, sætter SRID'er og indeksere relevante kolonner

--- Staging tabel til lokationsdata
drop table if exists raw_staging;

create table raw_staging (
    id SERIAL PRIMARY KEY, 
    ts VARCHAR(10), 
    aid VARCHAR(36),
    aid_type VARCHAR(10),
    latitude_D VARCHAR(20), 
    longitude_D VARCHAR(20),
    horizontal_accuracy FLOAT,
    altitude FLOAT,
    altitude_accuracy FLOAT,
    manufacturer VARCHAR(256),
    model VARCHAR(256),
    UtcDateTime_str VARCHAR(20)
)

--- kopiere data ind i staging tabellen ved at kører følgende i psql terminal
--- \copy raw_staging(id, ts, aid, aid_type, latitude_D, longitude_D, horizontal_accuracy, altitude, altitude_accuracy, manufacturer, model, UtcDateTime_str) FROM 'data/NonInhab_Pickwell_2021_UTM32N.csv' DELIMITERS ';' CSV HEADER;

--- tabel til rådata
drop table if exists raw_data;

create table raw_data as
select id, 
	   to_timestamp(ts::int) as ts, 
	   aid,
	   replace(latitude_d, ',', '.')::float as latitude_d,
	   replace(longitude_d, ',', '.')::float as longitude_d,
	   horizontal_accuracy,
	   aid_type,
	   altitude,
	   altitude_accuracy,
	   manufacturer,
	   model,
	   utcdatetime_str from raw_staging rs 
	   	   	   
ALTER TABLE raw_data
ADD geom geometry(POINT);

UPDATE raw_data
SET geom = ST_Point(longitude_D, latitude_D);

-- følgende indexer er blot til at speed order by aid, ts en smule op
DROP INDEX if exists idx_raw_data_aid;
DROP INDEX if exists idx_raw_data_ts;

CREATE INDEX idx_raw_data_aid 
ON raw_data(aid);

CREATE INDEX idx_raw_data_ts 
ON raw_data(ts);

SELECT UpdateGeometrySRID('raw_data','geom',4326);
--- Følgende laver tabellen infrastruktur, som bruges til at fjerne punkter senere hen:
--- Først loades data ind i en staging tabel fra vores .shp filer:
--- i terminalen konvertere vi .shp filerne til en .sql fil
--- shp2pgsql -s 3044 -I Jernbaner.shp jernbaner_staging > jernbaner_staging.sql
--- derefter læs ind til databasen med:
--- psql -U edin -d ign_naturstyrelsen -f jernbaner_staging.sql

--- Laver infrastruktur tabel ud fra *_staging tabeller
drop table if exists infrastruktur;
  
create table infrastruktur as
select
	st_transform(js.geom, 3044) as geom
	from jernbaner_staging js
union
select	
	st_transform(vs.geom, 3044) as geom
	from vejgt6m_staging vs
union
select st_transform(ms.geom, 3044) as geom
	from motorvej_staging ms  
  
	
CREATE INDEX point_geom_3044_idx
  ON point
  USING GIST (st_transform(geom, 3044));
 
CREATE INDEX infrastruktur_geom_3044_idx
  ON infrastruktur
  USING GIST (st_transform(geom, 3044));




--- Strava data 
 
CREATE TABLE strava_ped_counts (
  edge_uid INT,
  activity_type VARCHAR(50),
  date date,
  total_trip_count INT,
  forward_trip_count INT,
  reverse_trip_count INT,
  forward_people_count INT,
  reverse_people_count INT,
  forward_commute_trip_count INT,
  reverse_commute_trip_count INT,
  forward_leisure_trip_count INT,
  reverse_leisure_trip_count INT,
  forward_morning_trip_count INT,
  reverse_morning_trip_count INT,
  forward_midday_trip_count INT,
  reverse_midday_trip_count INT,
  forward_evening_trip_count INT,
  reverse_evening_trip_count INT,
  forward_overnight_trip_count INT,
  reverse_overnight_trip_count INT,
  forward_male_people_count INT,
  reverse_male_people_count INT,
  forward_female_people_count INT,
  reverse_female_people_count INT,
  forward_unspecified_people_count INT,
  reverse_unspecified_people_count INT,
  forward_13_19_people_count INT,
  reverse_13_19_people_count INT,
  forward_20_34_people_count INT,
  reverse_20_34_people_count INT,
  forward_35_54_people_count INT,
  reverse_35_54_people_count INT,
  forward_55_64_people_count INT,
  reverse_55_64_people_count INT,
  forward_65_plus_people_count INT,
  reverse_65_plus_people_count INT,
  forward_average_speed FLOAT,
  reverse_average_speed FLOAT,
  osm_reference_id INT
  ) 

COPY strava_ped_counts(edge_uid,activity_type,date,total_trip_count,forward_trip_count,reverse_trip_count,forward_people_count,reverse_people_count,forward_commute_trip_count,reverse_commute_trip_count,forward_leisure_trip_count,reverse_leisure_trip_count,forward_morning_trip_count,reverse_morning_trip_count,forward_midday_trip_count,reverse_midday_trip_count,forward_evening_trip_count,reverse_evening_trip_count,forward_overnight_trip_count,reverse_overnight_trip_count,forward_male_people_count,reverse_male_people_count,forward_female_people_count,reverse_female_people_count,forward_unspecified_people_count,reverse_unspecified_people_count,forward_13_19_people_count,reverse_13_19_people_count,forward_20_34_people_count,reverse_20_34_people_count,forward_35_54_people_count,reverse_35_54_people_count,forward_55_64_people_count,reverse_55_64_people_count,forward_65_plus_people_count,reverse_65_plus_people_count,forward_average_speed,reverse_average_speed,osm_reference_id)
FROM '/home/edin/projects/ign_naturstyrelsen/data/strava/selected_area_daily_2019-12-01-2021-12-31_ped/e0455541f8c2b629747ee1a11d2366aefdc651973150f791db153309fceb8f7f-1662913638357.csv'
DELIMITER ','
CSV HEADER;




CREATE TABLE strava_bike_counts (
	edge_uid INT,
	activity_type VARCHAR(50),
	date date,
	total_trip_count INT,
	forward_trip_count INT,
	reverse_trip_count INT,
	forward_people_count INT,
	reverse_people_count INT,
	forward_commute_trip_count INT,
	reverse_commute_trip_count INT,
	forward_leisure_trip_count INT,
	reverse_leisure_trip_count INT,
	forward_morning_trip_count INT,
	reverse_morning_trip_count INT,
	forward_midday_trip_count INT,
	reverse_midday_trip_count INT,
	forward_evening_trip_count INT,
	reverse_evening_trip_count INT,
	forward_overnight_trip_count INT,
	reverse_overnight_trip_count INT,
	forward_male_people_count INT,
	reverse_male_people_count INT,
	forward_female_people_count INT,
	reverse_female_people_count INT,
	forward_unspecified_people_count INT,
	reverse_unspecified_people_count INT,
	forward_13_19_people_count INT,
	reverse_13_19_people_count INT,
	forward_20_34_people_count INT,
	reverse_20_34_people_count INT,
	forward_35_54_people_count INT,
	reverse_35_54_people_count INT,
	forward_55_64_people_count INT,
	reverse_55_64_people_count INT,
	forward_65_plus_people_count INT,
	reverse_65_plus_people_count INT,
	forward_average_speed FLOAT,
	reverse_average_speed FLOAT,
	osm_reference_id INT,
	ride_count INT,
	ebike_ride_count INT



  edge_uid INT,
  activity_type VARCHAR(50),
  date date,
  total_trip_count INT,
  forward_trip_count INT,
  reverse_trip_count INT,
  forward_people_count INT,
  reverse_people_count INT,
  forward_commute_trip_count INT,
  reverse_commute_trip_count INT,
  forward_leisure_trip_count INT,
  reverse_leisure_trip_count INT,
  forward_morning_trip_count INT,
  reverse_morning_trip_count INT,
  forward_midday_trip_count INT,
  reverse_midday_trip_count INT,
  forward_evening_trip_count INT,
  reverse_evening_trip_count INT,
  forward_overnight_trip_count INT,
  reverse_overnight_trip_count INT,
  forward_male_people_count INT,
  reverse_male_people_count INT,
  forward_female_people_count INT,
  reverse_female_people_count INT,
  forward_unspecified_people_count INT,
  reverse_unspecified_people_count INT,
  forward_13_19_people_count INT,
  reverse_13_19_people_count INT,
  forward_20_34_people_count INT,
  reverse_20_34_people_count INT,
  forward_35_54_people_count INT,
  reverse_35_54_people_count INT,
  forward_55_64_people_count INT,
  reverse_55_64_people_count INT,
  forward_65_plus_people_count INT,
  reverse_65_plus_people_count INT,
  forward_average_speed FLOAT,
  reverse_average_speed FLOAT,
  osm_reference_id INT
  ) 


COPY strava_ped_counts(edge_uid,activity_type,date,total_trip_count,forward_trip_count,reverse_trip_count,forward_people_count,reverse_people_count,forward_commute_trip_count,reverse_commute_trip_count,forward_leisure_trip_count,reverse_leisure_trip_count,forward_morning_trip_count,reverse_morning_trip_count,forward_midday_trip_count,reverse_midday_trip_count,forward_evening_trip_count,reverse_evening_trip_count,forward_overnight_trip_count,reverse_overnight_trip_count,forward_male_people_count,reverse_male_people_count,forward_female_people_count,reverse_female_people_count,forward_unspecified_people_count,reverse_unspecified_people_count,forward_13_19_people_count,reverse_13_19_people_count,forward_20_34_people_count,reverse_20_34_people_count,forward_35_54_people_count,reverse_35_54_people_count,forward_55_64_people_count,reverse_55_64_people_count,forward_65_plus_people_count,reverse_65_plus_people_count,forward_average_speed,reverse_average_speed,osm_reference_id,ride_count,ebike_ride_count)
FROM '/home/edin/projects/ign_naturstyrelsen/data/strava/selected_area_daily_2019-12-01-2021-12-31_ped/e0455541f8c2b629747ee1a11d2366aefdc651973150f791db153309fceb8f7f-1662913638357.csv'
DELIMITER ','
CSV HEADER;




