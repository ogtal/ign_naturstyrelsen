









select distinct on (product) product, order_date, sale
           from product_sales
           order by product, order_date desc

           
SELECT * FROM abc
WHERE abc.




drop table if exists points; 

create table points as 
select aid, geo, ts 
from raw_data
order by aid, ts

alter table points 
add column serialnumber SERIAL

drop table if exists intervals; 

create table intervals as
select p1.geo as x_start, 
	   p2.geo as x_end, 
       p1.ts as t_start,
	   p2.ts as t_end, 
	   st_distancesphere(p1.geo, p2.geo) as dx, 
	   (p2.ts - p1.ts) as dt, 
	   st_distancesphere(p1.geo, p2.geo) > '100' as x_cut,
	   (p2.ts - p1.ts) > interval '1 hour' as t_cut, 
	   p1.aid as aid,
	   p1.aid != p2.aid as aid_mismatch
from test_routes as p1
join test_routes as p2 on p1.serialnumber = p2.serialnumber - 1
order by p1.aid, t_start

drop table if exists intervals_2; 


create table intervals_2 as
select
  *,
  sum(case when x_cut then 1
           when t_cut then 1
           when aid_mismatch then 1 
           else 0 end) over(order by aid, t_start asc) + 1 
  as route_id
from test_routes_points
order by aid, t_start 


select * from intervals_2 trp 
order by route_id asc

select * from intervals_2
where x_cut = false and t_cut = false and aid_mismatch = false
order by route_id asc

select * from intervals_2 
where route_id = 171


drop table if exists jernbaner_staging; 


SELECT srid, srtext, proj4text FROM spatial_ref_sys

SELECT * FROM spatial_ref_sys

SELECT srid, srtext, proj4text FROM spatial_ref_sys WHERE srtext ILIKE '%PROJCS["ETRS89 / UTM zone 32N%' and srtext ilike '%false_easting",500000%'




PROJCS["ETRS_1989_UTM_Zone_32N"



select count(*) from route_test rt
where rt.speed = 0


select count(*) from route_test rt
where rt.speed < 2

select count(*) from route_test rt
where rt.speed < 5

select count(*) from route_test rt
where rt.speed > 5 and rt.speed < 10

select count(*) from route_test rt
where rt.speed > 10 and rt.speed < 40

select count(*) from route_test rt
where rt.speed > 40 and rt.speed < 80

select count(*) from route_test rt
where rt.speed > 80 and rt.speed < 150

select count(*) from route_test rt
where rt.speed > 400


SELECT census_blocks.*
   FROM census_blocks INNER JOIN parcels 
      ON ST_DWithin(census_blocks.geog, parcels.geog, 1609)
WHERE parcels.parcel_id = '12345';


SELECT rd.*
FROM raw_data a, jernbaner_staging b
WHERE ST_DWithin(a.geo, b.geom, 100)


select rd.* from raw_data rd
	join jernbaner_staging js 
		on ST_DWithin(rd.geo, js.geom, 10000)
where js.gid < 4
		
		
SELECT 
  ST_DWithin(
  'POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))'::GEOMETRY,
  'POINT (29 10)'::GEOMETRY,
  3000);
