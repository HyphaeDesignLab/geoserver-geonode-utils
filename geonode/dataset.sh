geonode_dataset_get() {
  . .geonode.conf
  curl -k -X 'GET' \
    -H "Authorization: Bearer $access_token" \
    -H 'accept: application/json' \
    "https://geo2.hyphae.design/api/v2/datasets/$1/"
}
if [ "$1" = 'run' ]; then
  geonode_dataset_get $1;
fi;