create table test_data (
    point_id SERIAL PRIMARY KEY, 
    ts timestamp, 
    aid VARCHAR(40),
    latitude_D FLOAT8, 
    longitude_D FLOAT8, 
    geo geometry(POINT)
)

create table raw_data (
    point_id SERIAL PRIMARY KEY, 
    ts timestamp, 
    aid VARCHAR(36),
    aid_type VARCHAR(10),
    latitude_D FLOAT, 
    longitude_D FLOAT,
    horizontal_accuracy FLOAT,
    altitude FLOAT,
    altitude_accuracy FLOAT,
    manufacturer VARCHAR(256),
    model VARCHAR(256),
    UtcDateTime_str VARCHAR(256),
    geo geometry(POINT)
)


create table phone_info (
    aid VARCHAR(36) PRIMARY KEY,
    aid_type VARCHAR(10),
    manufacturer VARCHAR(256),
    model VARCHAR(256)
)


create table raw_2D_points (
    point_id SERIAL PRIMARY KEY, 
    aid VARCHAR(36),
    ts timestamp, 
    latitude FLOAT, 
    longitude FLOAT,
    horizontal_accuracy FLOAT,
    geo geometry(POINT),
    FOREIGN KEY (aid) REFERENCES phone_info(aid)
)

create table counter_info (
    device_id VARCHAR(36) PRIMARY KEY,
    latitude FLOAT, 
    longitude FLOAT,
    geo geometry(POINT)
)

create table counter_data (
    coount_id SERIAL PRIMARY KEY, 
    count INT,
    ts timestamp
    device_id VARCHAR(36),
    FOREIGN KEY (device_id) REFERENCES counter_info(device_id)
)

#new table structure

create table actor(
    aid VARCHAR(36) PRIMARY KEY 
)

create table device(
    device_id SERIAL PRIMARY KEY,
    aid VARCHAR(36),
    aid_type VARCHAR(10),
    manufacturer VARCHAR(256),
    model VARCHAR(256),
    FOREIGN KEY (aid) REFERENCES actor(aid)
)

create table route (
    route_id SERIAL PRIMARY KEY,
    device_id INT,
    start_ts timestamp,
    end_ts timestamp,
    avg_speed FLOAT,
    duration FLOAT,
    classification VARCHAR(256),
    FOREIGN KEY (device_id) REFERENCES device(device_id)
)

create table point_2D (
    point_id SERIAL PRIMARY KEY,
    route_id INT, 
    ts timestamp, 
    latitude FLOAT, 
    longitude FLOAT,
    horizontal_accuracy FLOAT,
    geo geometry(POINT),
    FOREIGN KEY (route_id) REFERENCES route(route_id)
)