CREATE TABLE autre_clc AS
WITH autre_clc AS (
	SELECT b.code_12, (st_dump(st_intersection(b.geom, a.geom))).geom AS geom
	FROM patched a LEFT JOIN ref.clc_2012 b
	     ON st_intersects(a.geom, b.geom)
	WHERE a.nature IS NULL OR a.nature IN ('AUTRE/NATURE', 'AUTRE/?')
)
SELECT * FROM autre_clc;