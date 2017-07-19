CREATE TABLE ocsol_tags AS
SELECT a.fid, b.gid, b.nature::ocs_nature
FROM ocsol a LEFT JOIN
     carto_raw b ON
     -- a.tileid = b.tileid AND
     st_contains(b.geom, st_pointonsurface(a.geom))
WHERE ST_GeometryType(b.geom) = 'ST_Polygon';

ALTER TABLE ocsol
DROP COLUMN nature;

ALTER TABLE ocsol
ADD COLUMN nature ocs_nature;

WITH
tags AS (
	SELECT fid, max(nature) AS nature
	FROM ocsol_tags
	GROUP BY fid
)
UPDATE ocsol
SET nature = coalesce(tags.nature, 'AUTRE/?'::ocs_nature)
FROM tags
WHERE ocsol.fid = tags.fid;


