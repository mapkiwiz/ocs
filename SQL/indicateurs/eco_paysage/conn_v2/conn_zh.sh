#!/bin/bash

echo "Exporting graph to CSV"

psql -A -F " " -t > /tmp/graph_zh.edges <<EOF
SELECT
    zh_gid + (SELECT max(grid_gid) FROM aux.zh_grid_500m_rel),
    grid_gid
FROM aux.zh_grid_500m_rel
EOF

echo "Extracting subgraphs"

./subgraphs.py /tmp/graph_zh.edges

echo "Computing cell metrics"

psql <<EOF

	DROP TABLE IF EXISTS aux.zh_subgraphs;
	
	CREATE TABLE aux.zh_subgraphs (
	    grid_gid int,
	    subg int
	);

	\COPY aux.zh_subgraphs FROM '/tmp/graph_zh.subgraphs' WITH DELIMITER ' ';


	DROP TABLE IF EXISTS ind_aura.conn_zh_v2;

	CREATE TABLE ind_aura.conn_zh_v2 AS
	WITH
	subgraphs AS (
		SELECT subg, count(grid_gid) AS cnt
		FROM aux.zh_subgraphs
		GROUP BY subg
	)
	SELECT a.grid_gid AS cid, max(b.cnt) AS cnt
	FROM aux.zh_subgraphs a
	INNER JOIN subgraphs b
	ON a.subg = b.subg
	GROUP BY a.grid_gid;

EOF