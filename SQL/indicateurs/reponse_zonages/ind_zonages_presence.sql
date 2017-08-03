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

    FOR cell_id IN SELECT gid FROM ind.grid_500m WHERE tileid = cell_10km
    LOOP

         SELECT geom FROM ind.grid_500m WHERE gid = cell_id INTO cell_geom;

        RETURN QUERY
        WITH
        agg AS (
            SELECT distinct a.zonage
            FROM zonages.tous a
            WHERE st_contains(a.geom, st_centroid(cell_geom))
              AND a.zonage IN (
                    'comil',
                    'sage',
                    'scot',
                    'forpub',
                    'pnr',
                    'pn',
                    'zico',
                    'znieff2',
                    'zsens',
                    'zvuln'
                )
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
    SELECT count(gid) FROM ocs.grid_ocs WHERE dept = query_dept INTO num_cells;

    FOR row_num, cell_10km IN SELECT row_number() over()::int, gid FROM ocs.grid_ocs WHERE dept = query_dept
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

CREATE OR REPLACE FUNCTION ind.ind_zonages_presence()
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
    SELECT count(gid) FROM ocs.grid_ocs INTO num_cells;

    FOR row_num, cell_10km IN SELECT row_number() over()::int, gid FROM ocs.grid_ocs
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

CREATE TABLE ind_aura.zonages_presence_flat AS
SELECT * FROM ind.ind_zonages_presence();

CREATE TABLE ind_aura.zonages_presence AS
SELECT * FROM crosstab(
    'SELECT a.gid AS cid, b.zonage, (b.zonage IS NOT NULL) as presence FROM ind.grid_500m a LEFT JOIN ind_aura.zonages_presence_flat b ON a.gid = b.cid ORDER BY a.gid, b.zonage',
    'SELECT distinct zonage FROM ind_aura.zonages_presence_flat ORDER BY zonage')
AS ct(
    cid int,
    comil boolean,
    forpub boolean,
    pn boolean,
    pnr boolean,
    sage boolean,
    scot boolean,
    zico boolean,
    znieff2 boolean,
    zsens boolean,
    zvuln boolean
);

UPDATE ind_aura.zonages_presence
SET
comil = COALESCE(comil, false),
forpub = COALESCE(forpub, false),
pn = COALESCE(pn, false),
pnr = COALESCE(pnr, false),
sage = COALESCE(sage, false),
scot = COALESCE(scot, false),
zico = COALESCE(zico, false),
znieff2 = COALESCE(znieff2, false),
zsens = COALESCE(zsens, false),
zvuln = COALESCE(zvuln, false);