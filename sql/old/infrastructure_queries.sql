

SELECT Find_SRID('public', 'point_2d', 'geo');
SELECT Find_SRID('public', 'raw_data', 'geo');

--- 4326
SELECT Find_SRID('public', 'jernbaner_staging', 'geom');


SELECT UpdateGeometrySRID('jernbaner_staging','geom',4326);



SELECT ST_SRID(geom) FROM jernbaner_staging LIMIT 1;
SELECT ST_SRID(geo) FROM point_2d pd LIMIT 1;


SELECT * FROM spatial_ref_sys WHERE srid = 3044;

ST_Transform(geom,4326)

select pd.* from point_2d pd
	join jernbaner_staging js 
		on ST_DWithin(pd.geo, ST_Transform(js.geom, 4326), 0.001)
where js.gid < 2


SELECT 
  a.tree_id, a.species, avg(b.age) as age_avg, 
  count(*) as samples, a.geom
FROM trees a 
JOIN trees b
ON ST_DWithin(a.geom, b.geom, 100) AND a.species = b.species
WHERE a.age IS NULL
GROUP BY a.tree_id;


select pd.*, js.gid  
from point_2d pd
join jernbaner_staging js 
	on ST_DWithin(js.geom, pd.geo, 1000)
where js.gid = 6


CREATE TABLE jernbaner_geog AS
SELECT
  ST_Transform(geom,4326)::geography AS geog,
  gid
FROM jernbaner_staging;



