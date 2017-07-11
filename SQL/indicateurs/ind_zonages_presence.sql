CREATE OR REPLACE FUNCTION ind.ind_zonages_presence(cell_10km bigint)
RETURNS TABLE (cid int, zonage varchar(20))
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
        agg AS (
            SELECT distinct a.zonage
            FROM zonages.tous a
            WHERE st_contains(a.geom, st_centroid(cell_geom))
                  AND a.zonage IN ('contrat_riviere', 'sage', 'scot')
        )
        SELECT cell_id as cid, agg.zonage
        FROM agg;

    END LOOP;

    -- RAISE NOTICE 'Cell % (time : %)', cell_10km, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

-- CREATE TABLE ind.clc_2012_cantal AS
-- SELECT (ind.ind_clc_2012(gid)).* FROM ind.grid_10km_m WHERE dept = 'CANTAL';

CREATE OR REPLACE FUNCTION ind.ind_zonages_presence(query_dept text)
RETURNS TABLE (cid int, zonage varchar(20))
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
        SELECT * FROM ind.ind_zonages_presence(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE TABLE ind.zonages_presence_cantal AS
SELECT * FROM ind.ind_zonages_presence('CANTAL');

CREATE TABLE ind.ct_zonages_presence_cantal AS
SELECT * FROM crosstab(
    'SELECT cid, zonage, true as presence FROM ind.zonages_presence_cantal ORDER BY cid, zonage',
    'SELECT distinct zonage FROM ind.zonages_presence_cantal ORDER BY zonage')
AS ct(
    cid int,
    in_contr boolean,
    in_sage boolean,
    in_scot boolean
);

UPDATE ind.ct_zonages_presence_cantal
SET in_contr = coalesce(in_cont, false),
    in_sage = coalesce(in_sage, false),
    in_scot = coalesce(in_scot, false);