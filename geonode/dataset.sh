geonode_dataset_get_api_call() {
  . .geonode.conf
  curl -k -X 'GET' \
    -H "Authorization: Bearer $access_token" \
    -H 'accept: application/json' \
    "https://geo2.hyphae.design/api/v2/datasets/$1/"
}

geonode_datasets_get() {
  # for every execution job ID, get the full dataset info
  #     (grep -h = no file name)
  local dataset_ids=( $(grep -hoE '/catalogue/#/dataset/[0-9]+' $geonode_upload_results_dir/upload-*.json 2>/dev/null | sed -e 's@/catalogue/#/dataset/@@'))
  for dataset_id in "${dataset_ids[@]}"; do
    # run the datasets/get API, save to <upload_dir>/dataset-<id>.json
    geonode_dataset_get_api_call $dataset_id >$geonode_upload_results_dir/dataset-$dataset_id.json 2>>$geonode_upload_results_dir/dataset-$dataset_id.log
    sleep .5
  done
  unset dataset_id
  echo >> uploads.log
}
if [ "$1" = 'run' ]; then
  geonode_dataset_get $1;
fi;