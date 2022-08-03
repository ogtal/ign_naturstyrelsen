select date_trunc('month', TO_TIMESTAMP(datetime, 'DD/MM YYYY. HH24:MI:SS')) AS month,
		case
			when EXTRACT(dow from TO_TIMESTAMP(datetime, 'DD/MM YYYY. HH24:MI:SS')) between 1 and 5 then 'workday'
			else 'weekend'
		end,
	   sum(count) as station_count
from onehour_302775 o 
group by 1, 2



select date_trunc('month', t_start) as month, 
       case
		   when EXTRACT(dow from t_start) between 1 and 5 then 'workday'
		   else 'weekend'
	   end,
	count(route_id) as gps_count
from far_from_infra ffi
where ST_DWITHIN(ffi.geom:: geography, 
                  ST_MakePoint('12.3109056', '55.9641755'):: geography,500)
and ffi.v < 30
group by 1, 2
order by 1, 2



select date_trunc('hour', TO_TIMESTAMP(datetime, 'DD/MM YYYY. HH24:MI:SS')) AS hour,
	   sum(count) as station_count
from onehour_302775 o 
where EXTRACT(hour from TO_TIMESTAMP(datetime, 'DD/MM YYYY. HH24:MI:SS')) between 6 and 18
group by 1


select date_trunc('month', t_start) as month, 
	count(route_id) as gps_count
from far_from_infra ffi
where ST_DWITHIN(ffi.geom:: geography, 
                  ST_MakePoint('12.3109056', '55.9641755'):: geography,500)
and EXTRACT(hour from t_start) between 6 and 18
and ffi.v < 30
group by 1
order by 1


--- 

select date_trunc('month', TO_TIMESTAMP(datetime, 'DD/MM YYYY. HH24:MI:SS')) AS month,
		case
			when EXTRACT(dow from TO_TIMESTAMP(datetime, 'DD/MM YYYY. HH24:MI:SS')) between 1 and 5 then 'workday'
			else 'weekend'
		end as workday_weekend,
		case
			when EXTRACT(hour from TO_TIMESTAMP(datetime, 'DD/MM YYYY. HH24:MI:SS')) between 6 and 18 then 'day'
			else 'night'
		end as day_night,
	   sum(count) as station_count
from onehour_302775 o 
group by 1, 2, 3



select date_trunc('month', TO_TIMESTAMP(datetime, 'DD/MM YYYY. HH24:MI:SS')) AS month,
		case
			when EXTRACT(dow from TO_TIMESTAMP(datetime, 'DD/MM YYYY. HH24:MI:SS')) between 1 and 5 then 'workday'
			else 'weekend'
		end as workday_weekend,
		case
			when EXTRACT(hout from TO_TIMESTAMP(datetime, 'DD/MM YYYY. HH24:MI:SS')) between 6 and 18 then 'day'
			else 'weekend'
		end as workday_weekend,
	   sum(count) as station_count
from onehour_302775 o 
group by 1, 2



select TO_TIMESTAMP(datetime, 'DD/MM YYYY. HH24:MI:SS') as datetime, 
		case
			when EXTRACT(dow from TO_TIMESTAMP(datetime, 'DD/MM YYYY. HH24:MI:SS')) between 1 and 5 then 'workday'
			else 'weekend'
		end as workday_weekend,
		case
			when EXTRACT(hour from TO_TIMESTAMP(datetime, 'DD/MM YYYY. HH24:MI:SS')) between 6 and 18 then 'day'
			else 'night'
		end as day_night,
	   count as station_count 
from onehour_302775 o 







