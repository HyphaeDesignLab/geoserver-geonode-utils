
_debug() {
  local z
  if [ "$HYPHAE_DATA_UPLOAD_DEBUG" ]; then
    read -n1 -p " $1? (y) " z
    echo;
    if [ "$z" != "y" ]; then return 1; fi
    return 0
  fi
  return 0
}
prepare_hyphae_data() {
  cd $(dirname $0)
  local dir
  local zipfile
  for zipfile in *.zip; do
    dir="$(sed -e s/\.zip// <<< $zipfile)"
    if [ ! -d "$dir" ] || [[ "$1" != *skip_unzip* ]]; then
      rm -rf $dir
      unzip $zipfile -d $dir
    fi
    local shp_file=$(ls $dir/*.shp 2>/dev/null)
    local geojson_file=$(ls $dir/*.json $dir/*.geojson 2>/dev/null | tr '\n' '~' | sed -E -e 's/~$//')
    echo "$dir"
    if [ "$shp_file" ] && [ ! "$geojson_file" ]; then
      local file_basename=$(sed -e 's/.shp//' <<< $shp_file);
      echo
      echo Converting SHP to GeoJSON: $shp_file
      _debug 'shp -> geojson line-delimited' \
        && ogr2ogr -t_srs 'EPSG:4326' -f "GeoJSON" $file_basename.geojson $shp_file
    fi
    if [ ! "$geojson_file" ]; then
      echo "NO geojson files";
    elif [[ "$geojson_file" = *'~'* ]]; then
      echo "too many geojson files: $(tr '~' ',' <<< $geojson_file)";
    else
      # if json, rename to geojson
      if grep -F '.json' <<< $geojson_file 2>/dev/null 1>/dev/null; then
        echo "renaming json to geojson"
        local geojson_file2=$(sed -e 's/\.json/.geojson/' <<< $geojson_file)
        mv $geojson_file $geojson_file2
        geojson_file="$geojson_file2"
      fi # end-if json
      echo "converting geojson to geojson line-delimited"
      grep -E '\{ *"type": *"Feature", *"properties":' $geojson_file | sed -E -e 's/,$//' > ${geojson_file}_ \
        && mv ${geojson_file}_ $geojson_file
    fi

  done

}

upload_hyphae_data() {
  for zipfile in *.zip; do
      local dir="$(sed -e s/\.zip// <<< $zipfile)"
      local geojson_file=$(ls -1 $dir/*.geojson 2>/dev/null | head -1 | tr -d '\n')
      echo $geojson_file;
      if [ "$geojson_file" ]; then
        upload_hyphae_project_data $geojson_file
      fi
  done
}
upload_hyphae_project_data() {
  local dir=$(dirname $1)
  local dataset_id=$(basename $1 | sed -e 's/\.json//;s/\.geojson//;s/-/_/g' | tr 'A-Z' 'a-z')
  local dataset_name=$(echo $dataset_id | sed -e 's/_/ /g')
  echo
  if [ -f $dir/upload.log ]; then
    echo "Already uploaded $file as '$dataset_name' (${dataset_id:0:32})"
  else
    echo "Uploading $file as '$dataset_name' (${dataset_id:0:32})"
    _debug 'upload' \
      && php -d display_errors=1 -d error_reporting=E_ALL -d error_log=../mapbox/errors.log \
             -f ../mapbox/api.php tileset_create_and_publish id=${dataset_id:0:32} file=$1
    sleep 5
  fi
}

clean_hyphae_data() {
  local dir
  for dir in $(find . -mindepth 1 -type d); do
    rm $dir/error.txt 2>/dev/null
    rm $dir/test.geojson 2>/dev/null
    rm $dir/tileset.json 2>/dev/null
  done
}



if [ "$HYPHAE_DATA_UPLOAD_DEBUG" ]; then set -x; fi;
if [ "$1" = "prepare" ]; then
 prepare_hyphae_data $2
elif [ "$1" = "upload" ]; then
 upload_hyphae_data
elif [ "$1" = "upload_one" ]; then
 upload_hyphae_project_data $2
elif [ "$1" = "clean" ]; then
 clean_hyphae_data
fi


