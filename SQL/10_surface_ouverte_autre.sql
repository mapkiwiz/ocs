CREATE TABLE carto.surface_ouverte_autre AS
WITH
agricole AS (
    SELECT cid, geom FROM carto.surface_cultures
    UNION
    SELECT cid, geom FROM carto.surface_prairie
    UNION
    SELECT cid, geom FROM carto.surface_arboriculture
),
to_be_removed AS (
    SELECT a.gid, st_union(st_intersection(a.geom, b.geom)) AS geom
    FROM carto.surface_ouverte a INNER JOIN agricole b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
),
diff AS (
    SELECT a.gid, a.cid, (st_dump(coalesce(safe_difference(a.geom, r.geom), a.geom))).geom AS geom
    FROM carto.surface_ouverte a LEFT JOIN to_be_removed r ON a.gid = r.gid
)
SELECT row_number() over() as gid, cid, diff.geom
FROM diff;

-- CREATE OR REPLACE FUNCTION build_surface_autre(cell_id bigint)
-- RETURNS SETOF geometry(Polygon)
-- AS
-- $func$
-- DECLARE

--     obj RECORD;
--     matching geometry;
--     new_geom geometry;
--     part geometry;
--     count integer;
--     start_time TIMESTAMP WITHOUT TIME ZONE;

-- BEGIN

--     count := 0;
--     start_time := clock_timestamp();

--     FOR obj IN SELECT gid, cid, geom FROM carto.surface_ouverte
--                WHERE cid = cell_id
--     LOOP
        
--         new_geom := st_snaptogrid(obj.geom, 0.5);
--         FOR matching IN 
--             SELECT (st_dump(safe_intersection(st_snaptogrid(geom, 0.5), obj.geom, 0.01))).geom
--             FROM carto.surface_agricole
--             WHERE cid = cell_id AND st_intersects(geom, obj.geom)
--         LOOP

--             IF st_geometrytype(matching) = 'ST_Polygon' OR st_geometrytype(matching) = 'ST_MultiPolygon' THEN
--                 new_geom := safe_difference(new_geom, matching, 0.5);
--             END IF;

--         END LOOP;

--         FOR part IN SELECT (st_dump(st_snaptogrid(new_geom, 0.5))).geom
--         LOOP

--             count := count + 1;
--             RETURN NEXT part;

--         END LOOP;

--     END LOOP;

--     RAISE NOTICE 'Cell % -> % polygons (time: %)', cell_id, count, (clock_timestamp() - start_time);

-- END
-- $func$
-- LANGUAGE plpgsql STABLE STRICT;

CREATE OR REPLACE FUNCTION build_surface_autre(cell_id bigint)
RETURNS SETOF geometry(Polygon)
AS
$func$
DECLARE

    obj RECORD;
    matching geometry;
    new_geom geometry;
    part geometry;
    count integer;
    start_time TIMESTAMP WITHOUT TIME ZONE;

BEGIN

    count := 0;
    start_time := clock_timestamp();

    FOR obj IN
        SELECT gid, cid, geom
        FROM carto.surface_ouverte
        WHERE cid = cell_id
    LOOP
        
        new_geom := obj.geom;
        FOR matching IN 
            WITH p AS (
                SELECT (st_dump(safe_intersection(geom, obj.geom, 0.01))).geom
                FROM carto.surface_agricole
                WHERE cid = cell_id AND (geom && obj.geom) AND safe_intersects(geom, obj.geom, 0.5)
            )
            SELECT geom FROM p
            ORDER BY st_area(geom) DESC
        LOOP

            IF st_geometrytype(matching) = 'ST_Polygon' OR st_geometrytype(matching) = 'ST_MultiPolygon' THEN
                new_geom := safe_difference(new_geom, matching, 0.5);
            END IF;

        END LOOP;

        FOR part IN SELECT (st_dump(new_geom)).geom
        LOOP

            count := count + 1;
            RETURN NEXT part;

        END LOOP;

    END LOOP;

    RAISE NOTICE 'Cell % -> % polygons (time: %)', cell_id, count, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;


-- Exemple pour générer les surfaces autres
-- pour un seul département

CREATE TABLE carto.surface_autre AS
WITH
autre AS (
    SELECT gid as cid, build_surface_autre(gid) as geom
    FROM ind.grid_10km_m
    WHERE dept = 'CANTAL'
    ORDER BY gid
)
SELECT row_number() over() as gid, cid, geom
FROM autre;
