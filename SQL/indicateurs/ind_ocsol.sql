-- Famille d'indicateur : Occupation du sol
-- Indicateurs :
-- Données sources :
-- - carto.ocsol
-- - BD TOPO 

CREATE OR REPLACE FUNCTION ind.ind_ocsol(cell_10km bigint)
RETURNS TABLE (cid int, surf_rank int, type varchar(20), surf_ha double precision)
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
            SELECT a.type, sum(st_area(safe_intersection(a.geom, b.geom, 0.5))) / 1e4 as surf_ha
            FROM carto.ocsol a INNER JOIN ind.grid_500m b ON st_intersects(a.geom, b.geom)
            WHERE b.gid = cell_id
            GROUP BY a.type
        ),
        surf AS (
            SELECT agg.type, agg.surf_ha
            FROM agg
            ORDER BY surf_ha DESC
        )
        SELECT cell_id as cid, row_number() over()::int as surf_rank, surf.type::varchar(20), surf.surf_ha
        FROM surf;

    END LOOP;

    -- RAISE NOTICE 'Cell % (time : %)', cell_10km, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

-- 

CREATE OR REPLACE FUNCTION ind.ind_ocsol(query_dept text)
RETURNS TABLE (cid int, surf_rank int, type varchar(20), surf_ha double precision)
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
        SELECT * FROM ind.ind_ocsol(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

-- Calcul de la matrice d'occupation du sol
-- pour chaque cellule de 500 m

CREATE TABLE ind.ocsol_cantal AS
SELECT * FROM ind.ind_ocsol('CANTAL');

-- Calcul des indicateurs dérivés

CREATE TABLE ind.ocsol_surf_construite_cantal AS
SELECT cid, surf_ha
FROM ind.ocsol_cantal
WHERE type = 'SURFACE IMPERMEABLE';

CREATE TABLE ind.ocsol_surf_eau_cantal AS
SELECT cid, surf_ha
FROM ind.ocsol_cantal
WHERE type = 'SURFACE EN EAU';

CREATE TABLE ind.ocsol_surf_foret_cantal AS
SELECT cid, surf_ha
FROM ind.ocsol_cantal
WHERE type = 'SURFACE BOISEE';

CREATE TABLE ind.ocsol_surf_ouverte_cantal AS
SELECT cid, surf_ha
FROM ind.ocsol_cantal
WHERE type IN ('PRAIRIE', 'ARBORICULTURE', 'SURFACE AUTRE', 'CULTURES');

-- Vérification de la table principale

WITH                                                      
agg as (
    SELECT cid, sum(surf_ha) / 25.0 as coverage
    FROM ind.ocsol_cantal
    GROUP BY cid)
SELECT count(*)
FROM agg
WHERE coverage < 0.8;

-- Cross table

CREATE TABLE ind.ct_ocsol_cantal AS
SELECT * FROM crosstab(
    'SELECT cid, type, surf_ha FROM ind.ocsol_cantal ORDER BY cid, type',
    'SELECT distinct type FROM ind.ocsol_cantal ORDER BY type')
AS ct(
    cid int,
    surf_arboriculture double precision,
    surf_cultures double precision,
    surf_prairie double precision,
    surf_autre double precision,
    surf_foret double precision,
    surf_eau double precision,
    surf_construite double precision
);

ALTER TABLE ind.ct_ocsol_cantal
ADD COLUMN surf_ouverte double precision,
ADD COLUMN surf_totale double precision,
ADD COLUMN geom geometry(Polygon, 2154);

UPDATE ind.ct_ocsol_cantal
SET surf_arboriculture = coalesce(surf_arboriculture, 0),
    surf_cultures = coalesce(surf_cultures, 0),
    surf_prairie = coalesce(surf_prairie, 0),
    surf_autre = coalesce(surf_autre, 0),
    surf_foret = coalesce(surf_foret, 0),
    surf_eau = coalesce(surf_eau, 0),
    surf_construite = coalesce(surf_construite, 0);

UPDATE ind.ct_ocsol_cantal
SET surf_ouverte = (surf_prairie + surf_arboriculture + surf_cultures + surf_autre),
    surf_totale = (surf_prairie + surf_arboriculture + surf_cultures + surf_autre + surf_foret + surf_eau + surf_construite),
    geom = g.geom
FROM ind.grid_500m g
WHERE ct_ocsol_cantal.cid = g.gid; 

