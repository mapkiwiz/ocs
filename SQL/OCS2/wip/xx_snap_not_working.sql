CREATE OR REPLACE FUNCTION polygon2lines(geom geometry)
RETURNS SETOF geometry(LineString)
AS
$func$
DECLARE

    g geometry;
    p integer[];

BEGIN

    FOR p, g IN SELECT * FROM ST_DumpRings(geom)
    LOOP

        RETURN NEXT ST_ExteriorRing(g);

    END LOOP;

END
$func$
LANGUAGE plpgsql IMMUTABLE STRICT;


-- CREATE TABLE test.line_non_infra AS
-- WITH
-- lines AS (
--     SELECT gid, ST_ExteriorRing((ST_DumpRings(geom)).geom) AS geom
--     FROM test.surf_non_infra
-- ),
-- densified AS (
--     SELECT gid, row_number() over() AS line_id, (disaggregate_line(geom, 5)).*
--     FROM lines
-- ),
-- densified_sorted AS (
--     SELECT *
--     FROM densified
--     ORDER BY gid, line_id, index
-- )
-- SELECT gid, ST_MakeLine(vertex) AS geom
-- FROM densified_sorted
-- GROUP BY gid, line_id;


CREATE OR REPLACE FUNCTION PolygonToDenseLineStrings(ageom geometry(Polygon), disstep double precision)
RETURNS SETOF geometry(LineString)
AS
$func$
DECLARE

    ls geometry;
    dls geometry;

BEGIN

    FOR ls IN
        SELECT ST_ExteriorRing((ST_DumpRings(ageom)).geom) AS geom
    LOOP

        WITH dense AS (
            SELECT *
            FROM disaggregate_line(ls, disstep)
        )
        -- dense_ordered AS (
        --     SELECT * FROM dense
        --     ORDER BY index
        -- )
        SELECT ST_MakeLine(vertex) AS geometry
        FROM dense
        INTO dls;

        RETURN NEXT dls;

    END LOOP;

END
$func$
LANGUAGE plpgsql VOLATILE STRICT;

CREATE TABLE test.line_non_infra AS
SELECT gid, PolygonToDenseLineStrings(geom) AS geom
FROM test.surf_non_infra;

CREATE OR REPLACE FUNCTION SnapOnLineNonInfra(ageom geometry, tolerance double precision)
RETURNS geometry
AS
$func$
DECLARE

    temp geometry;
    target geometry;

BEGIN

    temp := ageom;

    FOR target IN
        SELECT a.geom 
        FROM test.line_non_infra a INNER JOIN test.surf_non_infra b ON a.gid = b.gid
        WHERE st_contains(b.geom, ageom)
    LOOP

        temp := ST_Snap(temp, target, 1.5*tolerance);

    END LOOP;

    RETURN temp;

END
$func$
LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION SnapOnLineNonInfra2(ageom geometry, tolerance double precision)
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
        SELECT geom FROM small_diff WHERE st_area(geom) < tolerance
        UNION ALL SELECT ageom AS geom
    )
    SELECT st_union(geom)
    FROM parts
    INTO temp;

    RETURN temp;

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

CREATE TABLE test.surf_construite_snapped_687 AS
SELECT gid, SnapOnLineNonInfra2(geom, 2500) AS geom
FROM test.surf_construite_non_infra
WHERE gid = 687 ;

CREATE OR REPLACE FUNCTION SnapOnLineNonInfra(tolerance double precision)
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

        RETURN NEXT SnapOnLineNonInfra2(ageom, tolerance);
        IF i % 100 = 0
        THEN
            RAISE NOTICE 'Progress % %%', 100 * i / num;
        END IF;

    END LOOP;

END
$func$
LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE TABLE test.surf_construite_snapped AS
SELECT SnapOnLineNonInfra(2500) as geom;