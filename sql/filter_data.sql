--- Dette script filtrere trunkerede punkter fra, punkter der er nær veje/jernbaner og laver en tabel til punkter der ikke er en del af en rute
drop table if exists point;

create table point as
select id, ts, geom, horizontal_accuracy, aid from raw_data rd 
where scale(trim(trailing '0' from substring(rd.latitude_d::text, 1, 10))::numeric) > 2
  and scale(trim(trailing '0' from substring(rd.longitude_d::text, 1, 10))::numeric) > 2
order by aid, ts;


--- blot til statistik
drop table if exists truncated_points;

create table truncated_points as
select id, ts, geom, horizontal_accuracy, aid from raw_data rd 
where scale(trim(trailing '0' from substring(rd.latitude_d::text, 1, 10))::numeric) < 3
  or scale(trim(trailing '0' from substring(rd.longitude_d::text, 1, 10))::numeric) < 3



drop table if exists ignore_these_points;

create table ignore_these_points as
select p.id, st_distance(st_transform(p.geom, 3044), i.geom) as dist from point p, infrastruktur i
where st_dwithin(st_transform(p.geom, 3044), i.geom, 50)

--- Det tog 1 minut og 24 s

select count(*), count(distinct id) from ignore_these_points 

select count(*) from rec_point

drop table if exists rec_point

create table rec_point as
select * from point 
where id in (
select id from point
except
select distinct id from ignore_these_points)
order by aid, ts;

alter table rec_point
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
	   p2.aid  as p2aid,
	   p1.aid  as aid,
	   st_distancesphere(p1.geom, p2.geom) > '3000' as x_cut,
	   (p2.ts - p1.ts) > interval '30 minute' as t_cut, 
	   p1.aid != p2.aid as aid_mismatch,
  	   sum(CASE WHEN st_distancesphere(p1.geom, p2.geom) > '3000' THEN 1
       WHEN (p2.ts - p1.ts) > interval '30 minute' THEN 1
       WHEN p1.aid != p2.aid THEN 1
       ELSE 0 END) OVER(ORDER BY p1.aid, p1.ts asc) + 1
       AS route_id
from rec_point as p1
join rec_point as p2 on p1.serialnumber = p2.serialnumber - 1
order by p1.aid, t_start;



