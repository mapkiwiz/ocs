CREATE OR REPLACE FUNCTION Disaggregate(input geometry, distance double precision)
RETURNS SETOF geometry(LineString)
AS
$func$
DECLARE

    p geometry;
    origin geometry;
    previous geometry;
    current geometry;
    segment geometry;
    length double precision;
    x double precision;
    y double precision;
    k int;
    srid int;

BEGIN

    srid = st_srid(input);

    IF ST_GeometryType(input) = 'ST_LineString'
    THEN

        FOR p IN
            SELECT geom FROM ST_DumpPoints(input)
        LOOP

            IF origin IS NOT NULL
            THEN

                length := st_distance(origin, p);

                IF length > 0
                THEN 

                    x := (st_x(p) - st_x(origin)) / length;
                    y := (st_y(p) - st_y(origin)) / length;

                    k := 1;
                    previous := origin;

                    WHILE ((k+1)*distance) < length -- le dernier segment doit rester plus grand que distance
                    LOOP

                        current := st_setsrid(st_makepoint(st_x(origin) + (k*x*distance), st_y(origin) + (k*y*distance)), srid);
                        segment := st_setsrid(st_makeline(previous, current), srid);
                        RETURN NEXT segment;

                        k := k + 1;
                        previous := current;

                    END LOOP;

                END IF;

            END IF;

            segment := st_setsrid(st_makeline(previous, p), srid);
            RETURN NEXT segment;

            origin := p;

        END LOOP;

    ELSIF ST_GeometryType(input) = 'ST_MultiLineString'
    THEN

        FOR p IN
            SELECT geom FROM ST_Dump(input)
        LOOP

            RETURN QUERY SELECT disaggregate(p, distance);

        END LOOP;

    ELSE

        RAISE NOTICE 'Input geometry must be LineString or MultiLineString';

    END IF;

END
$func$
LANGUAGE plpgsql IMMUTABLE STRICT;