CREATE OR REPLACE FUNCTION ind.ind_foret_frag_shannon(cell_10km bigint)
RETURNS TABLE (cid int, value double precision)
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
        fragments AS (
            -- SELECT distinct a.code_12
            SELECT a.nature, (st_dump(st_union(a.geom))).geom
            FROM  bdt.bdt_zone_vegetation a
            WHERE st_intersects(a.geom, cell_geom)
            GROUP BY a.nature
        ),
        objects AS (
            SELECT (st_dump(safe_intersection(a.geom, cell_geom, 0.5))).geom
            FROM fragments a
        ),
        surf AS (
            SELECT st_area(geom) as s
            FROM objects
        ),
        summary AS (
            SELECT count(s) as n, sum(s) as s FROM surf
            WHERE surf.s > 0
        ),
        shannon as (
            SELECT CASE
                WHEN summary.s > 0 THEN -sum((surf.s / summary.s) * ln(surf.s / summary.s))
                ELSE 0
                END as entropy
            FROM surf, summary
            GROUP BY summary.s
        )
        SELECT cell_id as cid, CASE
            WHEN summary.n > 1 THEN shannon.entropy/ln(summary.n)
            ELSE 0
            END
        FROM shannon, summary;

    END LOOP;

    -- RAISE NOTICE 'Cell % (time : %)', cell_10km, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

--
--

CREATE OR REPLACE FUNCTION ind.ind_foret_frag_shannon(query_dept text)
RETURNS TABLE (cid int, value double precision)
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
        SELECT * FROM ind.ind_foret_frag_shannon(cell_10km);
        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);
    END LOOP;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql STABLE STRICT;

CREATE TABLE ind.foret_frag_shannon_cantal AS
SELECT * FROM ind.ind_foret_frag_shannon('CANTAL');

ALTER TABLE ind.foret_frag_shannon_cantal
ADD COLUMN geom geometry(Polygon, 2154);

UPDATE ind.foret_frag_shannon_cantal
SET geom = g.geom
FROM ind.grid_500m g
WHERE foret_frag_shannon_cantal.cid = g.gid;

INSERT INTO ind.foret_frag_shannon_cantal (cid, value, geom)
SELECT a.gid, 0, a.geom
FROM ind.grid_500m a LEFT JOIN ind.foret_frag_shannon_cantal b ON a.gid = b.cid
WHERE a.dept = 'CANTAL' AND b.cid IS NULL;