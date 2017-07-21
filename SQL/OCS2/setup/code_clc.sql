CREATE TYPE ocs_nature_clc AS ENUM (
    'A/NATUREL', -- 14,32x,5x
    'A/ZONE_HUMIDE', -- 41,42
    'A/VIGNE', -- 221
    'A/PRAIRIE', -- 23
    'A/AGRICOLE', -- 21
    'A/LOGISTIQUE', -- 12
    'A/CARRIERE', -- 13
    'A/LANDES', -- 322
    'A/PELOUSE', -- 321
    'A/FORET', -- 31
    'ROCHERS', -- 33
    'NEIGE', -- 335
    'AUTRE/ARTIFICIALISE', -- 112 
    'ARBORICULTURE', -- 22
    'VIGNE', -- 221
    'PRAIRIE', -- 231
    'CULTURES', -- 21
    'BATI', -- 111
    'FORET', -- 31
    'EAU', -- 51
    'AUTRE/INFRA', -- 122
    'INFRA' -- 122
);

CREATE TABLE ocs.code_clc (
    code_clc character(3),
    nature ocs_nature_clc
);

\COPY ocs.code_clc FROM 'code_clc_ocs_nature.csv' WITH CSV HEADER;

CREATE TABLE ocs.nature_clc (
    nature ocs_nature,
    code_clc character(3)
);

\COPY ocs.nature_clc FROM 'ocs_nature_code_clc.csv' WITH CSV HEADER;


CREATE TABLE ocs.carto_clc AS
WITH
ocs AS (
    SELECT a.tileid, a.geom, (a.nature::text)::ocs_nature_clc, b.code_clc
    FROM ocs.carto_umc a
         LEFT JOIN ocs.nature_clc b
         ON a.nature = b.nature
    WHERE a.nature NOT IN ('AUTRE/NATURE', 'AUTRE/?')
          AND EXISTS (
                SELECT gid
                FROM ocs.grid_ocs
                WHERE dept = 'SAVOIE' AND gid = a.tileid
          )
),
clc AS (
    SELECT a.tileid, a.geom, b.nature, a.code_12 AS code_clc
    FROM ocs.autre_clc_cleaned a
         LEFT JOIN ocs.code_clc b
         ON a.code_12 = b.code_clc
    WHERE EXISTS (
            SELECT gid
            FROM ocs.grid_ocs
            WHERE dept = 'SAVOIE' AND gid = a.tileid
        )
),
ocs_and_clc AS (
    SELECT * FROM ocs
    UNION ALL
    SELECT * FROM clc
)
SELECT row_number() over() AS gid, tileid, geom, nature, code_clc
FROM ocs_and_clc;
