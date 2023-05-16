--- Konstruktion og beregninger på de enkelte ruter, f.eks. antallet af punkter, rumlig afstand, temporal afstand, hastighed i km/t


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


--- Laver en foreign key til at speede up
ALTER TABLE route  
ADD CONSTRAINT fk_r_route_id 
FOREIGN KEY (route_id) 
REFERENCES route_calc (route_id);

