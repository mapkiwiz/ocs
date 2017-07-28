CREATE OR REPLACE FUNCTION ocsv2.TileStats(tid integer)
RETURNS TABLE (
	tileid_ integer,
	dataset text,
	tile_ha double precision,
	objs bigint,
	objs_ha double precision,
	overlap_ha double precision,
	overlap_p numeric,
	smalln bigint,
	smallp numeric,
	unclassified_ha double precision,
	unclassified_p numeric
)
AS
$func$
DECLARE
BEGIN

RETURN QUERY
WITH
tile_info AS (
    SELECT
        gid AS tileid,
        st_area(geom) AS area
    FROM ocs.grid_ocs
    WHERE gid = tid
),
raw AS (
-- Surface stats, before post-processing
    WITH
    raw_stats AS (
        SELECT
            count(gid) AS nobjs,
            sum(st_area(geom)) AS area
        FROM ocsol
        WHERE tileid = (SELECT tileid FROM tile_info)
    ),
    small_objs AS (
        SELECT
            count(gid) AS nobjs,
            sum(st_area(geom)) AS area
        FROM ocsol
        WHERE st_area(geom) < 2500
          AND tileid = (SELECT tileid FROM tile_info)
    ),
    unclassified AS (
        SELECT
            count(gid) AS nobjs,
            sum(st_area(geom)) AS area
        FROM ocsol
        WHERE nature IS NULL OR nature = 'AUTRE/?'
          AND tileid = (SELECT tileid FROM tile_info)
    )
    SELECT
        tile_info.tileid,
        'Fusion brute BDT/RPG'::text AS dataset,
        tile_info.area / 1e4 AS tile_ha,
        raw_stats.nobjs AS objs,
        raw_stats.area / 1e4 AS objs_ha,
        (raw_stats.area - tile_info.area) / 1e4 AS overlap_ha,
        round(( 100.0 * (raw_stats.area - tile_info.area) / tile_info.area )::numeric, 2) AS overlap_p,
        small_objs.nobjs AS smalln,
        round((100.0 * small_objs.nobjs / raw_stats.nobjs)::numeric, 1) AS smallp,
        unclassified.area / 1e4 AS unclassified_ha,
        round((100.0 * unclassified.area / tile_info.area)::numeric, 1) AS unclassified_p
    FROM
        tile_info,
        raw_stats,
        small_objs,
        unclassified
),
simplified AS (
    -- Simplified Stats
    WITH
    raw_stats AS (
        SELECT
            count(gid) AS nobjs,
            sum(st_area(geom)) AS area
        FROM simplified
        WHERE tileid = (SELECT tileid FROM tile_info)
    ),
    small_objs AS (
        SELECT
            count(gid) AS nobjs,
            sum(st_area(geom)) AS area
        FROM simplified
        WHERE st_area(geom) < 2500
          AND tileid = (SELECT tileid FROM tile_info)
    ),
    unclassified AS (
        SELECT
            count(gid) AS nobjs,
            sum(st_area(geom)) AS area
        FROM simplified
        WHERE nature IS NULL OR nature = 'AUTRE/?'
          AND tileid = (SELECT tileid FROM tile_info)
    )
    SELECT
        tile_info.tileid,
        'Après simplifcation'::text AS dataset,
        tile_info.area / 1e4 AS tile_ha,
        raw_stats.nobjs AS objs,
        raw_stats.area / 1e4 AS objs_ha,
        (raw_stats.area - tile_info.area) / 1e4 AS overlap_ha,
        round(( 100.0 * (raw_stats.area - tile_info.area) / tile_info.area )::numeric, 2) AS overlap_p,
        small_objs.nobjs AS smalln,
        round((100.0 * small_objs.nobjs / raw_stats.nobjs)::numeric, 1) AS smallp,
        unclassified.area / 1e4 AS unclassified_ha,
        round((100.0 * unclassified.area / tile_info.area)::numeric, 1) AS unclassified_p
    FROM
        tile_info,
        raw_stats,
        small_objs,
        unclassified
),
final AS (
    -- after post-process stats
    WITH
    raw_stats AS (
        SELECT
            count(gid) AS nobjs,
            sum(st_area(geom)) AS area
        FROM carto_clc
        WHERE tileid = (SELECT tileid FROM tile_info)
    ),
    small_objs AS (
        SELECT
            count(gid) AS nobjs,
            sum(st_area(geom)) AS area
        FROM carto_clc
        WHERE st_area(geom) < 2500
          AND tileid = (SELECT tileid FROM tile_info)
    ),
    unclassified AS (
        SELECT
            count(gid) AS nobjs,
            sum(st_area(geom)) AS area
        FROM carto_clc
        WHERE nature IS NULL OR nature = 'AUTRE/?'
          AND tileid = (SELECT tileid FROM tile_info)
    )
    SELECT
        tile_info.tileid,
        'Après post-traitement CLC'::text AS dataset,
        tile_info.area / 1e4 AS tile_ha,
        raw_stats.nobjs AS objs,
        raw_stats.area / 1e4 AS objs_ha,
        (raw_stats.area - tile_info.area) / 1e4 AS overlap_ha,
        round(( 100.0 * (raw_stats.area - tile_info.area) / tile_info.area )::numeric, 2) AS overlap_p,
        small_objs.nobjs AS smalln,
        round((100.0 * small_objs.nobjs / raw_stats.nobjs)::numeric, 1) AS smallp,
        unclassified.area / 1e4 AS unclassified_ha,
        round((100.0 * unclassified.area / tile_info.area)::numeric, 1) AS unclassified_p
    FROM
        tile_info,
        raw_stats,
        small_objs,
        unclassified
)
SELECT * FROM raw
UNION ALL
SELECT * FROM simplified
UNION ALL
SELECT * FROM final;

END
$func$
LANGUAGE plpgsql VOLATILE STRICT;

