-- Etape 3
-- On répète l'opération pour chaque grande maille

CREATE TABLE ripi.lin_dgo (
    gid serial PRIMARY KEY,
    cid bigint,
    tx_for double precision,
    tx_for_t double precision,
    geom geometry(LineString, 2154)
);

CREATE INDEX lin_dgo_geom_idx
ON ripi.lin_dgo USING GIST (geom);

CREATE OR REPLACE FUNCTION ripi.lin_ripisylve(query_dept text)
RETURNS VOID
-- RETURNS TABLE (
--     cid bigint,
--     tx_for double precision,
--     tx_for_t double precision,
--     seg_geom geometry(LineString))
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
    SELECT count(gid) FROM ocs.grid_ocs WHERE dept = query_dept INTO num_cells;

    FOR row_num, cell_10km IN
        SELECT row_number() over()::int, gid
        FROM ocs.grid_ocs
        WHERE dept = query_dept
        ORDER BY gid
    LOOP

        cell_time := clock_timestamp();

        INSERT INTO ripi.lin_dgo (cid, tx_for, tx_for_t, geom)
        SELECT cell_10km, a.tx_for, a.tx_for_t, (st_dump(a.seg_geom)).geom
        FROM ripi.lin_ripisylve(cell_10km, 10) a;

        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);

    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql VOLATILE STRICT;