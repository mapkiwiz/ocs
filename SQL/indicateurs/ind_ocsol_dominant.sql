CREATE OR REPLACE FUNCTION ind.ind_ocsol_dominant(cell_10km bigint)
RETURNS TABLE (cid int, surf_rank int, ocsol text, surf_ha double precision)
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
            SELECT a.type, sum(st_area(safe_intersection(cell_geom, a.geom, 0.5))) / 1e4 as surf_ha
            FROM carto.ocsol a
            WHERE st_intersects(a.geom, cell_geom)
            GROUP BY a.type
        ),
        surf AS (
            SELECT agg.type, agg.surf_ha
            FROM agg
            ORDER BY surf_ha DESC
            LIMIT 2
        )
        SELECT cell_id as cid, row_number() over()::int as surf_rank, surf.type as ocsol, surf.surf_ha
        FROM surf;

    END LOOP;

    -- RAISE NOTICE 'Cell % (time : %)', cell_10km, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

--
--

CREATE OR REPLACE FUNCTION ind.ind_ocsol_dominant(query_dept text)
RETURNS TABLE (cid int, surf_rank int, ocsol text, surf_ha double precision)
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
        SELECT * FROM ind.ind_ocsol_dominant(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE TABLE ind.ocsol_dominant_cantal AS
SELECT * FROM ind.ind_ocsol_dominant('CANTAL');

CREATE OR REPLACE VIEW ind.ocsol_dominant_geo AS
WITH
dom AS (
    SELECT *
    FROM ind.ocsol_dominant_cantal
    WHERE surf_rank = 1
),
subdom AS (
    SELECT *
    FROM ind.ocsol_dominant_cantal
    WHERE surf_rank = 2
)
SELECT a.gid,
       b.ocsol as ocs1, coalesce(b.surf_ha, 0) as a_ocs1,
       c.ocsol as ocs2, coalesce(c.surf_ha, 0) as a_ocs2,
       a.geom
FROM ind.grid_500m a
     LEFT JOIN dom b ON a.gid = b.cid
     LEFT JOIN subdom c ON a.gid = c.cid
WHERE a.dept = 'CANTAL';
