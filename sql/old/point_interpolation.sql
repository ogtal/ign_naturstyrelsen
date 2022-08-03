with point_table as(
with temp_table as(
select
route_id,
t_start, t_end,
EXTRACT(EPOCH FROM t_end-t_start)/60 as minutes,
ST_StartPoint(geom) as start_point,
ST_EndPoint(geom) as end_point,
geom
from route_calc
where v >= 1)
select 
route_id,
st_addpoint(ST_AddPoint(ST_LineFromMultiPoint(ST_LineInterpolatePoints(geom, 1/minutes)), start_point, 0), end_point)  as new_points,
geom,
t_start,
t_end
from temp_table
where temp_table.minutes >= 2.0)
select route_id,
(ST_DumpPoints(new_points)).geom as geom,
geom as org_line,
generate_series(t_start , t_end+'1 minute'::interval, '1 minute'::interval) as t
from point_table;