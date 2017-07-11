DROP TABLE IF EXISTS carto.surface_ouverte CASCADE;

CREATE TABLE carto.surface_ouverte AS
WITH
to_be_removed AS (
    SELECT a.gid, safe_union(safe_intersection(a.geom, b.geom)) AS geom
    FROM carto.surface_non_impermeable a INNER JOIN carto.surface_boisee b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
),
diff AS (
    SELECT a.gid, a.cid, (st_dump(coalesce(safe_difference(a.geom, r.geom), a.geom))).geom AS geom
    FROM carto.surface_non_impermeable a LEFT JOIN to_be_removed r ON a.gid = r.gid
)
SELECT row_number() over() as gid, cid, diff.geom
FROM diff;

INSERT INTO carto.small_polygons (gid, cid, geom)
SELECT row_number() over() + (SELECT max(gid) FROM carto.small_polygons) as gid, cid, geom
FROM carto.surface_ouverte
WHERE st_area(geom) < 1500;

DELETE FROM carto.surface_ouverte
WHERE st_area(geom) < 1500;


CREATE OR REPLACE FUNCTION build_surface_ouverte(cell_id int)
RETURNS SETOF geometry(Polygon)
AS
$func$
DECLARE

    obj RECORD;
    matching geometry;
    new_geom geometry;
    part geometry;
    count integer;

BEGIN

    count := 0;
    FOR obj IN SELECT gid, cid, geom FROM carto.surface_non_impermeable
               WHERE cid = cell_id
    LOOP
        
        new_geom := obj.geom;
        FOR matching IN 
            SELECT safe_intersection(geom, obj.geom)
            FROM carto.surface_boisee
            WHERE cid = cell_id AND st_intersects(geom, obj.geom)
        LOOP

            IF st_geometrytype(matching) = 'ST_Polygon' OR st_geometrytype(matching) = 'ST_MultiPolygon' THEN
                new_geom := safe_difference(new_geom, matching);
            END IF;

        END LOOP;

        FOR part IN SELECT (st_dump(new_geom)).geom
        LOOP

            count := count + 1;
            RETURN NEXT part;

        END LOOP;

    END LOOP;

    RAISE NOTICE 'Cell % -> % polygons', cell_id, count;

END
$func$
LANGUAGE plpgsql;

DROP TABLE IF EXISTS carto.surface_ouverte CASCADE;

-- Exemple pour générer les surfaces ouvertes
-- pour un seul département

CREATE TABLE carto.surface_ouverte AS
WITH
ouvert AS (
    SELECT gid as cid, build_surface_ouverte(gid) as geom
    FROM ind.grid_10km_m
    WHERE dept = 'CANTAL'
    ORDER BY gid
)
SELECT row_number() over() as gid, cid, geom
FROM ouvert;

INSERT INTO carto.small_polygons (gid, cid, geom)
SELECT row_number() over() + (SELECT max(gid) FROM carto.small_polygons) as gid, cid, geom
FROM carto.surface_ouverte
WHERE st_area(geom) < 1500;

DELETE FROM carto.surface_ouverte
WHERE st_area(geom) < 1500;

-- Exemple pour recalculer un maille

DELETE FROM carto.surface_ouverte
WHERE cid = 325;

INSERT INTO carto.surface_ouverte (gid, cid, geom)
WITH
ouvert AS (
    SELECT build_surface_ouverte(325) as geom
)
SELECT row_number() over() + (SELECT max(gid) FROM carto.surface_ouverte) as gid, 325 as cid, geom
FROM ouvert;