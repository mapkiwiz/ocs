CREATE TYPE ocs_nature AS ENUM (
	'AUTRE/?', 
	'AUTRE/NATURE', 
	'AUTRE/BATI', 
	'ARBO', 
	'PRAIRIE', 
	'CULTURES', 
	'BATI', 
	'FORET', 
	'EAU',
	'INFRA');

CREATE TABLE test.ocsol_tags AS
SELECT a.fid, b.gid, b.nature::ocs_nature
FROM test.ocsol_cleaned a LEFT JOIN
     test.ocsol b ON st_contains(b.geom, st_pointonsurface(a.geom));

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


