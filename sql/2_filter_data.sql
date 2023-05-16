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




