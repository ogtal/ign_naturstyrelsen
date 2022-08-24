--- Konstruktion og beregninger på de enkelte ruter, f.eks. antallet af punkter, rumlig afstand, temporal afstand, hastighed i km/t


--- Her laves ruterne
--- Bemærk brugen af union - det skyldes at vi fra intervals tabellen skal bruge samtlige
--- x_start værdier, men at vi ikke få de sidste punkt med på en rute. Det sidste punkt fås af 
--- det select statement der følger 'union'
drop table if exists route;

create table route as
with route_points as ( 
--- selects the first n-1 points
( select route_id, t_start as t, x_start as x, aid from intervals
       where x_cut = false and t_cut = false and aid_mismatch = false
       ) 
union 
--- selects the last point 
( SELECT DISTINCT ON (1) route_id, t_end AS t, x_end AS x, aid FROM intervals
		where x_cut = false and t_cut = false and aid_mismatch = false
       ORDER BY 1,2 desc) 
       )
select route_id, aid, st_makeline(x order by t) as geom, min(t) as t_start, max(t) as t_end from route_points 
group by route_id, aid

--- til statistik
select sum(ST_NumPoints(r.geom)) from route r

--- Laver en tabel der indeholder de resterende punkter, som ikke er en del af nogle ruter
drop table if exists isolated_points

create table isolated_points as 
select x_end as geom, t_end as t, horizontal_accuracy, aid from intervals i
where i.route_id in (
select i.route_id from intervals i 
except
select r.route_id from route r )















drop table if exists route_calc cascade;

create table route_calc as
select 
route_id, 
geom,
t_start, 
t_end,
ST_NumPoints(geom) AS n_points,
st_length(st_transform(geom, 3044)) as dx, 
(t_end - t_start) as dt,
(st_length(st_transform(geom, 3044))/(EXTRACT(epoch FROM (t_end - t_start))+1))*3.6 as v
from route

ALTER TABLE route_calc ADD PRIMARY KEY (route_id);


--- Laver en foreign key til at speede up except statement nedenunder her
ALTER TABLE route  
ADD CONSTRAINT fk_r_route_id 
FOREIGN KEY (route_id) 
REFERENCES route_calc (route_id);

