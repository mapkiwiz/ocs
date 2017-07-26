CREATE TABLE carto_clc AS
WITH
ocs AS (
    SELECT a.geom, (a.nature::text)::ocsv2.ocs_nature_clc, b.code_clc
    FROM simplified a
         LEFT JOIN ocsv2.nature_clc b
         ON a.nature::text = b.nature::text
    WHERE a.nature NOT IN ('AUTRE/NATURE', 'AUTRE/?')
),
clc AS (
    SELECT a.geom, (b.nature::text)::ocsv2.ocs_nature_clc, a.code_12 AS code_clc
    FROM autre_clc_cleaned a
         LEFT JOIN ocs.code_clc b
         ON a.code_12 = b.code_clc
),
ocs_and_clc AS (
    SELECT * FROM ocs
    UNION ALL
    SELECT * FROM clc
)
SELECT row_number() over() AS gid, geom, nature, code_clc
FROM ocs_and_clc;

-- INSERT INTO ocsv2.carto_clc (tileid, geom, nature, code_clc)
-- SELECT 791 AS tileid, geom, nature, code_clc
-- FROM carto_clc;