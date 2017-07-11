CREATE OR REPLACE FUNCTION ind.ind_clc_frag(cell_10km bigint)
RETURNS TABLE (cid int, num_obj int)
AS
$func$
DECLARE

    cell_id int;
    start_time TIMESTAMP WITHOUT TIME ZONE;

BEGIN

    start_time := clock_timestamp();

    FOR cell_id IN SELECT gid FROM ind.grid_500m WHERE gid_10k = cell_10km
    LOOP

        RETURN QUERY
        WITH
        fragments AS (
            -- SELECT distinct a.code_12
            SELECT (st_dump(st_intersection(a.geom, b.geom))).geom as part
            FROM ref.clc_2012 a INNER JOIN ind.grid_500m b ON st_intersects(a.geom, b.geom)
            WHERE b.gid = cell_id
        ),
        cnt AS (
            SELECT count(*) as num_obj
            FROM fragments
        )
        SELECT cell_id as cid, cnt.num_obj::int
        FROM cnt;

    END LOOP;

    -- RAISE NOTICE 'Cell % (time : %)', cell_10km, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

-- CREATE TABLE ind.clc_2012_cantal AS
-- SELECT (ind.ind_clc_2012(gid)).* FROM ind.grid_10km_m WHERE dept = 'CANTAL';

CREATE OR REPLACE FUNCTION ind.ind_clc_frag(query_dept text)
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
    SELECT count(gid) FROM ind.grid_10km_m WHERE dept = query_dept INTO num_cells;

    FOR row_num, cell_10km IN SELECT row_number() over()::int, gid FROM ind.grid_10km_m WHERE dept = query_dept
    LOOP
        cell_time := clock_timestamp();
        RETURN QUERY
        SELECT * FROM ind.ind_clc_frag(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE TABLE ind.clc_frag_cantal AS
SELECT * FROM ind.ind_clc_frag('CANTAL');