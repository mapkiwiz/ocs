CREATE OR REPLACE FUNCTION ind.ind_ocsol(cell_10km bigint)
RETURNS TABLE (cid int, nature ocsv2.ocs_nature, surf_ha double precision, surf_rank integer)
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
            SELECT a.nature, sum(st_area(safe_intersection(cell_geom, a.geom, 0.5))) / 1e4 as surf_ha
            FROM ocsv2.carto_clc a
            WHERE st_intersects(a.geom, cell_geom)
            GROUP BY a.nature
        ),
        surf AS (
            SELECT agg.nature, agg.surf_ha
            FROM agg
            ORDER BY surf_ha DESC
        )
        SELECT cell_id as cid, surf.nature as nature, surf.surf_ha, row_number() over()::int as surf_rank
        FROM surf;

    END LOOP;

    -- RAISE NOTICE 'Cell % (time : %)', cell_10km, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE OR REPLACE FUNCTION ind.ind_ocsol()
RETURNS TABLE (cid int, nature ocsv2.ocs_nature, surf_ha double precision, surf_rank integer)
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
        SELECT * FROM ind.ind_ocsol(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE TABLE ind_aura.ocsol_sparse AS
SELECT * FROM ind.ind_ocsol();


CREATE TABLE ind_aura.ocsol_surfaces AS
SELECT * FROM crosstab(
    'SELECT cid, nature, surf_ha FROM ind_aura.ocsol_sparse ORDER BY cid, nature',
    'SELECT distinct nature FROM ind_aura.ocsol_sparse ORDER BY nature')
AS ct(
    cid int,
    vigx double precision,
    prax double precision,
    agrx double precision,
    zhu double precision,
    esv double precision,
    art double precision,
    natx double precision,
    forx double precision,
    roc double precision,
    nei double precision,
    pur double precision,
    nat double precision,
    arb double precision,
    vig double precision,
    pra double precision,
    cul double precision,
    bat double precision,
    fort double precision,
    eau double precision,
    infx double precision,
    inf double precision
);

UPDATE ind_aura.ocsol_surfaces
SET
vigx = COALESCE(vigx, 0),
prax = COALESCE(prax, 0),
agrx = COALESCE(agrx, 0),
zhu = COALESCE(zhu, 0),
esv = COALESCE(esv, 0),
art = COALESCE(art, 0),
natx = COALESCE(natx, 0),
forx = COALESCE(forx, 0),
roc = COALESCE(roc, 0),
nei = COALESCE(nei, 0),
pur = COALESCE(pur, 0),
nat = COALESCE(nat, 0),
arb = COALESCE(arb, 0),
vig = COALESCE(vig, 0),
pra = COALESCE(pra, 0),
cul = COALESCE(cul, 0),
bat = COALESCE(bat, 0),
fort = COALESCE(fort, 0),
eau = COALESCE(eau, 0),
infx = COALESCE(infx, 0),
inf = COALESCE(inf, 0);

