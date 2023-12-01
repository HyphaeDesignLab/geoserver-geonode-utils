#!/bin/bash

ogr2ogr_convert_to_mbtiles() {
  local inputFile="$1"
  local outputFile="$2"
  if [ ! "$inputFile" ]; then
    echo 'usage: shp-to-geojson.sh  <input.shp> [<output.geojson>]'
    echo '  output file is optional'
    exit;
  fi
  if [ ! "$outputFile" ]; then
    outputFile=$(sed -E -e 's/\.[a-z]+$/.mbtiles/' <<< $inputFile);
  fi
  if [ ! -f "$inputFile" ]; then
    echo "input file does not exist"
    exit;
  fi
  if [ ! -d "$(dirname "$outputFile")" ]; then
    echo "output file directory does not exist"
    exit;
  fi
  if [ -f "$(dirname "$outputFile")" ]; then
    local zchoice;
    read -p "output file ($outputFile) exists. would you like to overwrite? (y) " zchoice
    if [ "$zchoice" != 'y' ]; then exit; fi
  fi

  # https://gdal.org/programs/ogr2ogr.html
  ogr2ogr -t_srs 'EPSG:4326' -f 'MVT' -dsco FORMAT=MBTILES -dsco MAXZOOM=10 $outputFile $inputFile
}

ogr2ogr_convert_to_mbtiles $1 $2