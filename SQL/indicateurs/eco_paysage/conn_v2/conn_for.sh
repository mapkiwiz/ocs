#!/bin/bash

echo "Exporting graph to CSV"

psql -A -F " " -t > /tmp/graph_sb.edges <<EOF

	SELECT
	    sb_gid + (SELECT max(grid_gid) FROM aux.sb_grid_500m_rel),
	    grid_gid
	FROM aux.sb_grid_500m_rel;

EOF

echo "Extracting subgraphs"

./subgraphs.py /tmp/graph_sb.edges

echo "Computing cell metrics"

psql <<EOF

	DROP TABLE IF EXISTS aux.sb_subgraphs;
	
	CREATE TABLE aux.sb_subgraphs (
	    grid_gid int,
	    subg int
	);

	\COPY aux.sb_subgraphs FROM '/tmp/graph_sb.subgraphs' WITH DELIMITER ' ';


	DROP TABLE IF EXISTS ind_aura.conn_for_v2;

	CREATE TABLE ind_aura.conn_for_v2 AS
	WITH
	subgraphs AS (
		SELECT subg, count(grid_gid) AS cnt
		FROM aux.sb_subgraphs
		GROUP BY subg
	)
	SELECT a.grid_gid AS cid, max(b.cnt) AS cnt
	FROM aux.sb_subgraphs a
	INNER JOIN subgraphs b
	ON a.subg = b.subg
	GROUP BY a.grid_gid;

EOF