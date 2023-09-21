. debug.sh
. helpers.sh
geonode_upload_log=uploads.log

# if no arguments, then give info and prompt user for info
cat upload-intro.txt
if [ "$1" = "" ]; then
  echo
  read -p ' Do you want to read more detailed explanation of usage options/arguments? (y) ' zzz
  if [ "$zzz" = "y" ]; then
    cat upload-intro.txt upload-usage.txt | less
    echo
  fi
  echo
  read -p ' Are you ready to upload files? (any key to continue) ("n" or Ctrl+C to exit) ' zzz
  if [ "$zzz" = 'n' ]; then
    exit 0;
  fi
  echo
fi

echo_and_log ' Uploading'
geonode_upload_results_dir=''
# geonode_upload_results_dir will get set by uploader.sh
. uploader.sh
geonode_upload_main "$@"
if [ -s "$geonode_upload_results_dir/errors.log" ]; then
  echo ' there were errors in uploading... check uploads.log'
fi
echo_and_log ' ... done'

echo_and_log ' Fetching upload jobs'
. execution-request.sh
geonode_execution_jobs_get
echo_and_log '  ... done'

echo_and_log
echo_and_log ' Fetching datasets'
. dataset.sh
geonode_datasets_get
echo_and_log ' ... done'

echo_and_log
echo_and_log 'Uploaded Temp Dir with detailed logs: ' $geonode_upload_results_dir

echo_and_log
echo_and_log -n 'Uploaded Datasets: '
for geonode_upload_dataset_id in $(ls $geonode_upload_results_dir/dataset-*.json 2>/dev/null | sed -E -e 's/.+dataset-([0-9]+).json/\1/'); do
  echo_and_log 'Dataset ID:' $geonode_upload_dataset_id
  echo_and_log 'URL:' https://geo2.hyphae.design/catalogue/#/dataset/$geonode_upload_dataset_id
  grep -oE '"embed_url": *"[^"]+"' $geonode_upload_results_dir/dataset-$geonode_upload_dataset_id.json | sed -E -e 's/[{} "]+//g' -e 's/.*embed_url:(.+)$/\1/' > $geonode_upload_results_dir/dataset-$geonode_upload_dataset_id-embed-url.txt
  echo_and_log 'Embed URL:' $(cat $geonode_upload_results_dir/dataset-$geonode_upload_dataset_id-embed-url.txt)
  echo_and_log
  sleep .5
done

echo_and_log
echo " Upload done and all uploaded datasets info/errors is in uploads.log"
echo_and_log