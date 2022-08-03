
--- Lav heat maps med henholdsvis punkter, ruter etc. 





SELECT COUNT(*), squares.geom
    FROM
    normalized_points AS pts
    INNER JOIN
    ST_SquareGrid(
        1000,
       st_transform(pts.geom, 3044)
    ) AS squares
    ON ST_Intersects(st_transform(pts.geom, 3044), squares.geom)
    GROUP BY squares.geom

    
create table grid_1000 as
with normalized_and_single_points as (
select t as ts, geom from normalized_points np
union 
select ts, geom from point p
where p.aid in (
select aid from (   
select aid, count(*) as c from point 
group by aid) x
where c = 1)
) select count(*), squares.geom
from normalized_and_single_points as pts
INNER JOIN
ST_SquareGrid(
    1000,
   st_transform(pts.geom, 3044)
) AS squares
ON ST_Intersects(st_transform(pts.geom, 3044), squares.geom)
GROUP BY squares.geom



create table grid_2000 as
with normalized_and_single_points as (
select t as ts, geom from normalized_points np
union 
select ts, geom from point p
where p.aid in (
select aid from (   
select aid, count(*) as c from point 
group by aid) x
where c = 1)
) select count(*), squares.geom
from normalized_and_single_points as pts
INNER JOIN
ST_SquareGrid(
    2000,
   st_transform(pts.geom, 3044)
) AS squares
ON ST_Intersects(st_transform(pts.geom, 3044), squares.geom)
GROUP BY squares.geom


create table grid_100 as
with normalized_and_single_points as (
select t as ts, geom from normalized_points np
union 
select ts, geom from point p
where p.aid in (
select aid from (   
select aid, count(*) as c from point 
group by aid) x
where c = 1)
) select count(*), squares.geom
from normalized_and_single_points as pts
INNER JOIN
ST_SquareGrid(
    100,
   st_transform(pts.geom, 3044)
) AS squares
ON ST_Intersects(st_transform(pts.geom, 3044), squares.geom)
GROUP BY squares.geom



select * from intervals i 
where i.route_id = 71238

select * from normalized_points np
where np.route_id = 71238
    