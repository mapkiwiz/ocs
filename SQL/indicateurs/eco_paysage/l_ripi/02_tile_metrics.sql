-- Etape 2 - Procédure de calcul du taux de ripisylve par segments
--           pour chaque maille de calcul

CREATE OR REPLACE FUNCTION ripi.lin_ripisylve(cell_id bigint, disagg_step double precision)
RETURNS TABLE (seg_geom geometry(LineString), tx_for double precision, tx_for_t double precision)
AS
$func$
DECLARE

    intersection_tolerance double precision;

BEGIN

    DROP TABLE IF EXISTS ripi_lin_points;
    DROP TABLE IF EXISTS ripi_voronoi;
    DROP TABLE IF EXISTS ripi_dgo;
    DROP TABLE IF EXISTS ripi_lin_dgo;
    DROP TABLE IF EXISTS ripi_dgo_side;

    intersection_tolerance := 0.5;

    -- RAISE NOTICE 'Create DGOs';

    CREATE TEMP TABLE ripi_lin_points as
    WITH
    lines AS (
        SELECT geom
        FROM st_dump(st_simplify((SELECT st_union(geom) FROM ripi.lin_by_grid WHERE cid = cell_id), 1.0))
    )
    SELECT (disaggregate_line(geom, disagg_step)).vertex as geom
    FROM lines;

    CREATE TEMP TABLE ripi_voronoi AS
    SELECT geom
    FROM st_dump(st_voronoipolygons((SELECT st_union(st_force2d(geom)) FROM ripi_lin_points), 2.5));

    CREATE TEMP TABLE ripi_dgo AS
    WITH ugo AS (
        SELECT (st_dump(st_intersection(a.geom, b.geom))).geom
        FROM ripi_voronoi a, ripi.cde_buffer_5m b
        WHERE st_isvalid(a.geom) 
              AND st_intersects(a.geom, b.geom)
              AND b.cid = cell_id
    )
    SELECT row_number() over() as dgo_id, geom
    FROM ugo;

    CREATE TEMP TABLE ripi_lin_dgo AS
    WITH
    lines AS (
        SELECT (st_dump(geom)).geom
        FROM ripi.lin_by_grid
        WHERE cid = cell_id
    ),
    intersection AS (
        SELECT b.dgo_id, safe_intersection(a.geom, b.geom, intersection_tolerance) as geom
        FROM lines a, ripi_dgo b
        WHERE st_intersects(a.geom, b.geom)
    ),
    parts AS (
        SELECT dgo_id, (st_dump(geom)).geom
        FROM intersection
    )
    SELECT dgo_id, geom
    FROM parts
    WHERE ST_GeometryType(geom) = 'ST_LineString';

    CREATE TEMP TABLE ripi_dgo_side AS
    WITH
    lines AS (
        SELECT (st_dump(geom)).geom
        FROM ripi.lin_by_grid
        WHERE cid = cell_id
    ),
    split AS (
        SELECT a.dgo_id, (st_dump(st_split(a.geom, b.geom))).geom
        FROM ripi_dgo a, lines b
        WHERE st_intersects(a.geom, b.geom)
    )
    SELECT row_number() over() as gid, dgo_id, st_force2d(geom) as geom
    FROM split;

    ALTER TABLE ripi_dgo_side
    ADD PRIMARY KEY (gid);

    CREATE INDEX dgo_geom_idx
    ON ripi_dgo_side USING GIST (geom);

    ALTER TABLE ripi_dgo_side
    ADD COLUMN tx_eau double precision,
    ADD COLUMN tx_for double precision;

    -- RAISE NOTICE 'Compute DGO intersection with surface_boisee';

    WITH
    inter AS (
        SELECT a.gid, coalesce(st_area(safe_intersection(a.geom, st_union(b.geom), intersection_tolerance)), 0) / st_area(a.geom) as tx_for
        FROM ripi_dgo_side a LEFT JOIN aux.surface_boisee b ON st_intersects(a.geom, b.geom)
        -- WHERE b.cid = cell_id
        GROUP BY a.gid
    )
    UPDATE ripi_dgo_side
    SET tx_for = inter.tx_for
    FROM inter
    WHERE ripi_dgo_side.gid = inter.gid;

    -- RAISE NOTICE 'Compute DGO intersection with surface_eau';

    WITH
    inter AS (
        SELECT a.gid, coalesce(st_area(safe_intersection(a.geom, st_union(b.geom), intersection_tolerance)), 0) / st_area(a.geom) as tx_eau
        FROM ripi_dgo_side a LEFT JOIN aux.surface_eau b ON st_intersects(a.geom, b.geom)
        -- WHERE b.cid = cell_id
        GROUP BY a.gid
    )
    UPDATE ripi_dgo_side
    SET tx_eau = inter.tx_eau
    FROM inter
    WHERE ripi_dgo_side.gid = inter.gid;

    UPDATE ripi_dgo_side
    SET tx_for = ripi_dgo_side.tx_for / (1 - ripi_dgo_side.tx_eau)
    WHERE ripi_dgo_side.tx_eau < 1 and ripi_dgo_side.tx_eau > 0;

    ALTER TABLE ripi_lin_dgo
    ADD COLUMN tx_for double precision,
    ADD COLUMN tx_for_t double precision;

    WITH v AS (
        SELECT
            a.dgo_id,
            sum(st_length(a.geom)*(CASE WHEN b.tx_for > 0.9 THEN 1 ELSE 0 END)) as tx_for_t,
            sum(st_length(a.geom)*b.tx_for) as tx_for
        FROM ripi_lin_dgo a INNER JOIN ripi_dgo_side b ON a.dgo_id = b.dgo_id
        GROUP BY a.dgo_id
    )
    UPDATE ripi_lin_dgo
    SET 
        tx_for = v.tx_for / st_length(ripi_lin_dgo.geom),
        tx_for_t = v.tx_for_t / st_length(ripi_lin_dgo.geom)
    FROM v
    WHERE ripi_lin_dgo.dgo_id = v.dgo_id
      AND st_length(ripi_lin_dgo.geom) > 0;

    UPDATE ripi_lin_dgo
    SET tx_for = 2.0
    WHERE ripi_lin_dgo.tx_for > 2.0;

    RETURN QUERY
    SELECT a.geom, a.tx_for, a.tx_for_t
    FROM ripi_lin_dgo a;

    EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error on processing cell %', cell_id;

END
$func$
LANGUAGE plpgsql VOLATILE STRICT;