CREATE OR REPLACE FUNCTION ind.ind_mesh_ocs(cell_10km bigint)
RETURNS TABLE (cid int, value double precision)
AS
$func$
DECLARE

    cell_id int;
    cell_geom geometry;
    start_time TIMESTAMP WITHOUT TIME ZONE;

BEGIN

    start_time := clock_timestamp();

    FOR cell_id IN SELECT gid FROM ind.grid_500m WHERE tileid = cell_10km
    LOOP

        SELECT geom FROM ind.grid_500m WHERE gid = cell_id INTO cell_geom;

        RETURN QUERY
        WITH
        fragments AS (
            -- SELECT distinct a.code_12
            SELECT a.nature, st_intersection(a.geom, cell_geom) AS geom
            FROM  ocsv2.carto_clc a
            WHERE st_intersects(a.geom, cell_geom)
                  AND a.nature IN (
                    'FORET',
                    'A/FORET',
                    'NATUREL',
                    'A/NATUREL',
                    'PRAIRIE',
                    'A/PRAIRIE',
                    'A/ZONE_HUMIDE',
                    'PERIURBAIN'
                  )
        ),
        dissolve AS (
            SELECT nature, (st_dump(st_union(geom))).geom
            -- SELECT nature, st_union(geom) AS geom
            FROM fragments
            GROUP BY nature
        ),
        surf AS (
            SELECT st_area(geom) as s
            FROM dissolve
        ),
        total AS (
            SELECT count(s) as n, sum(s) as s FROM surf
            WHERE surf.s > 0
        ),
        mesh as (
            SELECT CASE
                WHEN total.s > 0 THEN sum(pow(surf.s, 2)) / total.s
                ELSE 0
                END as size
            FROM surf, total
            GROUP BY total.s
        )
        SELECT cell_id as cid, size AS value
        FROM mesh;

    END LOOP;

    -- RAISE NOTICE 'Cell % (time : %)', cell_10km, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

--
--

CREATE OR REPLACE FUNCTION ind.ind_mesh_ocs()
RETURNS TABLE (cid int, value double precision)
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
    SELECT count(gid) FROM ocs.grid_ocs INTO num_cells;

    FOR row_num, cell_10km IN SELECT row_number() over()::int, gid FROM ocs.grid_ocs
    LOOP
        cell_time := clock_timestamp();
        RETURN QUERY
        SELECT * FROM ind.ind_mesh_ocs(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE TABLE ind_aura.mesh_ocs AS
SELECT * FROM ind.ind_mesh_ocs();