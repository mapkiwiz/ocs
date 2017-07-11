CREATE OR REPLACE FUNCTION ind.ind_ripi_longueur(cell_10km bigint)
RETURNS TABLE (cid int, length_m double precision)
AS
$func$
DECLARE

    cell_id int;
    cell_geom geometry;
    start_time TIMESTAMP WITHOUT TIME ZONE;

BEGIN

    start_time := clock_timestamp();

    FOR cell_id IN SELECT gid FROM ind.grid_500m WHERE gid_10k = cell_10km
    LOOP

        SELECT geom FROM ind.grid_500m WHERE gid = cell_id INTO cell_geom;

        RETURN QUERY
        WITH
        intersection as (
            SELECT safe_intersection(a.geom, cell_geom, 0.5) as geom
            FROM carto.j_seg_cde_surf_boisee a
            WHERE st_intersects(a.geom, cell_geom) and a.regime = 'Permanent' and a.nearest_distance < 7.5
        ),
        agg AS (
            SELECT sum(st_length(geom)) as length_m
            FROM intersection
            WHERE ST_GeometryType(geom) = 'ST_LineString'
            
        )
        SELECT cell_id as cid, coalesce(agg.length_m, 0)
        FROM agg;

    END LOOP;

    -- RAISE NOTICE 'Cell % (time : %)', cell_10km, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE OR REPLACE FUNCTION ind.ind_ripi_longueur(query_dept text)
RETURNS TABLE (cid int, length_m double precision)
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
        RETURN QUERY
        SELECT * FROM ind.ind_ripi_longueur(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE TABLE ind.ripi_longueur_cantal AS
SELECT * FROM ind.ind_ripi_longueur('CANTAL');

ALTER TABLE ind.ripi_longueur_cantal
ADD COLUMN ripi_ratio double precision,
ADD COLUMN geom geometry(Polygon, 2154);

WITH j AS (
    SELECT a.cid, b.geom, CASE WHEN c.length_m > 0 THEN (a.length_m / c.length_m) ELSE 0 END as ripi_ratio
    FROM ind.ripi_longueur_cantal a
         LEFT JOIN ind.grid_500m b ON a.cid = b.gid
         LEFT JOIN ind.densite_drainage_cantal c ON a.cid = c.cid
)
UPDATE ind.ripi_longueur_cantal
SET geom = j.geom,
    ripi_ratio = j.ripi_ratio
FROM j
WHERE ripi_longueur_cantal.cid = j.cid;