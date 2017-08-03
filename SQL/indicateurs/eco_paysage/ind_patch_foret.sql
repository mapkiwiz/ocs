CREATE OR REPLACE FUNCTION ind.ind_patch_foret(cell_10km bigint)
RETURNS TABLE (cid int, num_obj int)
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
        patches AS (
            SELECT safe_intersection(a.geom, cell_geom, 0.5) as geom
            FROM  aux.surface_boisee a
            WHERE st_intersects(a.geom, cell_geom)
        ),
        objects AS (
            SELECT (st_dump(safe_union(a.geom))).geom
            FROM patches a
        ),
        cnt AS (
            SELECT count(*) as num_obj
            FROM objects
        )
        SELECT cell_id as cid, cnt.num_obj::int
        FROM cnt;

    END LOOP;

    -- RAISE NOTICE 'Cell % (time : %)', cell_10km, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

--
--

CREATE OR REPLACE FUNCTION ind.ind_patch_foret()
RETURNS TABLE (cid int, num_obj int)
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
        SELECT * FROM ind.ind_patch_foret(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE TABLE ind_aura.patch_foret AS
SELECT * FROM ind.ind_patch_foret();