CREATE OR REPLACE FUNCTION disaggregate_line(input geometry, distance double precision)
RETURNS TABLE (index int, vertex geometry(Point), heading double precision)
AS
$func$
DECLARE

    p geometry;
    previous geometry;
    p_heading double precision;
    previous_heading double precision;
    length double precision;
    x double precision;
    y double precision;
    k int;

BEGIN

    index := 0;

    IF ST_GeometryType(input) = 'ST_LineString'
    THEN

        FOR p IN
            SELECT geom FROM ST_DumpPoints(input)
        LOOP

            IF previous IS NOT NULL
            THEN

                length := st_distance(previous, p);

                IF length > 0
                THEN 
                    x := (st_x(p) - st_x(previous)) / length;
                    y := (st_y(p) - st_y(previous)) / length;
                    p_heading := asin(y) * 180 / pi();
                    
                    vertex := previous;
                    heading := CASE WHEN index = 0 THEN p_heading ELSE 0.5 * (p_heading + previous_heading) END;
                    index := index + 1;
                    RETURN NEXT;

                    k := 1;
                    heading := p_heading;
                    WHILE ((k+1)*distance) < length
                    LOOP

                        vertex := st_setsrid(st_makepoint(st_x(previous) + (k*x*distance), st_y(previous) + (k*y*distance)), st_srid(input));
                        index := index + 1;
                        k := k + 1;
                        RETURN NEXT;

                    END LOOP;

                END IF;

                previous_heading := p_heading;

            END IF;

            previous := p;

        END LOOP;

        vertex := p;
        heading := previous_heading;
        index := index + 1;
        RETURN NEXT;

    ELSIF ST_GeometryType(input) = 'ST_MultiLineString'
    THEN

        FOR p IN
            SELECT geom FROM ST_Dump(input)
        LOOP

            RETURN QUERY SELECT * FROM disaggregate_line(p, distance);

        END LOOP;

    ELSE

        RAISE NOTICE 'Input geometry must be LineString or MultiLineString';

    END IF;

END
$func$
LANGUAGE plpgsql IMMUTABLE STRICT;