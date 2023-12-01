if [ ! "$1" ] || [ ! "$2" ]; then
  echo 'usage: shp-to-geojson.sh  <input.shp> <output.geojson>'
  exit;
fi
if [ ! -f "$1" ]; then
  echo "input file does not exist"
  exit;
fi
if [ ! -d $(dirname "$2") ]; then
  echo "output file directory does not exist"
  exit;
fi

# https://gdal.org/programs/ogr2ogr.html
ogr2ogr -t_srs 'EPSG:4326' -f "GeoJSON" $2 $1
