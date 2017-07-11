CREATE OR REPLACE FUNCTION ind.ind_foret_type_dominant(cell_10km bigint)
RETURNS TABLE (cid int, surf_rank int, nature varchar(25), surf_ha double precision)
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
        clc AS (
            SELECT a.nature, sum(st_area(st_intersection(a.geom, b.geom))) / 1e4 as surf_ha
            FROM bdt.bdt_zone_vegetation a INNER JOIN ind.grid_500m b ON st_intersects(a.geom, b.geom)
            WHERE b.gid = cell_id
            GROUP BY a.nature
        ),
        surf AS (
            SELECT clc.nature, clc.surf_ha
            FROM clc
            ORDER BY surf_ha DESC
            LIMIT 1
        )
        SELECT cell_id as cid, row_number() over()::int as surf_rank, surf.nature, surf.surf_ha
        FROM surf;

    END LOOP;

    -- RAISE NOTICE 'Cell % (time : %)', cell_10km, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

-- CREATE TABLE ind.clc_2012_cantal AS
-- SELECT (ind.ind_clc_2012(gid)).* FROM ind.grid_10km_m WHERE dept = 'CANTAL';

CREATE OR REPLACE FUNCTION ind.ind_foret_type_dominant(query_dept text)
RETURNS TABLE (cid int, surf_rank int, nature varchar(25), surf_ha double precision)
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
        SELECT * FROM ind.ind_foret_type_dominant(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE TABLE ind.foret_type_dominant_cantal AS
SELECT * FROM ind.ind_foret_type_dominant('CANTAL');