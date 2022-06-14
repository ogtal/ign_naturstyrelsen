DROP FUNCTION makegrid_2d(geometry,integer,integer);

CREATE OR REPLACE FUNCTION public.makegrid_2d (
  bound_polygon public.geometry,
  width_step integer,
  height_step integer
)
RETURNS public.geometry AS
$body$
DECLARE
  Xmin DOUBLE PRECISION;
  Xmax DOUBLE PRECISION;
  Ymax DOUBLE PRECISION;
  X DOUBLE PRECISION;
  Y DOUBLE PRECISION;
  NextX DOUBLE PRECISION;
  NextY DOUBLE PRECISION;
  CPoint public.geometry;
  sectors public.geometry[];
  i INTEGER;
  SRID INTEGER;
BEGIN
  Xmin := ST_XMin(bound_polygon);
  Xmax := ST_XMax(bound_polygon);
  Ymax := ST_YMax(bound_polygon);
  SRID := ST_SRID(bound_polygon);

  Y := ST_YMin(bound_polygon); --current sector's corner coordinate
  i := -1;
  <<yloop>>
  LOOP
    IF (Y > Ymax) THEN  
        EXIT;
    END IF;

    X := Xmin;
    <<xloop>>
    LOOP
      IF (X > Xmax) THEN
          EXIT;
      END IF;

      CPoint := ST_SetSRID(ST_MakePoint(X, Y), SRID);
      NextX := ST_X(ST_Project(CPoint, $2, radians(90))::geometry);
      NextY := ST_Y(ST_Project(CPoint, $3, radians(0))::geometry);

      i := i + 1;
      sectors[i] := ST_MakeEnvelope(X, Y, NextX, NextY, SRID);

      X := NextX;
    END LOOP xloop;
    CPoint := ST_SetSRID(ST_MakePoint(X, Y), SRID);
    NextY := ST_Y(ST_Project(CPoint, $3, radians(0))::geometry);
    Y := NextY;
  END LOOP yloop;

  RETURN ST_Collect(sectors);
END;
$body$
LANGUAGE 'plpgsql';

drop table if exists cool_squares;

create table cool_squares as (
  SELECT (
    ST_Dump(
      makegrid_2d(
  ST_GeomFromText(
          'Polygon((12.1880474 55.827127,12.423814 55.827127,12.423814 56.077009,12.1880474 56.077009,12.1880474 55.827127))',
          4326
        ),
         2500, -- width step in meters
         2500  -- height step in meters
       ) 
    )
  ) .geom AS cell
);

drop table if exists square_route;

create table square_route as(
SELECT pts.route_id, pts.iid,  squares.cell
    FROM
    intervals_calc AS pts
    Right JOIN
    cool_squares AS squares
    ON ST_Intersects(pts.x_end, squares.cell)
);

drop table if exists square_route_count;

create table square_route_count as (
select count( distinct route_id) as route_count, cell as geom
from square_route 
group by cell);
