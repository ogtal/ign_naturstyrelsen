--- Lægger strava og tællestationersdata til rette til regressionsanalyse

@set station_name = onehour_30289c
@set format = 'DD/MM YYYY. HH24:MI:SS'

@set dt = 'day'
@set dx = 100

DROP TABLE IF EXISTS test_${station_name}

create table test_${station_name} as
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
    case when EXTRACT(dow from t) between 1 and 5 then 'workday'
    else 'weekend'
    end as day,
    abs(abs(extract(DOY from t) - 182.5) - 182.5) as cent_day_num,
    abs(abs(extract(week from t) - 26) - 26) as cent_week_num,
    abs(abs(extract(month from t) - 6) - 6) as cent_month_num                   
from station_table
group by t

select * from test_${station_name}

create table test_strava_${station_name} as
select date_trunc(${dt}, date) as trunc_date, sum(scaled_trip_count) as scaled_trip_count
from strava_station_circle_${dx}
where name = '${station_name}'
group by trunc_date
order by trunc_date asc  

select ts.*, tst.scaled_trip_count  from test_${station_name} ts
join test_strava_${station_name} tst on tst.trunc_date = ts.t

--- Alt ovenstående i et kald:
WITH a AS (
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
    case when EXTRACT(dow from t) between 1 and 5 then 'workday'
    else 'weekend'
    end as day,
    abs(abs(extract(DOY from t) - 182.5) - 182.5) as cent_day_num,
    abs(abs(extract(week from t) - 26) - 26) as cent_week_num,
    abs(abs(extract(month from t) - 6) - 6) as cent_month_num                   
from station_table
group by t
), b AS (
select date_trunc(${dt}, date) as trunc_date, sum(scaled_trip_count) as scaled_trip_count
from strava_station_circle_${dx}
where name = '${station_name}'
group by trunc_date
order by trunc_date asc  
) SELECT a.*, b.scaled_trip_count FROM a
JOIN b ON a.t = b.trunc_date