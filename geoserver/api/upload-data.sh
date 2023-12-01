. config.ini
curl -k -u $GEOSERVER_USER:$GEOSERVER_PASS -XPUT -H "Content-type: application/zip" \
  --data-binary @test-data/harry_s_hines_test.zip \
   "$GEOSERVER_URL_BASE/rest/workspaces/greenheart/datastores/pg_greenheart/file.shp"