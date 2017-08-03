CREATE OR REPLACE FUNCTION ind.ind_shdi_clc(cell_10km bigint)
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
            SELECT a.code_12, st_intersection(a.geom, cell_geom) AS geom
            FROM  aux.clc_2012_clipped a
            WHERE st_intersects(a.geom, cell_geom)
              AND a.code_12 NOT LIKE '1%'
        ),
        dissolve AS (
            -- SELECT code_12, (st_dump(st_union(geom))).geom
            SELECT code_12, st_union(geom) AS geom
            FROM fragments
            GROUP BY code_12
        ),
        surf AS (
            SELECT st_area(geom) as s
            FROM dissolve
        ),
        total AS (
            SELECT count(s) as n, sum(s) as s FROM surf
            WHERE surf.s > 0
        ),
        shannon as (
            SELECT CASE
                WHEN total.s > 0 THEN -sum((surf.s / total.s) * ln(surf.s / total.s))
                ELSE 0
                END as entropy
            FROM surf, total
            GROUP BY total.s
        )
        SELECT cell_id as cid, shannon.entropy AS value
        FROM shannon;

    END LOOP;

    -- RAISE NOTICE 'Cell % (time : %)', cell_10km, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

--
--

CREATE OR REPLACE FUNCTION ind.ind_shdi_clc()
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
        SELECT * FROM ind.ind_shdi_clc(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE TABLE ind_aura.shdi_clc AS
SELECT * FROM ind.ind_shdi_clc();