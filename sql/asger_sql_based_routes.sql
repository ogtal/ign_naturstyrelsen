create table actor_test as
select
	aid
from
	raw_data
group by
	aid;

ALTER TABLE actor_test
    ADD CONSTRAINT actor_pk PRIMARY KEY (aid);



drop table if exists device_test ;

create table device_test as
SELECT
   aid, manufacturer, model 
FROM
	raw_data
GROUP BY
   aid, manufacturer , model;

ALTER TABLE device_test
	ADD column device_id SERIAL PRIMARY KEY;

alter table device_test
	add constraint device_fk foreign key (aid) references actor_test (aid);

drop table if exists point_test;

create table point_test as
select
	raw_data.ts, raw_data.geo, raw_data.horizontal_accuracy, device_test.device_id
	from raw_data
	left join device_test on
	raw_data.aid = device_test.aid and
	((raw_data.manufacturer  = device_test.manufacturer) or ((raw_data.manufacturer is null ) and (raw_data.manufacturer is null)))
	and ((raw_data.model = device_test.model) or ((raw_data.model is null) and (raw_data.model is null)))
	order by device_id , ts;

alter table point_test 
add column serialnumber SERIAL;

drop table if exists point_diff;

create table point_diff as
select p1.geo as x_start, 
		 p2.geo as x_end, 
     p1.ts as t_start,
     p1.horizontal_accuracy as horizontal_accuracy,
	   p2.ts as t_end,
	   st_distancesphere(p1.geo, p2.geo) as dx, 
	   (p2.ts - p1.ts) as dt, 
	   st_distancesphere(p1.geo, p2.geo) > '10000' as x_cut,
	   (p2.ts - p1.ts) > interval '10 minute' as t_cut, 
	   p1.device_id  as p1device_id, 
	   p2.device_id  as p2deviec_id,
	   p1.device_id  as device_id,
	   p1.device_id != p2.device_id as device_id_mismatch
from point_test as p1
join point_test as p2 on p1.serialnumber = p2.serialnumber - 1
order by p1.device_id, t_start;

drop table if exists point_diff_2;

create table point_diff_2 as
select
  ,
  sum(case when x_cut then 1
           when t_cut then 1
           when device_id_mismatch then 1 
           else 0 end) over(order by device_id, t_start asc) + 1 
  as route_id
from point_diff
order by device_id, t_start;

drop table if exists point_calc;

create table point_calc as
select
route_id, dx, x_start, x_end, t_start, t_end, horizontal_accuracy,
extract(epoch from dt)/60 as dt,
(dx/(EXTRACT(epoch FROM dt)+1))*3.6 as speed
from point_diff_2
where x_cut = false and t_cut = false and device_id_mismatch = false
order by route_id, t_start;

drop table if exists route_test;

create table route_test as 
select 
route_id, sum(dx) as distance, sum(dt) as time,
AVG(speed) as speed, count(x_start)+1 as n_points
from point_calc
group by route_id;