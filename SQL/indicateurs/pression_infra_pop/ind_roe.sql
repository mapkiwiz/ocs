-- n_roe
-- Nombre d’obstacles à l’écoulement recensés dans le ROE

CREATE TABLE ind_aura.roe AS
SELECT a.gid AS cid, COALESCE(count(b.gid), 0) AS n_roe
FROM ind.grid_500m a
     LEFT JOIN ref.roe b ON st_contains(a.geom, b.geom)
GROUP BY a.gid;

--
-- Vérification
--

-- Nombre d'obstacles rencensés dans la grille

SELECT sum(n_roe)
FROM ind_aura.roe;

-- Nombre d'obstacles du ROEv3
-- dans la région Auvergne-Rhône-Alpes

SELECT count(*)
FROM ref.roe
WHERE EXISTS (
	SELECT gid FROM bdt.bdt_commune
	WHERE st_contains(bdt_commune.geom, roe.geom)
);


-- Il y a une centaine d'obstacles dans la grille
-- de plus que dans la région AURA
-- parce que quelques mailles dépassent en dehors de la région