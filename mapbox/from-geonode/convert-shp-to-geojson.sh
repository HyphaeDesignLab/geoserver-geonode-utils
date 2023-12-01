#!/bin/bash

convert_zip_to_shp_to_geojson() {
  local cdir=$(pwd);
  if [ "$1" ]; then
    cdir="$1"
  fi

  cd $(dirname $0)
  local dir;
  find $cdir -mindepth 1 -type d
  for dir in $(find $cdir -mindepth 1 -type d ); do
    local shp_file=$(ls $dir/*.shp 2>/dev/null | head -1 | tr -d '\n')
    local geojson_file=$(sed -e 's/.shp/.geojson/' <<< $shp_file)
    if [ ! -f $shp_file ]; then
      continue;
    fi
    if [ -f $geojson_file ]; then
      continue;
    fi
    echo "Converting $shp_file"
    ogr2ogr -t_srs 'EPSG:4326' -f "GeoJSON" $geojson_file $shp_file
    sleep 1;
  done
}

convert_zip_to_shp_to_geojson $1;