#
#https://github.com/geostyler/geostyler-cli

# npm install -g geostyler-cli

# -h / --help Display the help and exit.
#-o / --output Output filename or directory. Required. [string]
#-s / --source Source parser, either mapbox, mapfile or map, sld (for SLD 1.0), se (for SLD 1.1), qgis or qml. If not given, it will be guessed from the extension of the input file. Mandatory if the the target is a directory.
#-t / --target Target parser, either mapbox, sld (for SLD 1.0), se (for SLD 1.1), qgis or qml. If not given, it will be guessed from the extension of the output file. Mandatory if the the target is a directory. Mapfiles are currently not supported as target.
#-v / --version Display the version of the program.

# geostyler -s sld -t qgis -o output.qml input.sld
# geostyler -s sld -t mapbox -o output.sld input.geojson
geostyler -s sld -t qml -o input.sld output.qml
