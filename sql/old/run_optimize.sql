--- sætter SRI for rådata geom
SELECT UpdateGeometrySRID('raw_data','geo',4326);

--- Laver infrastruktur tabel ud fra *_staging tabeller
create table jernbaner as
select st_transform(js.geom, 4326) as geom from jernbaner_staging js  
drop table if exists jernbane
create table jernbane as
select st_union(j.geom) as geom from jernbaner j  

create table vejnet as
select st_transform(vs.geom, 4326) as geom from vejgt6m_staging vs 
drop table if exists vej
create table vej as
select st_union(v.geom) as geom from vejnet v   

create table motorveje as
select st_transform(ms.geom, 4326) as geom from motorvej_staging ms 
drop table if exists motorvej
create table motorvej as
select st_union(m.geom) as geom from motorveje m  

drop table if exists infrastruktur

create table infrastruktur as
select st_transform(st_union(veje.geom), 3044) as geom from(
select * from motorvej
union
select * from vej 
union 
select * from jernbane) as veje
--- 


--- Kopier relevante kolonner fra rådata
DROP TABLE IF EXISTS point;

--- 1.2 s -> 12 sek på fuldt datasæt
create table point as
select ts, geo as geom, horizontal_accuracy, aid from raw_data rd 
limit 1000000

alter table point 
add column serialnumber SERIAL;



--- Konstruere en 'interval' tabel bestående af to hinanden følgende punkter
--- Særligt tabellerne x_cut, t_cut og aid_mismatch er vigtige til at afgøre hvornår 
--- to punkter skal lægges sammen til et ruteinteval. Bemærk brugen af disse til udregning 
--- af route_id vha. en window function
--- Hvis x_cut indeholder værdien True, er punkterne for langt væk fra hinanden. 
--- Hvis t_cut indeholder værdien True, er der gået for lang tid mellem de to punkter er afsat
--- Hvis aid_mismatch er True kommer de to punkter fra forskellige aid'er  
drop table if exists intervals;

create table intervals as
select p1.geom as x_start, 
	   p2.geom as x_end, 
       p1.ts as t_start,
       p1.horizontal_accuracy as horizontal_accuracy,
	   p2.ts as t_end,
	   st_distancesphere(p1.geom, p2.geom) as dx, 
	   (p2.ts - p1.ts) as dt, 
	   st_distancesphere(p1.geom, p2.geom) > '10000' as x_cut,
	   (p2.ts - p1.ts) > interval '10 minute' as t_cut, 
	   p1.aid  as p1aid, 
	   p2.aid  as p2aid,
	   p1.aid  as aid,
	   p1.aid != p2.aid as aid_mismatch,
  	   sum(CASE WHEN st_distancesphere(p1.geom, p2.geom) > '10000' THEN 1
       WHEN (p2.ts - p1.ts) > interval '10 minute' THEN 1
       WHEN p1.aid != p2.aid THEN 1
       ELSE 0 END) OVER(ORDER BY p1.aid, p1.ts asc) + 1
       AS route_id
from point as p1
join point as p2 on p1.serialnumber = p2.serialnumber - 1
order by p1.aid, t_start;


--- Her laves ruterne vha. st_makeline. 
--- Bemærk brugen af union - det skyldes at vi fra interval tabellen skal bruge samtlige
--- x_start værdier, men at vi ikke få de sidste punkt med på en rute. Det får vi vha. det sidste
--- select kald. 
drop table if exists clean_route;
drop table if exists route cascade;

create table route as
select route_id, st_makeline(x order by t) as geom
from 
(select * from
--- selects the first points
( select route_id, t_start as t, x_start as x from intervals
       where x_cut = false and t_cut = false and aid_mismatch = false
       ) as first_n_points
--- selects the last point 
union ( SELECT DISTINCT ON (1) route_id, t_end AS t, x_end AS x FROM intervals 
		where x_cut = false and t_cut = false and aid_mismatch = false
       ORDER BY 1,2 desc)
       ) last_point
group by route_id 



---- MANGLER ROUTE_CALC!!!!!!!
drop table if exists route;

create table route as
select route_id, st_makeline(x order by t) as geom, min(t) as t_start, max(t) as t_end
from 
(select * from
--- selects the first points
( select route_id, t_start as t, x_start as x from intervals
       where x_cut = false and t_cut = false and aid_mismatch = false
       ) as first_n_points
--- selects the last point 
union ( SELECT DISTINCT ON (1) route_id, t_end AS t, x_end AS x FROM intervals 
		where x_cut = false and t_cut = false and aid_mismatch = false
       ORDER BY 1,2 desc)
       ) last_point
