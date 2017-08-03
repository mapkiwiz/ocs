CREATE OR REPLACE FUNCTION ind.ind_zonages_surf(cell_10km bigint)
RETURNS TABLE (cid int, zonage varchar(20), surf_ha double precision)
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
            SELECT a.zonage, sum(st_area(st_intersection(a.geom, cell_geom))) / 1e4 as surf_ha
            FROM zonages.tous a
            WHERE st_intersects(a.geom, cell_geom)
              AND a.zonage IN (
                    'apb',
                    'bpm',
                    'cen',
                    'ramsar',
                    'rb',
                    'ripn',
                    'rncfs',
                    'rnn',
                    'rnr',
                    'zico',
                    'znieff1',
                    'zps',
                    'zsc',
                    'zsens',
                    'zvuln'
                )
            GROUP BY a.zonage
        )
        SELECT cell_id as cid, agg.zonage, agg.surf_ha
        FROM agg;

    END LOOP;

    -- RAISE NOTICE 'Cell % (time : %)', cell_10km, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

-- CREATE TABLE ind.clc_2012_cantal AS
-- SELECT (ind.ind_clc_2012(gid)).* FROM ind.grid_10km_m WHERE dept = 'CANTAL';

CREATE OR REPLACE FUNCTION ind.ind_zonages_surf(query_dept text)
RETURNS TABLE (cid int, zonage varchar(20), surf_ha double precision)
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
        SELECT * FROM ind.ind_zonages_surf(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE OR REPLACE FUNCTION ind.ind_zonages_surf()
RETURNS TABLE (cid int, zonage varchar(20), surf_ha double precision)
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
        SELECT * FROM ind.ind_zonages_surf(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE TABLE ind_aura.zonages_surf_flat AS
SELECT * FROM ind.ind_zonages_surf();

CREATE TABLE ind_aura.zonages_surf AS
SELECT * FROM crosstab(
    'SELECT a.gid AS cid, b.zonage, b.surf_ha FROM ind.grid_500m a LEFT JOIN ind_aura.zonages_surf_flat b ON a.gid = b.cid ORDER BY a.gid, b.zonage',
    'SELECT distinct zonage FROM ind_aura.zonages_surf_flat ORDER BY zonage')
AS ct(
    cid int,
    apb     double precision,
    -- bpm     double precision,
    cen     double precision,
    ramsar  double precision,
    rb      double precision,
    ripn    double precision,
    rncfs   double precision,
    rnn     double precision,
    rnr     double precision,
    zico    double precision,
    znieff1 double precision,
    zps     double precision,
    zsc     double precision,
    zsens   double precision,
    zvuln   double precision
);

UPDATE ind_aura.zonages_surf
SET
    apb = COALESCE(apb, 0),
    cen = COALESCE(cen, 0),
    ramsar = COALESCE(ramsar, 0),
    rb = COALESCE(rb, 0),
    ripn = COALESCE(ripn, 0),
    rncfs = COALESCE(rncfs, 0),
    rnn = COALESCE(rnn, 0),
    rnr = COALESCE(rnr, 0),
    zico = COALESCE(zico, 0),
    znieff1 = COALESCE(znieff1, 0),
    zps = COALESCE(zps, 0),
    zsc = COALESCE(zsc, 0),
    zsens = COALESCE(zsens, 0),
    zvuln = COALESCE(zvuln, 0);
