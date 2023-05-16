--- Skalere strava ruterne i nærheden af en tællestation
@set dx = 100

--- Tællestationernes lokationer:
drop table if exists station_points

CREATE TABLE station_points (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    geom geometry(POINT, 4326)
);
   
INSERT INTO station_points (name, geom)
VALUES 
    ('onehour_32ed06', ST_SetSRID(ST_MakePoint(12.3109056, 55.9641755), 4326)),
    ('onehour_302775', ST_SetSRID(ST_MakePoint(12.35565572, 55.99425445), 4326)),
    ('onehour_30289c', ST_SetSRID(ST_MakePoint(12.34694014, 55.95622582), 4326)),
    ('onehour_355853', ST_SetSRID(ST_MakePoint(12.30452845, 56.00047168), 4326)),
    ('onehour_3812a4', ST_SetSRID(ST_MakePoint(12.222292, 56.022677), 4326)),
    ('eco_egehjorten', ST_SetSRID(ST_MakePoint(12.356097, 55.958153), 4326)),
    ('eco_praestevang', ST_SetSRID(ST_MakePoint(12.324700, 55.919976), 4326));

select * from station_points
   
-- Laver cirkler rundt om tællestationerne
drop table if exists station_circles; 

create table station_circles as
SELECT name,
       ST_Buffer(ST_Transform(ST_SetSRID(sp.geom, 4326), 3044), 100) as circle_100,
	   ST_Buffer(ST_Transform(ST_SetSRID(sp.geom, 4326), 3044), 250) as circle_250,
	   ST_Buffer(ST_Transform(ST_SetSRID(sp.geom, 4326), 3044), 500) as circle_500,
	   ST_Buffer(ST_Transform(ST_SetSRID(sp.geom, 4326), 3044), 1000) as circle_1000,
	   sp.geom as centre
FROM station_points sp

--- Smid strava data ind i circles
drop table if exists strava_station_circle_${dx}

create table strava_station_circle_${dx} as 
with grid as(
	select circle_${dx} as geom, name from station_circles 
	)
SELECT 
	   sr.date,
	   grid.name,
       ---sr.total_trip_count, 
       ---ST_length(st_intersection(st_transform(sr.geom, 3044), grid.geom)) / ST_length(st_transform(sr.geom, 3044)) as frac_inside, 
       ROUND(sr.total_trip_count * ST_length(st_intersection(st_transform(sr.geom, 3044), grid.geom)) / ST_length(st_transform(sr.geom, 3044))) as scaled_trip_count
	   ---grid.geom as grid_geom, 
	   ---sr.geom as strava_geom, 
	   ---st_intersection(st_transform(sr.geom, 3044), grid.geom) as geom_intersect 
	   FROM strava_ride as sr, grid
WHERE ST_intersects(st_transform(sr.geom, 3044), grid.geom)
UNION
SELECT 
	   sp.date,
   	   grid.name,
       ---sr.total_trip_count, 
       ---ST_length(st_intersection(st_transform(sr.geom, 3044), grid.geom)) / ST_length(st_transform(sr.geom, 3044)) as frac_inside, 
       ROUND(sp.total_trip_count * ST_length(st_intersection(st_transform(sp.geom, 3044), grid.geom)) / ST_length(st_transform(sp.geom, 3044))) as scaled_trip_count
	   ---grid.geom as grid_geom, 
	   ---sr.geom as strava_geom, 
	   ---st_intersection(st_transform(sr.geom, 3044), grid.geom) as geom_intersect 
	   FROM strava_ped as sp, grid
WHERE ST_intersects(st_transform(sp.geom, 3044), grid.geom)



