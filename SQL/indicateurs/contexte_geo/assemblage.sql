CREATE TEMP TABLE contexte_geo_ AS
SELECT
	g.gid AS cid,
	paysage.pays_id AS paysage,
	her.code_her1 AS her1,
	her.code_her2 AS her2,
	substr(rnifn.ser, 1, 1) AS greco,
	rnifn.ser,
	rnifn.rnifn,
	zpg.zpg
FROM      ind.grid_500m g
LEFT JOIN ind_aura.paysage ON g.gid = paysage.cid
LEFT JOIN ind_aura.her ON g.gid = her.cid
LEFT JOIN ind_aura.rnifn ON g.gid = rnifn.cid
LEFT JOIN ind_aura.zpg ON g.gid = zpg.cid;

CREATE TABLE ind_aura.contexte_geo AS
WITH
rows AS (
	SELECT
		*,
		row_number() over(PARTITION BY cid) AS rank
	FROM contexte_geo_
)
SELECT
	cid,
	paysage,
	her1,
	her2,
	greco,
	ser,
	rnifn,
	zpg
FROM rows
WHERE rank = 1;

ALTER TABLE ind_aura.contexte_geo
ADD PRIMARY KEY (cid);

ALTER TABLE ind_aura.contexte_geo 
ALTER COLUMN paysage type character(6),
ALTER COLUMN greco type character(1),
ALTER COLUMN ser type character(3),
ALTER COLUMN rnifn type character(3);

DROP TABLE contexte_geo_;
DROP TABLE ind_aura.paysage;
DROP TABLE ind_aura.her;
DROP TABLE ind_aura.rnifn;
DROP TABLE ind_aura.zpg;