#!/bin/bash

convert_geojson_to_mbtiles() {
  local cdir=$(pwd);
  if [ "$1" ]; then
    cdir="$1"
  fi

  cd $(dirname $0)
  local geojson_file;
  for geojson_file in $(find $cdir -type f -name '*geojson'); do
    local mbtiles_file=$(sed -e 's/.geojson/.mbtiles/' <<< $geojson_file)
    if [ -f $mbtiles_file ]; then
      continue;
    fi
    tippecanoe -o  $mbtiles_file -z5 -Z1 $1 $geojson_file
    echo
  done
}

convert_geojson_to_mbtiles $1;