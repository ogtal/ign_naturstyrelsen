# ign_naturstyrelsen
Undersøgelse af anvendeligheden af GPS data til analyse af friluftsliv



Indlægsning af shape file:


brug shp2pgsql til at konvertere til .sql file. 
Brug info i .prj til at finde ud af hvilken projektion der skal bruges 

shp2pgsql -s 3044 -I Jernbaner.shp jernbaner_staging > jernbaner_staging.sql

derefter læs ind til databasen med:
psql -U edin -d ign_naturstyrelsen -f jernbaner_staging.sql > test.txt


relevante links:


https://towardsdatascience.com/postgis-a-complete-workflow-729bb604f34c

https://stackoverflow.com/questions/1541202/how-do-you-know-what-srid-to-use-for-a-shp-file



query lines:
https://gis.stackexchange.com/questions/23493/how-to-find-the-nearest-point-projected-on-the-road-network


https://gis.stackexchange.com/questions/149570/matching-gps-points-to-the-road-network




# Tabeller 

raw_data - indeholder rådata
onehour_xxxx - tællestationsdata som Lisbeth bruger
xxxxx_staging - vejnet/jernbane data som jeg bruger

