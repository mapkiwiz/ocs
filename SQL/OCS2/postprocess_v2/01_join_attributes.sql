CREATE TABLE ocsol_tags AS
SELECT a.fid, b.gid, b.nature::ocsv2.ocs_nature
FROM filled a LEFT JOIN
     ocsol b ON
     -- a.tileid = b.tileid AND
     st_contains(b.geom, st_pointonsurface(a.geom))
WHERE ST_GeometryType(b.geom) = 'ST_Polygon';

ALTER TABLE filled
DROP COLUMN nature;

ALTER TABLE filled
ADD COLUMN nature ocsv2.ocs_nature;

WITH
tags AS (
	SELECT fid, max(nature) AS nature
	FROM ocsol_tags
	GROUP BY fid
)
UPDATE filled
SET nature = coalesce(tags.nature, 'AUTRE/?'::ocsv2.ocs_nature)
FROM tags
WHERE filled.fid = tags.fid;
