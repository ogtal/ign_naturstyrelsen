--- Lægger pickwell og tællestationersdata til rette til regressionsanalyse
---station_locations = {'onehour_32ed06': {'lat': 55.9641755, 'lon': 12.3109056},
---                     'onehour_302775': {'lat': 55.99425445, 'lon': 12.35565572},
---                     'onehour_30289c': {'lat': 55.95622582, 'lon': 12.34694014},
---                     'onehour_355853': {'lat': 56.00047168, 'lon': 12.30452845},
---                     'onehour_3812a4': {'lat': 56.022677, 'lon': 12.222292},
---                     'eco_egehjorten': {'lat': 55.958153, 'lon': 12.356097},
---                     #'eco_overdrevsvej': {'lat': 55.92656, 'lon': 12.34142}, # ikke nok overlappende data
---                     'eco_praestevang': {'lat': 55.919976, 'lon': 12.324700}}

@set station_name = onehour_30289c
@set format = 'DD/MM YYYY. HH24:MI:SS'
@set station_lat = 55.95622582
@set station_lon = 12.34694014

@set dt = 'day'
@set dx = 100

drop table if exists ${station_name}_${dx}

create table ${station_name}_${dx} as
with station_table as 
(select date_trunc(${dt}, to_timestamp(datetime, ${format})) as t, count as station_count from ${station_name})
select
    t, 
    sum(station_count) as station_count,
    case when EXTRACT(month from t) in (12, 1, 2) then 'winter'
    when EXTRACT(month from t) in (3, 4, 5) then 'spring'
    when EXTRACT(month from t) in (6, 7, 8) then 'summer'
    when EXTRACT(month from t) in (9, 10, 11) then 'autumn'
    end as season,
    abs(abs(extract(DOY from t) - 182.5) - 182.5) as cent_day_num,
    abs(abs(extract(week from t) - 26) - 26) as cent_week_num,
    abs(abs(extract(month from t) - 6) - 6) as cent_month_num                   
from station_table
group by t

drop table if exists gps_${station_name}_${dx}

create table gps_${station_name}_${dx} as
with data_table as (
    select 
        route_id as id, date_trunc(${dt}, t) as t from normalized_points np 
        where ST_DWITHIN(np.geom:: geography, 
        ST_MakePoint(${station_lon}, ${station_lat}):: geography,${dx})
    union
    select 
        ip.isolated_point_id as id, date_trunc('day', t) as t from isolated_points ip 
        where ST_DWITHIN(ip.geom:: geography, 
        ST_MakePoint(${station_lon}, ${station_lat}):: geography,${dx})
)
select 
t,
count(distinct id) as gps_count,
    case when EXTRACT(dow from t) between 1 and 5 then 'workday'
    else 'weekend'
    end as day,
    case when EXTRACT(month from t) in (12, 1, 2) then 'winter'
    when EXTRACT(month from t) in (3, 4, 5) then 'spring'
    when EXTRACT(month from t) in (6, 7, 8) then 'summer'
    when EXTRACT(month from t) in (9, 10, 11) then 'autumn'
    end as season,
    abs(abs(extract(DOY from t) - 182.5) - 182.5) as cent_day_num,
    abs(abs(extract(week from t) - 26) - 26) as cent_week_num,
    abs(abs(extract(month from t) - 6) - 6) as cent_month_num                   
from data_table
group by t


--- data til regressionsanalyse
select a.*, b.station_count  from gps_${station_name}_${dx} a 
join ${station_name}_${dx} b on a.t = b.t


select a.*  from gps_${station_name}_${dx} a 



--- præcist som ovenover, men sat sammen til et sql kald.
with a as ( 
with station_table as 
(select date_trunc(${dt}, to_timestamp(datetime, ${format})) as t, count as station_count from ${station_name})
select
    t, 
    sum(station_count) as station_count,
    case when EXTRACT(month from t) in (12, 1, 2) then 'winter'
    when EXTRACT(month from t) in (3, 4, 5) then 'spring'
    when EXTRACT(month from t) in (6, 7, 8) then 'summer'
    when EXTRACT(month from t) in (9, 10, 11) then 'autumn'
    end as season,
    abs(abs(extract(DOY from t) - 182.5) - 182.5) as cent_day_num,
    abs(abs(extract(week from t) - 26) - 26) as cent_week_num,
    abs(abs(extract(month from t) - 6) - 6) as cent_month_num                   
from station_table
group by t
), b as 
(
with data_table as (
    select 
        route_id as id, date_trunc(${dt}, t) as t from normalized_points np 
        where ST_DWITHIN(np.geom:: geography, 
        ST_MakePoint(${station_lon}, ${station_lat}):: geography,${dx})
    union
    select 
        ip.isolated_point_id as id, date_trunc('day', t) as t from isolated_points ip 
        where ST_DWITHIN(ip.geom:: geography, 
        ST_MakePoint(${station_lon}, ${station_lat}):: geography,${dx})
)
select 
t,
count(distinct id) as gps_count,
    case when EXTRACT(dow from t) between 1 and 5 then 'workday'
    else 'weekend'
    end as day,
    case when EXTRACT(month from t) in (12, 1, 2) then 'winter'
    when EXTRACT(month from t) in (3, 4, 5) then 'spring'
    when EXTRACT(month from t) in (6, 7, 8) then 'summer'
    when EXTRACT(month from t) in (9, 10, 11) then 'autumn'
    end as season,
    abs(abs(extract(DOY from t) - 182.5) - 182.5) as cent_day_num,
    abs(abs(extract(week from t) - 26) - 26) as cent_week_num,
    abs(abs(extract(month from t) - 6) - 6) as cent_month_num                   
from data_table
group by t
) select b.*, a.station_count from b
join a on a.t = b.t




















