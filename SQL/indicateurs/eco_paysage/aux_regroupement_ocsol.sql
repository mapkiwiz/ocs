CREATE OR REPLACE VIEW ocsv2.carto_clc_foret_dep AS 
SELECT
	a.*, 
	b.dept
FROM ocsv2.carto_clc a
     JOIN ocs.grid_ocs b ON a.tileid = b.gid
WHERE a.nature IN (
	'FORET',
	'A/FORET'
);

CREATE OR REPLACE VIEW ocsv2.carto_clc_urbanise_dep AS 
SELECT
	a.*, 
	b.dept
FROM ocsv2.carto_clc a
     JOIN ocs.grid_ocs b ON a.tileid = b.gid
WHERE a.nature IN (
	'BATI',
	'A/ARTIFICIALISE'
);


CREATE OR REPLACE VIEW ocsv2.carto_clc_ouvert_dep AS 
SELECT
	a.*, 
	b.dept
FROM ocsv2.carto_clc a
     JOIN ocs.grid_ocs b ON a.tileid = b.gid
WHERE a.nature IN (
    'A/VIGNE', -- 221
    'A/PRAIRIE', -- 23
    'A/AGRICOLE', -- 21
    'A/ZONE_HUMIDE', -- 41,42
    'A/ESP.VERTS', -- 14
    'A/NATUREL', -- 321, 322, 323, 5x
    'ROCHERS', -- 33
    'NEIGE', -- 335
    'PERIURBAIN', -- 112
    'NATUREL', 
    'VIGNE', -- 221
    'PRAIRIE', -- 231
    'CULTURES' -- 21
);