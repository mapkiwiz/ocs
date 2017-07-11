CREATE OR REPLACE FUNCTION ind.ind_zonages_surf(cell_10km bigint)
RETURNS TABLE (cid int, zonage varchar(20), surf_ha double precision)
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
            SELECT a.zonage, sum(st_area(safe_intersection(a.geom, b.geom, 0.5))) / 1e4 as surf_ha
            FROM zonages.tous a INNER JOIN ind.grid_500m b ON st_intersects(a.geom, b.geom)
            WHERE b.gid = cell_id and a.zonage not in ('contrat_riviere', 'sage', 'scot', 'her1', 'her2')
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
    SELECT count(gid) FROM ind.grid_10km_m WHERE dept = query_dept INTO num_cells;

    FOR row_num, cell_10km IN SELECT row_number() over()::int, gid FROM ind.grid_10km_m WHERE dept = query_dept
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

CREATE TABLE ind.zonages_surf_cantal AS
SELECT * FROM ind.ind_zonages_surf('CANTAL');

CREATE TABLE ind.ct_zonages_surf_cantal AS
SELECT * FROM crosstab(
    'SELECT cid, zonage, surf_ha FROM ind.zonages_surf_cantal ORDER BY cid, zonage',
    'SELECT distinct zonage FROM zonages.typo WHERE zsurf ORDER BY zonage')
AS ct(
    cid int,
    a_apb double precision,
    a_bpm double precision,
    a_pn double precision,
    a_pnr double precision,
    a_ramsar double precision,
    a_rb double precision,
    a_ripn double precision,
    a_rncfs double precision,
    a_rnn double precision,
    a_rnr double precision,
    a_sitclas double precision,
    a_sitins double precision,
    a_zico double precision,
    a_znief1 double precision,
    a_znief2 double precision,
    a_zs double precision, 
    a_zvuln double precision,
    a_zps double precision,
    a_zsc double precision
);

UPDATE ind.ct_zonages_surf_cantal
SET
a_zsc = coalesce(a_zsc, 0),
a_apb = coalesce(a_apb, 0),
a_pn = coalesce(a_pn, 0),
a_zico  = coalesce(a_zico, 0),
a_zs = coalesce(a_zs, 0),
a_rnr = coalesce(a_rnr, 0),
a_rb  = coalesce(a_rb, 0),
a_znief1 = coalesce(a_znief1, 0),
a_rnn = coalesce(a_rnn, 0),
a_znief2 = coalesce(a_znief2, 0),
a_zvuln  = coalesce(a_zvuln, 0),
a_pnr = coalesce(a_pnr, 0),
a_ripn = coalesce(a_ripn, 0),
a_bpm  = coalesce(a_bpm, 0),
a_ramsar = coalesce(a_ramsar, 0),
a_rncfs = coalesce(a_rncfs, 0),
a_sitins = coalesce(a_sitins, 0),
a_sitclas = coalesce(a_sitclas, 0),
a_zps = coalesce(a_zps, 0);
