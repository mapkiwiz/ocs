CREATE OR REPLACE FUNCTION ind.ind_haie_longueur(cell_10km bigint)
RETURNS TABLE (cid int, length_m double precision)
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
        intersection as (
            SELECT (st_dump(safe_intersection(a.geom, cell_geom, 0.5))).geom as geom
            FROM bdt.bdt_zone_vegetation a
            WHERE a.nature = 'Haie' and st_intersects(a.geom, cell_geom)
        ),
        agg AS (
            SELECT sum(st_perimeter(geom)) as length_m
            FROM intersection
            WHERE ST_GeometryType(geom) = 'ST_Polygon'
            
        )
        SELECT cell_id as cid, COALESCE(agg.length_m, 0)
        FROM agg;

    END LOOP;

    -- RAISE NOTICE 'Cell % (time : %)', cell_10km, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE OR REPLACE FUNCTION ind.ind_haie_longueur()
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
    SELECT count(gid) FROM ocs.grid_ocs INTO num_cells;

    FOR row_num, cell_10km IN SELECT row_number() over()::int, gid FROM ocs.grid_ocs
    LOOP
        cell_time := clock_timestamp();
        RETURN QUERY
        SELECT * FROM ind.ind_haie_longueur(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE TABLE ind_aura.haie_longueur AS
SELECT * FROM ind.ind_haie_longueur();