group by route_id 

drop table if exists route_calc;

create table route_calc as
select 
route_id, 
geom,
t_start, 
t_end,
st_length(st_transform(geom, 3044)) as dx, 
(t_end - t_start) as dt,
(st_length(st_transform(geom, 3044))/(EXTRACT(epoch FROM (t_end - t_start))+1))*3.6 as v
from route
----


--- Beholder kun rute der har en gennemsnitshastighed på < 45 km/t og en afstand på > 50 fra veje m.v.

DROP INDEX route_calc_geom_idx;

DROP INDEX route_calc_geom_3044_idx;

DROP INDEX infrastruktur_geom_idx;

DROP INDEX infrastruktur_geom_3044_idx;

drop table if exists clean_routes


create table nearby_infra as
select rc.*, st_distance(st_transform(rc.geom, 3044), st_transform(i.geom, 3044)) as dist from route_calc rc, infrastruktur i 
where st_dwithin(st_transform(rc.geom, 3044), st_transform(i.geom, 3044), 50)

create table far_from_infra as 
select rc.*, st_distance(st_transform(rc.geom, 3044), st_transform(i.geom, 3044)) as dist from route_calc rc, infrastruktur i 
where rc.route_id not in (
select ni.route_id from nearby_infra ni 
)

CREATE INDEX route_calc_geom_3044_idx
  ON route_calc
  USING GIST (st_transform(geom, 3044));
 
CREATE INDEX infrastruktur_geom_3044_idx
  ON infrastruktur
  USING GIST (st_transform(geom, 3044));

drop table if exists clean_routes;

drop table if exists dirty_routes;

drop table if exists stationary_routes;

drop table if exists missing_routes;


--- find ud af hvor mange route der er i henholdsvis: stationary_, clean_, dirty_ etc. 

select count(*) from route

select count(*) from ( 
select r.route_id from route r 
intersect
select sr.route_id from stationary_routes sr 
) as _

select r.route_id from route r



select r.route_id from route r
minus 


with temp_table as 
select * from temp_table
union


ALTER TABLE route ADD CONSTRAINT pk_route_id PRIMARY KEY(route_id);

ALTER TABLE clean_routes 
ADD CONSTRAINT fk_route_id 
FOREIGN KEY (route_id) 
REFERENCES route (route_id);

select * from clean_routes cr 
where route_id in (
select route_id from route)

select * from route r 
where r.route_id not in (
select cr.route_id from clean_routes cr 
)


select route_id from clean_routes cr 
union (select route_id from dirty_routes)



select r.* from route r
join dirty_routes dr on dr.route_id = r.route_id 
join clean_routes cr on cr.route_id = r.route_id 
where dr.route_id is null or cr.route_id is null


select r.* from route r 
where r.route_id not in 
(select cr. route_id from clean_routes cr)



select * from ( 
(select cr. route_id from clean_routes cr) as a union select dr.route_id from dirty_routes dr
) c


--- normalisere ruter i tid. 


select * from route_calc

create table normalized_points as
with point_table as (  
with temp_table as (
select
	route_id,
	t_start,
	t_end,
	extract(EPOCH from t_end-t_start)/ 60 as minutes,
	ST_StartPoint(geom) as start_point,
	ST_EndPoint(geom) as end_point,
	geom
from
	route_calc rc
	where v > 1
) select
	route_id,
	st_addpoint(ST_AddPoint(ST_LineFromMultiPoint(ST_LineInterpolatePoints(geom, 1 / minutes)), start_point, 0), end_point) as interpolated_points,
	geom,
	t_start,
	t_end
from temp_table
where temp_table.minutes > 2)
select route_id, (ST_DumpPoints(interpolated_points)).geom as geom,
geom as org_line,
generate_series(t_start , t_end+'1 minute'::interval, '1 minute'::interval) as t
from point_table;
	




--- Lav heat maps med henholdsvis punkter, ruter etc. 

--- gris til heatmaps:



DROP FUNCTION makegrid_2d(geometry,integer,integer);

CREATE OR REPLACE FUNCTION public.makegrid_2d (
  bound_polygon public.geometry,
  width_step integer,
  height_step integer
)
RETURNS public.geometry AS
$body$
DECLARE
  Xmin DOUBLE PRECISION;
  Xmax DOUBLE PRECISION;
  Ymax DOUBLE PRECISION;
  X DOUBLE PRECISION;
  Y DOUBLE PRECISION;
  NextX DOUBLE PRECISION;
  NextY DOUBLE PRECISION;
  CPoint public.geometry;
  sectors public.geometry[];
  i INTEGER;
  SRID INTEGER;
