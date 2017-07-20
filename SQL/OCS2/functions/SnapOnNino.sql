CREATE OR REPLACE FUNCTION SnapOnNino(ageom geometry, area_tolerance double precision, width_tolerance double precision)
RETURNS geometry
AS
$func$
DECLARE

    temp geometry;
    target geometry;

BEGIN

    temp := ageom;

    WITH
    small_diff AS (
        SELECT (ST_Dump(safe_difference(b.geom, ageom, 0.5))).geom
        FROM surf_nino b
        WHERE st_contains(b.geom, st_centroid(ageom))
    ),
    parts AS (
        SELECT geom FROM small_diff
        WHERE st_area(geom) < area_tolerance
              OR ( 2 * st_area(geom) / st_perimeter(geom) < width_tolerance)
        UNION ALL SELECT ageom AS geom
    )
    SELECT safe_union(geom)
    FROM parts
    INTO temp;

    RETURN temp;

END
$func$
LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION SnapOnNino(area_tolerance double precision, width_tolerance double precision)
RETURNS SETOF geometry
AS
$func$
DECLARE

    ageom geometry;
    num integer;
    i integer;

BEGIN

    SELECT count(*) FROM surf_construite_nino INTO num;
    FOR i, ageom IN
        SELECT row_number() over(), geom FROM surf_construite_nino
    LOOP

        RETURN NEXT SnapOnNino(ageom, area_tolerance, width_tolerance);
        IF i % 100 = 0
        THEN
            RAISE NOTICE 'Progress % %%', 100 * i / num;
        END IF;

    END LOOP;

END
$func$
LANGUAGE plpgsql IMMUTABLE STRICT;