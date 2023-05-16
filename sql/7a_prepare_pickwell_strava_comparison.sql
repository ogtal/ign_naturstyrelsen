--- Laver tyve tilfældige punkter, hvor vi kan sammenligne strava og pickwell data:

drop table if exists rand_grid_1000

create table rand_grid_1000 as
select geom, st_centroid(geom) as centre from grid_1000
where count < 200000
order by random() 
limit 20

select centre, ST_BUFFER() from rand_grid_1000 

select 

create table rand_grid as
SELECT st_envelope(ST_Buffer(ST_Transform(ST_SetSRID(rg.centre, 3044), 3044), 100)) as square_100,
	   st_envelope(ST_Buffer(ST_Transform(ST_SetSRID(rg.centre, 3044), 3044), 250)) as square_250,
	   st_envelope(ST_Buffer(ST_Transform(ST_SetSRID(rg.centre, 3044), 3044), 500)) as square_500,
	   centre, geom as square_1000
FROM rand_grid_1000 rg

--- Tæller og skalere antallet af strava ruter

@set dx = 100

create table strava_rand_grid_${dx} as 
with grid as(
	select square_${dx} as geom from rand_grid 
	)
SELECT 
	   sr.date,
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
       ---sr.total_trip_count, 
       ---ST_length(st_intersection(st_transform(sr.geom, 3044), grid.geom)) / ST_length(st_transform(sr.geom, 3044)) as frac_inside, 
       ROUND(sp.total_trip_count * ST_length(st_intersection(st_transform(sp.geom, 3044), grid.geom)) / ST_length(st_transform(sp.geom, 3044))) as scaled_trip_count
	   ---grid.geom as grid_geom, 
	   ---sr.geom as strava_geom, 
	   ---st_intersection(st_transform(sr.geom, 3044), grid.geom) as geom_intersect 
	   FROM strava_ped as sp, grid
WHERE ST_intersects(st_transform(sp.geom, 3044), grid.geom)



--- Pickwell counts within a square - til at debugge
create table pickwell_rand_grid_${dx} as 
with grid as(
	select square_${dx} as geom from rand_grid 
	), normalized_and_single_points as (
select date_trunc('day', t) as ts, geom from normalized_points np
union 
select date_trunc('day', ts) as ts, geom from point p
where p.aid in (
select aid from (   
select aid, count(*) as c from point 
group by aid) x
where c = 1)
) select ts, count(*) as pts from normalized_and_single_points, grid
WHERE ST_Within(st_transform(normalized_and_single_points.geom, 3044), grid.geom)
group by grid.geom, ts






