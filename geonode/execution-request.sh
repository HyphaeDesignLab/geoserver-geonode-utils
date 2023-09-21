. debug.sh
. helpers.sh

geonode_execution_get_api_call() {
  . .geonode.conf
  curl -k -X 'GET' \
    -H "Authorization: Bearer $access_token" \
    -H 'accept: application/json' \
    "https://geo2.hyphae.design/api/v2/executionrequest/$1/"
}

_helper_get_error_from_response() {
  #echo_if_debug 'helper: get error' $1
  grep -Eo '"output_params":\{"errors":\["[^"]+' $1 | sed -E -e 's/"output_params":\{"errors":\["//'
}
_helper_get_status_from_response() {
  #echo_if_debug 'helper: get status' $1
  grep -oE '"status": *"[^"]+"' $1 2>/dev/null | sed -E -e 's/[" ]//g;s/status://'
}
geonode_execution_jobs_get() {
  echo_and_log -n 'upload execution job IDs: '
  # for every upload, get the upload execution job ID
  #   (i.e. loop on every line in <upload_dir>/upload.json)
  for geonode_execution_id in $(sed -E -e 's/[{} "]+//g' -e 's/.*execution_id:(.+)$/\1/' $geonode_upload_results_dir/upload.json 2>/dev/null); do
    echo $geonode_execution_id
    # run the execution_job/get API, and save to <upload_dir>/upload-<execution_job_id>.json
    geonode_execution_get_api_call $geonode_execution_id >$geonode_upload_results_dir/upload-$geonode_execution_id.json 2>$geonode_upload_results_dir/upload-$geonode_execution_id.log
    if [ ! -s $geonode_upload_results_dir/upload-$geonode_execution_id.json ]; then
      echo_and_log ' empty execution request response'
    fi
    grep not_authenticated $geonode_upload_results_dir/upload-$geonode_execution_id.json >/dev/null 2>/dev/null
    if [ "$?" = "0" ]; then
      echo_and_log && echo_and_log ' API auth failed'
    fi

    grep -E '"status":' $geonode_upload_results_dir/upload-$geonode_execution_id.json >/dev/null 2>/dev/null
    if [ "$?" = "1" ]; then
      echo_and_log ' error: upload job is missing its status'
      cat $geonode_upload_results_dir/upload-$geonode_execution_id.json
      return 1
    fi

    local job_status=$(_helper_get_status_from_response $geonode_upload_results_dir/upload-$geonode_execution_id.json)
    echo_if_debug "execution job get: $geonode_execution_id: status=$job_status"
    local is_job_complete=''
    if [ "$job_status" = 'finished' ]; then
      echo ' upload job is done';
      is_job_complete=1
    elif [ "$job_status" = 'running' ]; then
      echo ' upload job is still processing, will wait until a dataset for the upload exists'
      is_job_complete=0
    elif [ "$job_status" = 'failed' ]; then
      echo -n " upload job ($geonode_execution_id) failed: "
      _helper_get_error_from_response $geonode_upload_results_dir/upload-$geonode_execution_id.json
      return 1
    else
      echo -n " upload job ($geonode_execution_id) status is UNEXPECTED. here is the job details: "
      cat $geonode_upload_results_dir/upload-$geonode_execution_id.json
      return 1
    fi

    while [ "$is_job_complete" = "0" ]; do
      echo '...fetching execution job...'
      sleep 1
      geonode_execution_get_api_call $geonode_execution_id >$geonode_upload_results_dir/upload-$geonode_execution_id.json 2>$geonode_upload_results_dir/upload-$geonode_execution_id.log
      job_status=$(_helper_get_status_from_response $geonode_upload_results_dir/upload-$geonode_execution_id.json)
      if [ "$job_status" = "running" ]; then
        is_job_complete=0
      elif [ "$job_status" = "finished" ]; then
        is_job_complete=1
        echo ' upload job is done'
      elif [ "$job_status" = 'failed' ]; then
        echo -n " upload job ($geonode_execution_id) failed: "
        _helper_get_error_from_response $geonode_upload_results_dir/upload-$geonode_execution_id.json
        return 1
      else
        echo -n " upload job ($geonode_execution_id) status is UNEXPECTED. here is the job details: "
        cat $geonode_upload_results_dir/upload-$geonode_execution_id.json
        return 1
      fi
    done
    echo_and_log $geonode_execution_id
    sleep .5
  done
  unset geonode_execution_id
  echo >> $geonode_upload_log
  return 0
}

if [ "$1" = 'run' ]; then
  geonode_execution_request_get $1;
elif [ "$1" = 'debug' ]; then
  # if debug AND self-called (check self-script name, without directory path)
  _self_script_name=$(which $0 | sed -E -e 's@^.*/@@')
  if [ "$_self_script_name" = 'execution-request.sh' ]; then
    geonode_upload_log=''
    # run whatever is defined by $2 (as a function name) and $3, $4... as arguments to it
    eval "$2 $3 $4 $5"
  fi;
fi;