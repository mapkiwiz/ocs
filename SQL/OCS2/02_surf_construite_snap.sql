CREATE OR REPLACE FUNCTION SnapOnLineNonInfra(ageom geometry, area_tolerance double precision, width_tolerance double precision)
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
        SELECT (ST_Dump(ST_Difference(b.geom, ageom))).geom
        FROM test.surf_non_infra b
        WHERE st_contains(b.geom, st_centroid(ageom))
    ),
    parts AS (
        SELECT geom FROM small_diff
        WHERE st_area(geom) < area_tolerance
              OR ( 2 * st_area(geom) / st_perimeter(geom) < width_tolerance)
        UNION ALL SELECT ageom AS geom
    )
    SELECT st_union(geom)
    FROM parts
    INTO temp;

    RETURN temp;

END
$func$
LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION SnapOnLineNonInfra(area_tolerance double precision, width_tolerance double precision)
RETURNS SETOF geometry
AS
$func$
DECLARE

    ageom geometry;
    num integer;
    i integer;

BEGIN

    SELECT count(*) FROM test.surf_construite_non_infra INTO num;
    FOR i, ageom IN
        SELECT row_number() over(), geom FROM test.surf_construite_non_infra
    LOOP

        RETURN NEXT SnapOnLineNonInfra(ageom, area_tolerance, width_tolerance);
        IF i % 100 = 0
        THEN
            RAISE NOTICE 'Progress % %%', 100 * i / num;
        END IF;

    END LOOP;

END
$func$
LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE TABLE test.surf_construite_non_infra AS
WITH
intersection AS (
    SELECT (st_dump(st_intersection(a.geom, b.geom))).geom
    FROM test.surf_construite a LEFT JOIN test.surf_non_infra b
    ON st_intersects(a.geom, b.geom)
)
SELECT row_number() over() AS gid, geom
FROM intersection;

CREATE TABLE test.surf_construite_snapped AS
WITH
parts AS (
    SELECT SnapOnLineNonInfra(2500, 5) as geom
)
SELECT row_number() over() AS gid, geom
FROM parts;