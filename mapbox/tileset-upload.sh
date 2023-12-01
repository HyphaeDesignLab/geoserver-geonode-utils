# Mapbox CLI (https://github.com/mapbox/mapbox-cli-py)
mapbox_tileset_upload() {
  script_dir=$(dirname $0)
  mapbox -c $script_dir/config.ini upload --name "$3" $2 $1
}
mapbox_dataset_list() {
  echo
  # mapbox -c mapbox.ini -v datasets list "hyphae-lab.$tilesetId" $outputFile
}

mapbox_tileset_upload $1 $2 "$3"