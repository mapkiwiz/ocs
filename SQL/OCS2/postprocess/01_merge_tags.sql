CREATE TABLE test.ocsol_tags AS
SELECT a.fid, b.gid, b.nature::ocs_nature
FROM test.ocsol_cleaned a LEFT JOIN
     test.ocsol b ON st_contains(b.geom, st_pointonsurface(a.geom));

ALTER TABLE test.ocsol_cleaned
ADD COLUMN nature ocs_nature;

WITH
tags AS (
	SELECT fid, max(nature) AS nature
	FROM test.ocsol_tags
	GROUP BY fid
)
UPDATE test.ocsol_cleaned
SET nature = coalesce(tags.nature, 'AUTRE/?'::ocs_nature)
FROM tags
WHERE ocsol_cleaned.fid = tags.fid;


