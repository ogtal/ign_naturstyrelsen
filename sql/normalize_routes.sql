drop table if exists normalized_points;

--- Håndtere ruter der er kortere end 1 minut og smider dem over til de isolerede punkter
--- Bemærk at horizontal accuracy er udfyldt forkert - det er for at data kan passes ind den eksisterende isolated_points tabel.
insert into isolated_points 
with short_routes as (
select
	ST_StartPoint(rc.geom) as geom,
	rc.t_start as t,
	0 as horizontal_accuracy,
	r.aid
from
	route_calc rc
	left join route r on r.route_id = rc.route_id
	where extract(EPOCH from rc.t_end-rc.t_start)/60 < 1	
) select * from short_routes





drop table if exists normalized_points;
	
create table normalized_points as 
with stationary as (
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
	route_calc rc
	where rc.v = 0 and extract(EPOCH from t_end-t_start)/60 >= 1	
), longer_routes as (
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
	route_calc rc
	where rc.v > 0 and extract(EPOCH from t_end-t_start)/60 >= 1	
) select 
route_id, 
minutes,
t_start,
t_end,
start_point as geom,
geom as org_line,
generate_series(t_start , t_end, '1 minute'::interval) as t from stationary
union
select 
route_id,
minutes,
t_start,
t_end,
(st_dump(ST_LineInterpolatePoints(geom, 1/(extract(EPOCH from t_end-t_start)/60)))).geom as geom,
geom as org_line,
generate_series(t_start + '1 minute'::interval, t_end, '1 minute'::interval) as t from longer_routes
union
select route_id, minutes, t_start, t_end, start_point as geom, geom as org_line, t_start as t from longer_routes
order by route_id, t




drop table if exists normalized_routes;

create table normalized_routes as 
with temp_table as (
select route_id, geom, t from normalized_points np 
order by t)
select route_id, st_makeline(geom), min(t) as t_start, max(t) as t_end from temp_table
group by route_id 








