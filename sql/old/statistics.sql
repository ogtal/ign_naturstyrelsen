SELECT COUNT(*) FROM raw_data


select sum(antal_punkter) from
(SELECT COUNT(*) as antal_punkter, aid FROM raw_data
group by aid) as sub_table
where antal_punkter > 1

SELECT COUNT(*) as antal_punkter, aid FROM raw_data
group by aid




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
order by p1.device_id, t_start