--- Beregninger på de enkelte ruter, f.eks. antallet af punkter, rumlig afstand, temporal afstand, hastighed i km/t
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

--- Laver indexer til at speed op st_dwithin senere her

DROP INDEX route_calc_geom_3044_idx;

DROP INDEX infrastruktur_geom_3044_idx;

CREATE INDEX route_calc_geom_3044_idx
  ON route_calc
  USING GIST (st_transform(geom, 3044));
 
CREATE INDEX infrastruktur_geom_3044_idx
  ON infrastruktur
  USING GIST (st_transform(geom, 3044));

--- Laver tabel der indeholder de ruter vi ikke er interesseret i. De er indenfor 50 meter fra vej m.v. eller har en hastighed > 45 km/t 
drop table if exists nonrecreational;

create table nonrecreational as 
select rc.*, st_distance(st_transform(rc.geom, 3044), st_transform(i.geom, 3044)) as dist from route_calc rc, infrastruktur i 
where st_dwithin(st_transform(rc.geom, 3044), st_transform(i.geom, 3044), 50)

--- Laver en foreign key til at speede up except statement nedenunder her
ALTER TABLE nonrecreational  
ADD CONSTRAINT fk_nr_r_route_id 
FOREIGN KEY (route_id) 
REFERENCES route_calc (route_id);

--- Laver en tabel med de ruter vi 
drop table if exists recreational;


create table recreational as 
select rc.*, st_distance(st_transform(rc.geom, 3044), st_transform(i.geom, 3044)) as dist from route_calc rc, infrastruktur i 
where rc.route_id in (
select rc2.route_id from route_calc rc2  
except 
select n.route_id from nonrecreational n 
) and rc.v < 45;


-- 24 minutter


