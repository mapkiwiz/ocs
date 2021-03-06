CREATE OR REPLACE FUNCTION ind.ind_rpg_cult_dominante(cell_10km bigint)
RETURNS TABLE (cid int, surf_rank int, cult_maj varchar(2), surf_ha double precision)
AS
$func$
DECLARE

    cell_id int;
    start_time TIMESTAMP WITHOUT TIME ZONE;

BEGIN

    start_time := clock_timestamp();

    FOR cell_id IN SELECT gid FROM ind.grid_500m WHERE tileid = cell_10km
    LOOP

        RETURN QUERY
        WITH
        clc AS (
            SELECT a.code_cultu AS cult_maj, sum(st_area(st_intersection(a.geom, b.geom))) / 1e4 as surf_ha
            FROM ref.rpg_2014 a INNER JOIN ind.grid_500m b ON st_intersects(a.geom, b.geom)
            WHERE b.gid = cell_id
            GROUP BY a.code_cultu
        ),
        surf AS (
            SELECT clc.cult_maj, clc.surf_ha
            FROM clc
            ORDER BY surf_ha DESC
            LIMIT 1
        )
        SELECT cell_id as cid, row_number() over()::int as surf_rank, surf.cult_maj, surf.surf_ha
        FROM surf;

    END LOOP;

    -- RAISE NOTICE 'Cell % (time : %)', cell_10km, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

-- CREATE TABLE ind.clc_2012_cantal AS
-- SELECT (ind.ind_clc_2012(gid)).* FROM ind.grid_10km_m WHERE dept = 'CANTAL';

CREATE OR REPLACE FUNCTION ind.ind_rpg_cult_dominante()
RETURNS TABLE (cid int, surf_rank int, cult_maj varchar(2), surf_ha double precision)
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
        SELECT * FROM ind.ind_rpg_cult_dominante(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE TABLE ind_aura.rpg_cult_dominante AS
SELECT * FROM ind.ind_rpg_cult_dominante();