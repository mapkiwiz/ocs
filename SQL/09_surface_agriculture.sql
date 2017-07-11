-- Version Pure SQL

DROP TABLE IF EXISTS carto.surface_prairie CASCADE;

CREATE TABLE carto.surface_prairie AS
WITH
prairie AS (
    SELECT a.gid as cid, (st_dump(safe_intersection(a.geom, b.geom))).geom AS geom
    FROM ind.grid_10km_m a INNER JOIN ref.rpg_2012 b ON st_intersects(a.geom, b.geom)
    WHERE b.cult_maj = 17 or b.cult_maj = 18
),
prairie_na AS (
    SELECT b.cid, (st_dump(safe_intersection(a.geom, b.geom))).geom
    FROM carto.surface_ouverte a INNER JOIN prairie b
         ON st_intersects(a.geom, b.geom)
)
SELECT row_number() over() as gid, cid, geom
FROM prairie_na;


DROP TABLE IF EXISTS carto.surface_cultures CASCADE;

CREATE TABLE carto.surface_cultures AS
WITH
cultures AS (
    SELECT a.gid as cid, (st_dump(safe_intersection(a.geom, b.geom))).geom AS geom
    FROM ind.grid_10km_m a INNER JOIN ref.rpg_2012 b ON st_intersects(a.geom, b.geom)
    WHERE b.cult_maj NOT IN (17,18,20,21,22,23,27)
),
cultures_na AS (
    SELECT b.cid, (st_dump(safe_intersection(a.geom, b.geom))).geom
    FROM carto.surface_ouverte a INNER JOIN cultures b
         ON st_intersects(a.geom, b.geom)
)
SELECT row_number() over() as gid, cid, geom
FROM cultures_na;


DROP TABLE IF EXISTS carto.surface_arboriculture CASCADE;

CREATE TABLE carto.surface_arboriculture AS
WITH
arboriculture AS (
    SELECT a.gid as cid, (st_dump(safe_intersection(a.geom, b.geom))).geom AS geom
    FROM ind.grid_10km_m a INNER JOIN ref.rpg_2012 b ON st_intersects(a.geom, b.geom)
    WHERE b.cult_maj IN (20,21,22,23,27)
),
arboriculture_na AS (
    SELECT b.cid, (st_dump(safe_intersection(a.geom, b.geom))).geom
    FROM carto.surface_ouverte a INNER JOIN arboriculture b
         ON st_intersects(a.geom, b.geom)
)
SELECT row_number() over() as gid, cid, geom
FROM arboriculture_na;

CREATE OR REPLACE FUNCTION build_surface_agricole(cell_id bigint)
RETURNS TABLE (type text, geom geometry(Polygon))
AS
$func$
DECLARE

    cell geometry;
    parcelle RECORD;
    part1 geometry;
    part2 geometry;
    part geometry;
    result geometry;
    result_type text;
    count integer;
    start_time TIMESTAMP WITHOUT TIME ZONE;

BEGIN

    count := 0;
    start_time := clock_timestamp();

    SELECT a.geom FROM ind.grid_10km_m a WHERE gid = cell_id INTO cell;
    FOR parcelle IN
        SELECT a.geom, a.cult_maj FROM ref.rpg_2012 a
        WHERE st_intersects(a.geom, cell)
    LOOP

        CASE
            WHEN parcelle.cult_maj IN (17, 18) THEN result_type := 'PRAIRIE';
            WHEN parcelle.cult_maj IN (20,21,22,23,27) THEN result_type := 'ARBORICULTURE';
            ELSE result_type := 'CULTURES';
        END CASE;

        FOR part1 IN SELECT (st_dump(safe_intersection(parcelle.geom, cell, 0.01))).geom
        LOOP

            FOR part2 IN
                SELECT a.geom FROM carto.surface_ouverte a
                WHERE a.cid = cell_id AND st_intersects(a.geom, part1)
            LOOP

                result := safe_intersection(part1, part2, 0.5);

                IF st_geometrytype(result) = 'ST_Polygon' THEN
                    count := count + 1;
                    RETURN QUERY VALUES (result_type, result);
                ELSE
                    FOR part IN SELECT (st_dump(result)).geom
                    LOOP
                        IF st_geometrytype(part) = 'ST_Polygon' THEN
                            count := count + 1;
                            RETURN QUERY VALUES (result_type, part);
                        -- ELSE
                        --     RAISE NOTICE 'Unhandled part of type %', st_geometrytype(part);
                        END IF;
                    END LOOP;
                END IF;

            END LOOP;

        END LOOP;

    END LOOP;

    RAISE NOTICE 'Cell % -> % polygons (time : %)', cell_id, count, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE OR REPLACE FUNCTION build_surface_agricole_bydept(query_dept text)
RETURNS TABLE (cell_id bigint, type text, geom geometry(Polygon))
AS
$func$
DECLARE

    cid bigint;

BEGIN

    FOR cid IN SELECT gid FROM ind.grid_10km_m WHERE dept = query_dept
    LOOP
        RETURN QUERY SELECT cid, a.type, a.geom FROM build_surface_agricole(cid) a;
    END LOOP;

END
$func$
LANGUAGE plpgsql STABLE STRICT;

DROP TABLE IF EXITS carto.surface_agricole CASCADE;

CREATE TABLE carto.surface_agricole AS
WITH
agricole AS (
    SELECT cell_id as cid, type, geom FROM build_surface_agricole_bydept('CANTAL')
)
SELECT row_number() over() as gid, cid, type, geom
FROM agricole;

-- Exemple pour recalculer un maille

DELETE FROM carto.surface_agricole
WHERE cid = 325;

INSERT INTO carto.surface_agricole (gid, cid, type, geom)
WITH p AS (
    SELECT a.type, a.geom FROM build_surface_agricole(326) a
)
SELECT row_number() over() + (SELECT max(gid) FROM carto.surface_agricole) as gid, 325 as cid, p.type, p.geom
FROM p;