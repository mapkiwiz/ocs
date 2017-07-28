-- pop_2010
-- Population INSEE à partir des données carroyées
-- du recensement de 2010

CREATE TABLE ind_aura.pop AS
SELECT g.gid, coalesce(sum(p.pop), 0) as pop_2010
FROM ind.grid_500m g LEFT JOIN ref.insee_pop_2010_200m_v p
     ON st_contains(g.geom, p.geom)
GROUP BY g.gid;

--
-- Vérification
--

-- Population totale
-- retenue dans la grille

SELECT sum(pop_2010) FROM ind_aura.pop;

-- Population totale
-- rencensée dans la région Auvergne-Rhône-Alpes

SELECT sum(pop)
FROM ref.insee_pop_2010_200m_v a
WHERE EXISTS (
	SELECT gid FROM bdt.bdt_commune
	WHERE st_contains(bdt_commune.geom, a.geom)
);