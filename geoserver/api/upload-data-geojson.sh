curl -k -u $GEOSERVER_USER:$GEOSERVER_PASS -XPUT -H "Content-type: application/json" \
  --data-binary @test-data/stations2.geojson \
   "$GEOSERVER_URL_BASE/rest/workspaces/greenheart/datastores/pg_greenheart/file.json"