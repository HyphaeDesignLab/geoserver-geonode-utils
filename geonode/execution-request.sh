geonode_execution_get_api_call() {
  . .geonode.conf
  curl -k -X 'GET' \
    -H "Authorization: Bearer $access_token" \
    -H 'accept: application/json' \
    "https://geo2.hyphae.design/api/v2/executionrequest/$1/"
}

geonode_execution_jobs_get() {
  echo -n 'upload execution job IDs: ' >>uploads.log
  # for every upload, get the upload execution job ID
  #   (i.e. loop on every line in <upload_dir>/upload.json)
  for geonode_execution_id in $(sed -E -e 's/[{} "]+//g' -e 's/.*execution_id:(.+)$/\1/' $geonode_upload_results_dir/upload.json 2>/dev/null); do
    # run the execution_job/get API, and save to <upload_dir>/upload-<execution_job_id>.json
    geonode_execution_get_api_call $geonode_execution_id >$geonode_upload_results_dir/upload-$geonode_execution_id.json 2>$geonode_upload_results_dir/upload-$geonode_execution_id.log
    if [ ! -s $geonode_upload_results_dir/upload-$geonode_execution_id.json ]; then
      echo ' empty execution request response'
      echo ' empty execution request response' >> uploads.log
    fi
    grep not_authenticated $geonode_upload_results_dir/upload-$geonode_execution_id.json >/dev/null 2>/dev/null
    if [ "$?" = "0" ]; then
      echo ' API auth failed'
      echo ' API auth failed' >> uploads.log
    fi

    grep -E '"status":' $geonode_upload_results_dir/upload-$geonode_execution_id.json >/dev/null 2>/dev/null
    if [ "$?" = "1" ]; then
      echo ' upload job is missing its status'
      echo ' upload job is missing its status' >> uploads.log
    fi
    grep -E '"status": *"running"' $geonode_upload_results_dir/upload-$geonode_execution_id.json >/dev/null 2>/dev/null
    if [ "$?" = "0" ]; then
      echo ' upload job is still processing, will wait until a dataset for the upload exists'
      local is_job_complete=0
      while [ "$is_job_complete" = "0" ]; do
        sleep 2
        geonode_execution_get_api_call $geonode_execution_id >$geonode_upload_results_dir/upload-$geonode_execution_id.json 2>$geonode_upload_results_dir/upload-$geonode_execution_id.log
        grep -E '"status": *"finished"' $geonode_upload_results_dir/upload-$geonode_execution_id.json >/dev/null 2>/dev/null
        if [ "$?" = "0" ]; then
           is_job_complete=1
        fi
      done
    fi
    echo -n $geonode_execution_id ' ~ ' >>uploads.log
    sleep .5
  done
  unset geonode_execution_id
  echo >>uploads.log
}

if [ "$1" = 'run' ]; then
  geonode_execution_request_get $1;
fi;