SELECT PostGIS_Extensions_Upgrade();


ALTER EXTENSION postgis UPDATE;


ALTER EXTENSION postgis_sfcgal UPDATE;
ALTER EXTENSION postgis_topology UPDATE;
ALTER EXTENSION postgis_tiger_geocoder UPDATE;


CREATE EXTENSION postgis;

SELECT postgis_full_version();

create table test_points as


explain analyze

create table test_points as

explain analyze
select point_id, 
	   rd.geog AS geog, 
       st_distance(rd.geog, i.geog) as dist_infra
       from test_raw rd, test_infrastruktur i
LIMIT 100000

---   1.000 eksempler: 0.7 sekunder
---  10.000 eksempler: 7 sekunder
--- 100.000 eksempler: 71 sekunder

--- estimeret for det fulder datasæt:
--- 2 timer


explain analyze
select point_id, 
	   rd.geog AS geog, 
       st_distancesphere(rd.geog, i.geog) as dist_infra
       from test_raw rd, test_infrastruktur i
LIMIT 100

order by aid, ts;


create table point as


explain analyze

select ts, geo as geom, horizontal_accuracy, aid, 
       st_distancesphere(rd.geo, j.geom) as dist_jernbane,
       st_distancesphere(rd.geo, v.geom) as dist_vejnet,
       st_distancesphere(rd.geo, m.geom) as dist_motorvej
       from raw_data rd, jernbaner j, vejnet v, motorvej m  
limit 1000000

explain analyze
select point_id,
       st_distancesphere(rd.geo, foo.jern) as dist_jernbane       
       from raw_data rd, (select ST_union(j.geom) as jern from jernbaner j) as foo
limit 10000





select pd.* from point_2d pd
	join jernbaner_staging js 
		on ST_DWithin(pd.geo, ST_Transform(js.geom, 4326), 0.001)
where js.gid < 2

drop table if exists intervals_close_to_infrastructure;

create table intervals_close_to_infrastructure as 
select i.* from intervals i
	join jernbaner j 
		on ST_DWithin(i.x_start, j.geom, 0.001)
	join vejnet v 
		on ST_Dwithin(i.x_start, v.geom, 0.001)
	join motorvej m  
		on ST_Dwithin(i.x_start, m.geom, 0.001)
limit 50
		

create table i_test as 

explain analyze

create table nearby_jernbaner as
select i.iid from intervals i
	join jernbaner j 
		on ST_DWithin(i.x_start, j.geom, 0.001)

		
create table nearby_vejnet as
select i.iid from intervals i
	join vejnet v 
		on ST_DWithin(i.x_start, v.geom, 0.001)

create table nearby_motorvej as
select i.iid from intervals i
	join motorvej m
		on ST_DWithin(i.x_start, m.geom, 0.001)


create table nearby_motorvej as

explain analyze
select i.point_id, i.geo from raw_data i
	join infrastruktur m
		on ST_DWithin(i.geo, m.geom, 0.001)		
limit 100000		
		
EXPLAIN analyze select i.* 
from intervals i 
where i.iid not in
(select it.iid from i_test it)
limit 50000

drop table if exists clean_intervals; 

create table clean_intervals as 
SELECT i.*
FROM intervals i
WHERE i.iid NOT IN (
	select iid from nearby_jernbaner 
		)
	and i.iid not in(
	select iid from nearby_vejnet
	)
	and i.iid not in(
	select iid from nearby_motorvej 
	)
	
select i.*, st_distance(i.x_start, j.geom) from intervals i, jernbaner j
limit 10
	
limit 1
		
select iid from nearby_jernbaner



---drop table IF EXISTS actor ;
---
---create table actor as
---select
---	aid
---from
---	raw_data
---group by
---	aid;

---ALTER TABLE actor
---ADD CONSTRAINT actor_pk PRIMARY KEY (aid);

---drop table if exists device ;

---create table device as
---SELECT
---   aid, manufacturer, model 
---FROM
---	raw_data
---GROUP BY
---   aid, manufacturer , model;

---ALTER TABLE device
---	ADD column device_id SERIAL PRIMARY KEY;

---alter table device
---	add constraint device_fk foreign key (aid) references actor (aid);
