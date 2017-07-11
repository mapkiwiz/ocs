CREATE OR REPLACE FUNCTION ind.ind_densite_drainage(cell_10km bigint)
RETURNS TABLE (cid int, length_m double precision)
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
        agg AS (
            SELECT sum(st_length(st_intersection(a.geom, b.geom))) as length_m
            FROM bdt.bdt_troncon_cours_eau a INNER JOIN ind.grid_500m b ON st_intersects(a.geom, b.geom)
            WHERE b.gid = cell_id
        )
        SELECT cell_id as cid, coalesce(agg.length_m, 0)
        FROM agg;

    END LOOP;

    -- RAISE NOTICE 'Cell % (time : %)', cell_10km, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE OR REPLACE FUNCTION ind.ind_densite_drainage(query_dept text)
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
        SELECT * FROM ind.ind_densite_drainage(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE TABLE ind.densite_drainage_cantal AS
SELECT * FROM ind.ind_densite_drainage('CANTAL');