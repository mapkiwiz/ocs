-- Etape 1
-- Préparation de deux tables auxiliaires :
-- 1. Un tampon de 5 m de largeur 
--    autour des troncons (TRONCON_COURS_EAU) et des surfaces en eau (SURFACE_EAU) de la BDT ;
--    on ne garde que les sections qui ont un régime permanent (regime = 'Permanent')
-- 2. Un découpage par grandes mailles des tronçons (TRONCON_COURS_EAU) de la BDT

CREATE TABLE ripi.cde_buffer_5m AS
WITH
surf AS (
    SELECT b.gid as cid, (st_dump(st_buffer(st_union(st_intersection(a.geom, b.geom)), 5))).geom as geom
    FROM bdt.bdt_surface_eau a
         INNER JOIN ind.grid_10km_m b ON st_intersects(a.geom, b.geom)
         INNER JOIN bdt.bdt_troncon_cours_eau c ON st_intersects(a.geom, c.geom)
    WHERE a.regime = 'Permanent'
    GROUP BY b.gid
),
lin AS (
    SELECT b.gid as cid, (st_dump(st_buffer(st_union(st_intersection(a.geom, b.geom)), 5))).geom as geom
    FROM bdt.bdt_troncon_cours_eau a
         INNER JOIN ind.grid_10km_m b ON st_intersects(a.geom, b.geom)
    WHERE a.regime = 'Permanent'
    GROUP BY b.gid
),
surf_and_lin AS (
    SELECT * FROM surf
    UNION SELECT * FROM lin
)
SELECT cid, (st_dump(st_union(geom))).geom
FROM surf_and_lin
GROUP BY cid;

DROP TABLE IF EXISTS ripi.lin_by_grid;

CREATE TABLE ripi.lin_by_grid AS
SELECT b.gid as cid, st_force2d((st_dump(st_intersection(a.geom, b.geom))).geom) as geom
FROM bdt.bdt_troncon_cours_eau a
     INNER JOIN ind.grid_10km_m b ON st_intersects(a.geom, b.geom)
WHERE a.regime = 'Permanent';

CREATE INDEX lin_by_grid_geom_idx
ON ripi.lin_by_grid USING GIST (geom);

-- Etape 2 - Procédure de calcul du taux de ripisylve par segments
--           pour chaque maille de calcul

