CREATE TABLE ocs.carto_pre_umc AS
WITH
infra AS (
	SELECT tileid, (st_dump(st_union(geom))).geom, max(nature) AS nature
	FROM ocs.carto
	WHERE nature IN ('INFRA', 'AUTRE/INFRA')
	GROUP BY tileid
),
parts AS (
	SELECT tileid, nature, geom
	FROM infra
	UNION ALL
	SELECT tileid, nature, geom
	FROM ocs.carto
	WHERE nature NOT IN ('INFRA', 'AUTRE/INFRA')
)
SELECT row_number() over() AS gid, nature, st_area(geom) AS area, geom, tileid
FROM parts ;