#!/bin/bash

psql -A -F " " -t > /tmp/graph_haie.edges <<EOF
SELECT
    haie_gid + (SELECT max(grid_gid) FROM aux.haie_grid_500m_rel),
    grid_gid
FROM aux.haie_grid_500m_rel
EOF

./subgraphs.py /tmp/graph_haie.edges

psql <<EOF

	CREATE TABLE aux.haie_subgraphs (
	    grid_gid int,
	    subg int
	);

	\COPY aux.haie_subgraphs FROM '/tmp/graph_haie.subgraphs' WITH DELIMITER ' ';


	CREATE TABLE ind_aura.conn_haie_v2 AS
	WITH
	subgraphs AS (
		SELECT subg, count(grid_gid) AS cnt
		FROM aux.haie_subgraphs
		GROUP BY subg
	)
	SELECT a.grid_gid AS cid, max(b.cnt) AS cnt
	FROM aux.haie_subgraphs a
	INNER JOIN subgraphs b
	ON a.subg = b.subg
	GROUP BY a.grid_gid;

EOF