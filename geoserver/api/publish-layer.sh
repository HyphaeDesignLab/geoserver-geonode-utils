. config.ini
curl -k -u $GEOSERVER_USER:$GEOSERVER_PASS -X POST -H "Content-type: application/xml" -d '{
  "featureType": {
    "name": "evi_19summ",
    "nativeName": "evi_19summ",
    "title": "EVI 19 Summ",
    "srs": "EPSG:4326",
    "nativeBoundingBox": {
      "minx": -180,
      "maxx": 180,
      "miny": -90,
      "maxy": 90,
      "crs": "EPSG:4326"
    },
    "latLonBoundingBox": {
      "minx": -180,
      "maxx": 180,
      "miny": -90,
      "maxy": 90,
      "crs": "EPSG:4326"
    },
    "projectionPolicy": "FORCE_DECLARED",
    "enabled": true,
    "metadata": {
      "entry": {
        "@key": "cachingEnabled",
        "$": false
      }
    }
  }
}' "$GEOSERVER_URL_BASE/rest/workspaces/greenheart/datastores/pg_greenheart/featuretypes"
