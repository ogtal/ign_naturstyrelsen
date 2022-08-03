drop table if exists normalized_points;

--- BEMÆRK BUG I KODEN HERUNDER:
--- Punkterne bliver ikke afsat i korrekt rækkefølge langs ruten. 
---
-- this statement normalizes the routes and results in a point table 
-- this table is created from the routes in the table far_from_infra. 
-- Each route is normalized such the we get one point per minute. 
-- 
-- The routes are split into two temporary tables: 
-- short_routes - contains the routes that are stationary or have a duration < 1 minute
-- These routes are reduced to their start_point which is repeated every minutes for the duration of the route.
--
-- long_routes - contains the routes that contain movement and have a duration > 1 minute. 
-- Pointes are placed along these routes every minute using ST_LineInterpolatePoints 
-- these are placed into interpolated_long_routes
--
-- The final select statements query the temporary tables and generates the appropriate time series
create table normalized_points as
-- movement and >= 1 minute
with 
short_or_stationary_routes as ( 
select
	route_id,
	t_start,
	t_end,
	extract(EPOCH from t_end-t_start)/60 as minutes,
	ST_StartPoint(geom) as start_point,
	v,
	geom
from
	recreational rc
	where rc.v = 0 or extract(EPOCH from t_end-t_start)/60 < 1
), 
interpolated_long_routes as ( 
with long_routes as(
select
	route_id,
	t_start,
	t_end,
	extract(EPOCH from t_end-t_start)/60 as minutes,
	ST_StartPoint(geom) as start_point,
	ST_EndPoint(geom) as end_point,
	v,
	geom
from
	recreational rc
	where rc.v > 0 and extract(EPOCH from t_end-t_start)/60 >= 1
)
select 
	route_id,
	start_point,
	end_point,
	ST_MULTI(ST_UNION(start_point, ST_LineInterpolatePoints(geom, 1/minutes))) as interpolated_points,
	minutes,
	geom,
	t_start,
	t_end
from long_routes
)
select 
route_id, 
minutes,
start_point as geom,
geom as org_line,
generate_series(t_start , t_end, '1 minute'::interval) as t
from short_or_stationary_routes
union
select 
route_id, 
minutes,
(ST_DumpPoints(interpolated_points)).geom as geom,
geom as org_line,
generate_series(t_start , t_end, '1 minute'::interval) as t
from interpolated_long_routes
-- 15 sekunder

drop table if exists normalized_routes;

create table normalized_routes as 
with temp_table as (
select route_id, geom, t from normalized_points np 
where np.minutes >= 1
order by route_id, t)
select route_id, st_makeline(geom), min(t) as t_start, max(t) as t_end from temp_table
group by route_id 


---- HERUNDER EKSEMPLER PÅ UNDERLIG OPFØRSEL


select * from normalized_points np 
where np.route_id = 1015111

select * from recreational r  
where r.route_id = 1015111



select * from normalized_routes nr 
where nr.route_id = 242172


select route_id, geom from recreational r 
where r.route_id = 242172
union
select route_id, x_start as geom from intervals i 
where i.route_id = 242172






