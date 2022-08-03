--- Kopier relevante kolonner fra rådata filtrere trunkerede punkter fra (på 2. decimal)
drop table if exists point;

create table point as
select ts, geom, horizontal_accuracy, aid from raw_data rd 
where scale(trim(trailing '0' from substring(rd.latitude_d::text, 1, 10))::numeric) > 2
  and scale(trim(trailing '0' from substring(rd.longitude_d::text, 1, 10))::numeric) > 2
order by aid, ts;

alter table point
add column serialnumber SERIAL;

--- blot til statistik
create table truncated_points as
select ts, geom, horizontal_accuracy, aid from raw_data rd 
where scale(trim(trailing '0' from substring(rd.latitude_d::text, 1, 10))::numeric) < 3
  or scale(trim(trailing '0' from substring(rd.longitude_d::text, 1, 10))::numeric) < 3

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
	   st_distancesphere(p1.geom, p2.geom) > '10000' as x_cut,
	   (p2.ts - p1.ts) > interval '10 minute' as t_cut, 
	   p1.aid != p2.aid as aid_mismatch,
  	   sum(CASE WHEN st_distancesphere(p1.geom, p2.geom) > '10000' THEN 1
       WHEN (p2.ts - p1.ts) > interval '10 minute' THEN 1
       WHEN p1.aid != p2.aid THEN 1
       ELSE 0 END) OVER(ORDER BY p1.aid, p1.ts asc) + 1
       AS route_id
from point as p1
join point as p2 on p1.serialnumber = p2.serialnumber - 1
order by p1.aid, t_start;


drop table if exists route;

--- Her laves ruterne
--- Bemærk brugen af union - det skyldes at vi fra intervals tabellen skal bruge samtlige
--- x_start værdier, men at vi ikke få de sidste punkt med på en rute. Det sidste punkt fås af 
--- det select statement der følger 'union'
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