CREATE OR REPLACE FUNCTION ind.lin_ripisylve(cell_id bigint, disagg_step double precision)
RETURNS TABLE (seg_geom geometry(LineString), tx_for double precision, tx_for_t double precision)
AS
$func$
DECLARE
BEGIN

    DROP TABLE IF EXISTS ripi_lin_points;
    DROP TABLE IF EXISTS ripi_voronoi;
    DROP TABLE IF EXISTS ripi_dgo;
    DROP TABLE IF EXISTS ripi_lin_dgo;
    DROP TABLE IF EXISTS ripi_dgo_side;

    -- RAISE NOTICE 'Create DGOs';

    CREATE TEMP TABLE ripi_lin_points as
    WITH
    lines AS (
        SELECT geom
        FROM st_dump(st_simplify((SELECT st_union(geom) FROM ripi.lin_by_grid WHERE cid = cell_id), 1.0))
    )
    SELECT (disaggregate_line(geom, disagg_step)).vertex as geom
    FROM lines;

    CREATE TABLE ripi_voronoi AS
    SELECT geom
    FROM st_dump(st_voronoipolygons((SELECT st_union(st_force2d(geom)) FROM ripi_lin_points), 2.5));

    CREATE TABLE ripi_dgo AS
    WITH ugo AS (
        SELECT (st_dump(st_intersection(a.geom, b.geom))).geom
        FROM ripi_voronoi a, ripi.cde_buffer_5m b
        WHERE st_isvalid(a.geom) 
              AND st_intersects(a.geom, b.geom)
              AND b.cid = cell_id
    )
    SELECT row_number() over() as dgo_id, geom
    FROM ugo;

    CREATE TABLE ripi_lin_dgo AS
    WITH
    lines AS (
        SELECT (st_dump(geom)).geom
        FROM ripi.lin_by_grid
        WHERE cid = cell_id
    )
    SELECT b.dgo_id, st_force2d(st_intersection(a.geom, b.geom)) as geom
    FROM lines a, ripi_dgo b
    WHERE st_intersects(a.geom, b.geom);

    CREATE TABLE ripi_dgo_side AS
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

    -- RAISE NOTICE 'Compute DGO intersection with carto.surface_boisee';

    WITH
    inter AS (
        SELECT a.gid, coalesce(st_area(st_intersection(a.geom, st_union(b.geom))), 0) / st_area(a.geom) as tx_for
        FROM ripi_dgo_side a LEFT JOIN carto.surface_boisee b ON st_intersects(a.geom, b.geom)
        -- WHERE b.cid = cell_id
        GROUP BY a.gid
    )
    UPDATE ripi_dgo_side
    SET tx_for = inter.tx_for
    FROM inter
    WHERE ripi_dgo_side.gid = inter.gid;

    -- RAISE NOTICE 'Compute DGO intersection with carto.surface_eau';

    WITH
    inter AS (
        SELECT a.gid, coalesce(st_area(st_intersection(a.geom, st_union(b.geom))), 0) / st_area(a.geom) as tx_eau
        FROM ripi_dgo_side a LEFT JOIN carto.surface_eau b ON st_intersects(a.geom, b.geom)
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
        SELECT a.dgo_id, sum(st_length(a.geom)*(CASE WHEN b.tx_for > 0.9 THEN 1 ELSE 0 END)) as tx_for_t, sum(st_length(a.geom)*b.tx_for) as tx_for
        FROM ripi_lin_dgo a INNER JOIN ripi_dgo_side b ON a.dgo_id = b.dgo_id
        GROUP BY a.dgo_id
    )
    UPDATE ripi_lin_dgo
    SET 
        tx_for = v.tx_for / st_length(ripi_lin_dgo.geom),
        tx_for_t = v.tx_for_t / st_length(ripi_lin_dgo.geom)
    FROM v
    WHERE ripi_lin_dgo.dgo_id = v.dgo_id;

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

-- Etape 3
-- On répète l'opération pour chaque grande maille

CREATE OR REPLACE FUNCTION ind.lin_ripisylve(query_dept text)
RETURNS VOID
AS
$func$
DECLARE

    cell_10km bigint;
    start_time TIMESTAMP WITHOUT TIME ZONE;
    cell_time TIMESTAMP WITHOUT TIME ZONE;
    row_num int;
    num_cells int;

BEGIN

    start_time := clock_timestamp();
    SELECT count(gid) FROM ind.grid_10km_m WHERE dept = query_dept INTO num_cells;

    FOR row_num, cell_10km IN SELECT row_number() over()::int, gid FROM ind.grid_10km_m WHERE dept = query_dept
    LOOP

        cell_time := clock_timestamp();
        INSERT INTO ripi.lin_dgo (tx_for, tx_for_t, geom)
        SELECT tx_for, tx_for_t, (st_dump(seg_geom)).geom
        FROM ind.lin_ripisylve(cell_10km, 10);

        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);

    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql VOLATILE STRICT;

DROP TABLE IF EXISTS ripi.lin_dgo;
CREATE TABLE ripi.lin_dgo (
    gid serial,
    tx_for double precision,
    tx_for_t double precision,
    geom geometry(LineString, 2154)
);

SELECT ind.lin_ripisylve('CANTAL');
-- Temps de calcul pour le Cantal
-- NOTICE:  66 cells, total time: 00:49:07.831519

ALTER TABLE ripi.lin_dgo
ADD PRIMARY KEY (gid);

CREATE INDEX lin_dgo_geom_idx
ON ripi.lin_dgo USING GIST (geom);

-- Aggrégation spatiale directe par maille de 500 m

DROP TABLE IF EXISTS ind.ripi_longueur;
CREATE TABLE ind.ripi_longueur AS
SELECT a.gid, sum(b.tx_for * st_length(b.geom)) as l_ripi
FROM ind.grid_500m a LEFT JOIN
     ripi.lin_dgo b ON st_intersects(a.geom, b.geom)
GROUP BY a.gid;