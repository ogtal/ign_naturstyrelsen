--- Staging tabel 
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
DROP INDEX idx_raw_data_aid;
drop index idx_raw_data_ts;

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
	st_union(infra.geom) as geom
from
	(
	select
		st_union(st_transform(js.geom,
		4326)) as geom
	from
		jernbaner_staging js
union
	select
		st_union(st_transform(vs.geom,
		4326)) as geom
	from
		vejgt6m_staging vs
union
	select
		st_transform(ms.geom,
		4326) as geom
	from
		motorvej_staging ms
) as infra







