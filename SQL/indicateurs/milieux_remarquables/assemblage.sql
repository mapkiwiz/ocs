CREATE TABLE ind_aura.milieux_remarquables AS
SELECT
	g.gid AS cid,
	frayere.longueur AS l_fra,
	foret_evol_nat.surface AS a_fornat,
	zone_humide.surface AS a_zh,
	tourbiere.surface AS a_tourb
FROM      ind.grid_500m g
LEFT JOIN ind_aura.frayere ON g.gid = frayere.cid
LEFT JOIN ind_aura.foret_evol_nat ON g.gid = foret_evol_nat.cid
LEFT JOIN ind_aura.zone_humide ON g.gid = zone_humide.cid
LEFT JOIN ind_aura.tourbiere ON g.gid = tourbiere.cid;

ALTER TABLE ind_aura.milieux_remarquables
ADD PRIMARY KEY (cid);

DROP TABLE ind_aura.frayere;
DROP TABLE ind_aura.foret_evol_nat;
DROP TABLE ind_aura.zone_humide;
DROP TABLE ind_aura.tourbiere;