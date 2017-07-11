#!/bin/bash

psql <<EOF

CREATE SCHEMA test;

EOF

ls functions/*.sql |
while read f; do

	psql -f $f

done

ls *.sql |
while read f; do

	echo Running step $f
	psql -f $f

done