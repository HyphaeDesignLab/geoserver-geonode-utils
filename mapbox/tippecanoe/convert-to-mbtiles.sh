minZoom=$1
maxZoom=$2

if [ ! "$minZoom" ]; then
    minZoom=3
fi
if [ ! "$maxZoom" ]; then
    maxZoom=10
fi

tippecanoe -o $2 -z$maxZoom -Z$minZoom $1