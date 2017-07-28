CREATE TABLE ind_aura.pression_infra_pop AS
SELECT
	g.gid AS cid,
	pop.pop_2010,
	route1.longueur AS l_route1,
	route2.longueur AS l_route2,
	le.longueur AS l_elect,
	roe.n_roe::integer
FROM      ind.grid_500m g
LEFT JOIN ind_aura.pop ON g.gid = pop.gid
LEFT JOIN ind_aura.route1 ON g.gid = route1.cid
LEFT JOIN ind_aura.route2 ON g.gid = route2.cid
LEFT JOIN ind_aura.ligne_electrique le ON g.gid = le.cid
LEFT JOIN ind_aura.roe ON g.gid = roe.cid;

ALTER TABLE ind_aura.pression_infra_pop
ADD PRIMARY KEY (cid);

DROP TABLE ind_aura.pop;
DROP TABLE ind_aura.route1;
DROP TABLE ind_aura.route2;
DROP TABLE ind_aura.ligne_electrique;
DROP TABLE ind_aura.roe;