CREATE OR REPLACE FUNCTION ind.link_surface_boisee_patches(cell_id bigint, max_distance double precision)
RETURNS TABLE (from_patch bigint, to_patch bigint, inter_distance double precision)
AS
$func$
DECLARE

    patch_id bigint;
    patch geometry;

BEGIN

    CREATE TEMP TABLE surface_boisee_patches (
        from_patch bigint,
        to_patch bigint
    );

    CREATE INDEX surface_boisee_patches_from ON surface_boisee_patches (from_patch);
    CREATE INDEX surface_boisee_patches_to ON surface_boisee_patches (to_patch);

    FOR  patch_id, patch IN
        SELECT gid, geom FROM carto.surface_boisee
        WHERE cid = cell_id
    LOOP

        FOR from_patch, to_patch, inter_distance IN
            SELECT patch_id as from_patch, a.gid as to_patch, st_distance(a.geom, patch) as distance
            FROM carto.surface_boisee a
            WHERE st_dwithin(a.geom, patch, max_distance)
                  AND a.gid != patch_id
                  AND NOT EXISTS (
                    SELECT b.from_patch, b.to_patch
                    FROM surface_boisee_patches b
                    WHERE    (b.from_patch = a.gid AND b.to_patch = patch_id)
                          OR (b.from_patch = patch_id AND b.to_patch = a.gid)
                  )
        LOOP

            INSERT INTO surface_boisee_patches
            VALUES (from_patch, to_patch);

            RETURN NEXT;

        END LOOP;

    END LOOP;

    DROP TABLE surface_boisee_patches CASCADE;

END
$func$
LANGUAGE plpgsql VOLATILE STRICT;


CREATE OR REPLACE FUNCTION ind.link_surface_boisee_patches(query_dept text, max_distance double precision)
RETURNS TABLE (from_patch bigint, to_patch bigint, inter_distance double precision)
AS
$func$
DECLARE

    cell_10km bigint;
    start_time TIMESTAMP WITHOUT TIME ZONE;
    cell_time TIMESTAMP WITHOUT TIME ZONE;
    row_num int;
    num_cells int;

    _from_patch bigint;
    _to_patch bigint;
    _inter_distance double precision;

BEGIN

    start_time := clock_timestamp();
    SELECT count(gid) FROM ind.grid_10km_m WHERE dept = query_dept INTO num_cells;

    CREATE TEMP TABLE surface_boisee_patches_agg (
        from_patch bigint,
        to_patch bigint
    );

    CREATE INDEX surface_boisee_patches_agg_from ON surface_boisee_patches_agg (from_patch);
    CREATE INDEX surface_boisee_patches_agg_to ON surface_boisee_patches_agg (to_patch);

    FOR row_num, cell_10km IN SELECT row_number() over()::int, gid FROM ind.grid_10km_m WHERE dept = query_dept
    LOOP

        cell_time := clock_timestamp();

        FOR _from_patch, _to_patch, _inter_distance IN
            SELECT * FROM ind.link_surface_boisee_patches(cell_10km, max_distance)
        LOOP

            IF NOT EXISTS (
                SELECT a.from_patch, a.to_patch
                FROM surface_boisee_patches_agg a
                WHERE    (a.from_patch = _from_patch AND a.to_patch = _to_patch)
                      OR (a.from_patch = _to_patch AND a.to_patch = _from_patch)
            ) THEN

                INSERT INTO surface_boisee_patches_agg
                VALUES (_from_patch, _to_patch);

                from_patch := _from_patch;
                to_patch := _to_patch;
                inter_distance = _inter_distance;
                RETURN NEXT;

            END IF;

        END LOOP;

        RAISE NOTICE '% %%, cell %, time: %', (100.0 * row_num / num_cells)::int, cell_10km, (clock_timestamp() - cell_time);

    END LOOP;

    DROP TABLE surface_boisee_patches_agg CASCADE;

    RAISE NOTICE '% cells, total time: %', num_cells, (clock_timestamp() - start_time);

END
$func$
LANGUAGE plpgsql VOLATILE STRICT;