drop table if exists test_routes; 

create table test_routes as 
select aid, geo, ts 
from raw_data
order by aid, ts

alter table test_routes 
add column serialnumber SERIAL

drop table if exists test_routes_points; 

create table test_routes_points as
select p1.geo as x_start, 
	   p2.geo as x_end, 
       p1.ts as t_start,
	   p2.ts as t_end, 
	   st_distancesphere(p1.geo, p2.geo) as dx, 
	   (p2.ts - p1.ts) as dt, 
	   st_distancesphere(p1.geo, p2.geo) > '100' as x_cut,
	   (p2.ts - p1.ts) > interval '1 hour' as t_cut, 
	   p1.aid as p1aid, 
	   p2.aid as p2aid,
	   p1.aid as aid,
	   p1.aid != p2.aid as aid_mismatch
from test_routes as p1
join test_routes as p2 on p1.serialnumber = p2.serialnumber - 1
order by p1.aid, t_start

drop table if exists test_routes_points_2; 


create table test_routes_points_2 as
select
  *,
  sum(case when x_cut then 1
           when t_cut then 1
           when aid_mismatch then 1 
           else 0 end) over(order by aid, t_start asc) + 1 
  as route_id
from test_routes_points
order by aid, t_start 


select * from test_routes_points_2 trp 
order by route_id asc

select * from test_routes_points_2
where x_cut = false and t_cut = false and aid_mismatch = false
order by route_id asc

select * from test_routes_points_2 
where route_id = 171




 