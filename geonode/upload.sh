# if no arguments, then give info and prompt user for info
if [ "$1" = "" ]; then
  echo
  echo
  echo '----------------------------------------------------------------- '
  echo ' Genode Layer/Data Auto-uploader'
  echo '----------------------------------------------------------------- '
  echo
fi
. uploader.sh
geonode_upload_results_dir='/var/folders/n9/r20kc5hx3tq2spn1fr7gvsrh0000gp/T/tmp.Sekrd65b/'
# geonode_upload_main "$@"

. execution-request.sh
#for geonode_execution_id in $(sed -E -e 's/[{} "]+//g' -e 's/.*execution_id:(.+)$/\1/' $geonode_upload_results_dir/upload.json ); do
#  geonode_execution_request_get $geonode_execution_id > $geonode_upload_results_dir/upload-$geonode_execution_id.json 2>$geonode_upload_results_dir/upload-$geonode_execution_id.log;
#  sleep 1
#done

. dataset.sh
# h = no file name
geonode_upload_dataset_ids=( $(grep -hoE '/catalogue/#/dataset/[0-9]+' $geonode_upload_results_dir/upload-*.json | sed -e 's@/catalogue/#/dataset/@@'))
for geonode_upload_dataset_id in "${geonode_upload_dataset_ids[@]}"; do
  #geonode_dataset_get $geonode_upload_dataset_id >$geonode_upload_results_dir/dataset-$geonode_upload_dataset_id.json 2>>$geonode_upload_results_dir/dataset-$geonode_upload_dataset_id.log
  sleep 1
done
unset geonode_upload_dataset_id

echo -n > upload-results.txt
for geonode_upload_dataset_id in "${geonode_upload_dataset_ids[@]}"; do
  echo -n $geonode_upload_dataset_id, >> upload-results.txt
  grep -oE '"embed_url": *"[^"]+"' $geonode_upload_results_dir/dataset-$geonode_upload_dataset_id.json | sed -E -e 's/[{} "]+//g' -e 's/.*embed_url:(.+)$/\1/' >> upload-results.txt
  sleep 1
done

cat upload-results.txt
