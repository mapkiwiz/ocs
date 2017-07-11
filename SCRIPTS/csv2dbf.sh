function csv2dbf {
	INPUT=$1
	OUTPUT=$(dirname $INPUT)/$(basename $INPUT .csv).dbf
	ogr2ogr -f "ESRI Shapefile" -oo AUTODETECT_WIDTH=YES -oo AUTODETECT_TYPE=YES -oo AUTODETECT_SIZE_LIMIT=0 $OUTPUT $INPUT
}
