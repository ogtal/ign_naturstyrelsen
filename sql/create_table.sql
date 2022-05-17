create table test_data (
    point_id SERIAL PRIMARY KEY, 
    ts timestamp, 
    aid VARCHAR(40),
    latitude_D FLOAT8, 
    longitude_D FLOAT8, 
    geo geometry(POINT)
)