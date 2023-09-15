geonode_execution_request_get() {
  . .geonode.conf
  curl -k -X 'GET' \
    -H "Authorization: Bearer $access_token" \
    -H 'accept: application/json' \
    "https://geo2.hyphae.design/api/v2/executionrequest/$1/"
}
if [ "$1" = 'run' ]; then
  geonode_execution_request_get $1;
fi;