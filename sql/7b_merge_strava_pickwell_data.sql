
--- Lægger strava og pickwell data til rette til regressionsanalyse

@set dt = 'day'
@set dx = 100

drop table if exists test_strava_rand_${dx} 

create table test_strava_rand_${dx} as
select date_trunc(${dt}, date) as trunc_date, sum(scaled_trip_count) as scaled_trip_count
from strava_rand_grid_${dx}
group by trunc_date
order by trunc_date asc  

drop table if exists test_pickwell_rand_${dx}

create table test_pickwell_rand_${dx} as
with pickwell as (
select date_trunc(${dt}, ts) as trunc_date, sum(pts) as pickwell_counts from pickwell_rand_grid_${dx}
group by trunc_date
) select trunc_date, pickwell_counts,
case when EXTRACT(month from trunc_date) in (12, 1, 2) then 'winter'
when EXTRACT(month from trunc_date) in (3, 4, 5) then 'spring'
when EXTRACT(month from trunc_date) in (6, 7, 8) then 'summer'
when EXTRACT(month from trunc_date) in (9, 10, 11) then 'autumn'
end as season,
case when EXTRACT(dow from trunc_date) between 1 and 5 then 'workday'
else 'weekend'
end as day,
abs(abs(extract(DOY from trunc_date) - 182.5) - 182.5) as cent_day_num,
abs(abs(extract(week from trunc_date) - 26) - 26) as cent_week_num,
abs(abs(extract(month from trunc_date) - 6) - 6) as cent_month_num  
from pickwell
order by trunc_date asc

select tp.*, tst.scaled_trip_count  from test_pickwell_rand_${dx} tp
join test_strava_rand_${dx} tst on tst.trunc_date = tp.trunc_date


--- alt ovenstående i et kald:
WITH a AS (
select date_trunc(${dt}, date) as trunc_date, sum(scaled_trip_count) as scaled_trip_count
from strava_rand_grid_${dx}
group by trunc_date
order by trunc_date asc  
), b AS (
with pickwell as (
select date_trunc(${dt}, ts) as trunc_date, sum(pts) as pickwell_counts from pickwell_rand_grid_${dx}
group by trunc_date
) select trunc_date, pickwell_counts,
case when EXTRACT(month from trunc_date) in (12, 1, 2) then 'winter'
when EXTRACT(month from trunc_date) in (3, 4, 5) then 'spring'
when EXTRACT(month from trunc_date) in (6, 7, 8) then 'summer'
when EXTRACT(month from trunc_date) in (9, 10, 11) then 'autumn'
end as season,
case when EXTRACT(dow from trunc_date) between 1 and 5 then 'workday'
else 'weekend'
end as day,
abs(abs(extract(DOY from trunc_date) - 182.5) - 182.5) as cent_day_num,
abs(abs(extract(week from trunc_date) - 26) - 26) as cent_week_num,
abs(abs(extract(month from trunc_date) - 6) - 6) as cent_month_num  
from pickwell
) SELECT a.scaled_trip_count, b.* FROM a
JOIN b ON a.trunc_date = b.trunc_date
