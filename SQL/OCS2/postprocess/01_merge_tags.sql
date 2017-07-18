CREATE TABLE ocsol_tags AS
SELECT a.fid, b.gid, b.nature::ocs_nature
FROM ocsol_cleaned a LEFT JOIN
     ocsol b ON st_contains(b.geom, st_pointonsurface(a.geom))
WHERE ST_GeometryType(b.geom) = 'ST_Polygon';

ALTER TABLE ocsol_cleaned
DROP COLUMN nature;

ALTER TABLE ocsol_cleaned
ADD COLUMN nature ocs_nature;

WITH
tags AS (
	SELECT fid, max(nature) AS nature
	FROM ocsol_tags
	GROUP BY fid
)
UPDATE ocsol_cleaned
SET nature = coalesce(tags.nature, 'AUTRE/?'::ocs_nature)
FROM tags
WHERE ocsol_cleaned.fid = tags.fid;


