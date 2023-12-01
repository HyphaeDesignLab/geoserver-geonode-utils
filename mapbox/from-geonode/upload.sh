#!/bin/bash

convert_geojson_to_mbtiles() {
  local cdir=$(pwd);
  if [ "$1" ]; then
    cdir="$1"
  fi

  cd $(dirname $0);
  local file_path;
  for file_path in $(find $cdir -type f -name '*.mbtiles'); do
    local mapbox_uploaded_file=$(sed -e 's/.mbtiles/.mapbox.uploaded/' <<< $file_path)
    if [ -f $mapbox_uploaded_file ]; then
      echo "already uploaded $file_path";
      continue;
    fi
    local file_basename=$(basename $file_path)
    local file_basename_no_ext=$(sed -e 's/.mbtiles//' <<< $file_basename)
    local geojson_file=$(sed -e 's/.mbtiles/.geojson/' <<< $file_path)

    echo $file_basename

    #sed -e "s/{id}/$file_basename_no_ext/g" -e "s@{path}@$file_path@" mts-config.template.json > mts-config.json
    #sed -e "s/{id}/$file_basename_no_ext/g" -e "s@{path}@$file_path@" mts-recipe.template.json > mts-recipe.json
    #mtsds --estimate $geojson_file

    echo mapbox -c ./config.ini upload $file_basename_no_ext $file_path
    mapbox -c ./config.ini upload ${file_basename_no_ext:0:32} $file_path
    if [ "$?" = 0 ]; then
      echo 'success'
      echo > $mapbox_uploaded_file;
    fi
    echo
    echo
    echo
  done
}

convert_geojson_to_mbtiles $1