BEGIN
  Xmin := ST_XMin(bound_polygon);
  Xmax := ST_XMax(bound_polygon);
  Ymax := ST_YMax(bound_polygon);
  SRID := ST_SRID(bound_polygon);

  Y := ST_YMin(bound_polygon); --current sector's corner coordinate
  i := -1;
  <<yloop>>
  LOOP
    IF (Y > Ymax) THEN  
        EXIT;
    END IF;

    X := Xmin;
    <<xloop>>
    LOOP
      IF (X > Xmax) THEN
          EXIT;
      END IF;

      CPoint := ST_SetSRID(ST_MakePoint(X, Y), SRID);
      NextX := ST_X(ST_Project(CPoint, $2, radians(90))::geometry);
      NextY := ST_Y(ST_Project(CPoint, $3, radians(0))::geometry);

      i := i + 1;
      sectors[i] := ST_MakeEnvelope(X, Y, NextX, NextY, SRID);

      X := NextX;
    END LOOP xloop;
    CPoint := ST_SetSRID(ST_MakePoint(X, Y), SRID);
    NextY := ST_Y(ST_Project(CPoint, $3, radians(0))::geometry);
    Y := NextY;
  END LOOP yloop;

  RETURN ST_Collect(sectors);
END;
$body$
LANGUAGE 'plpgsql';

drop table if exists grid_100;

create table grid_100 as (
  SELECT (
    ST_Dump(
      makegrid_2d(
  ST_GeomFromText(
          'Polygon((12.1880474 55.827127,12.423814 55.827127,12.423814 56.077009,12.1880474 56.077009,12.1880474 55.827127))',
          4326
        ),
         100, -- width step in meters
         100  -- height step in meters
       ) 
    )
  ) .geom AS cell
);


drop table if exists square_route;

create table square_route as(
SELECT cr.route_id, grid.cell
    FROM
    clean_routes cr
    Right JOIN
    grid_100 AS grid
    ON ST_Intersects(cr.geom, grid.cell)
)

drop table if exists square_route_count;

create table square_route_count as (
select count( distinct route_id) as route_count, cell as geom
from square_route 
group by cell);



select cr. route_id from clean_routes cr

select dr.route_id from dirty_routes dr

SELECT name
FROM table2
WHERE name NOT IN
    (SELECT name 
     FROM table1)



SELECT t1.name
FROM table1 t1
LEFT JOIN table2 t2 ON t2.name = t1.name
WHERE t2.name IS NULL

select * from cool_squares cs 

select cs.cell, count(*) from route_calc rc, cool_squares cs 
where ST_Intersects(cs.cell, rc.geom) and rc.v < 45 and 
group by cs.cell


select * from route_test_dist
where dist < 100

select route_id, count(*) from intervals i 
group by route_id 
having count(*) > 1

select * from intervals i 
where x_cut = false and t_cut = false and aid_mismatch = false


create table route_test_2 as
select rd.aid, st_makeline(rd.geo)  as geom 
from raw_data rd 
group by rd.aid


select st_makeline(rd.geo) from raw_data rd 
where rd.aid = '003cc9b0-f1fe-4780-a12d-6b862b5de89d'

select * from route_test_2


drop table if exists route_test


create table route_test as
select i.route_id, st_makeline(i.x_end)  as geom 
from intervals i 
group by i.route_id




select * from intervals i 
where i.route_id = 155

select * from route_test rt 

SELECT * FROM "public"."route_test" WHERE route_id = 310


SELECT gps.track_id, ST_MakeLine(gps.geom ORDER BY gps_time) As geom
	FROM gps_points As gps
	GROUP BY track_id;
where x_cut = false and t_cut = false and aid_mismatch = false
order by route_id, t_start;


alter table intervals 
add column iid SERIAL;

ALTER TABLE intervals
ADD constraint intervals_pk PRIMARY KEY (iid);


drop table if exists intervals_calc;



drop table if exists routes;

create table routes as 
select 
route_id, sum(dx) as distance, sum(dt) as time,
AVG(speed) as speed, count(x_start)+1 as n_points
from point_calc
group by route_id;



select * from route_calc rc 
left join route r 


select route_id, aid from intervals i
where x_cut = false and t_cut = false and aid_mismatch = false
group by route_id
limit 10



SELECT DISTINCT ON (1) route_id, aid FROM intervals 
where x_cut = false and t_cut = false and aid_mismatch = false
limit 10
		