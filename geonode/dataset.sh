
# -------------------------------------------------------------------------------------------------
get_upload_job_count() {
  ls $geonode_upload_results_dir/upload-*.json 2>/dev/null | wc -l | tr -d ' \n'
}
test__get_upload_job_count() {
  geonode_upload_results_dir=$1
  echo -n ' get_upload_job_count: '
  local count=$(get_upload_job_count)
  local expected_count=$(cat $1/result__get_upload_job_count.txt)
  if [ "$count" = "$expected_count" ]; then
    echo ok
  else
    echo " FAILED: $count JOBs found, but $expected_count expected"
  fi
}


# -------------------------------------------------------------------------------------------------
get_dataset_url_count() {
  grep -E '/catalogue/#/dataset/[0-9]+' $geonode_upload_results_dir/upload-*.json 2>/dev/null | wc -l | tr -d ' \n'
}

test__get_dataset_url_count() {
  geonode_upload_results_dir=$1
  echo -n ' get_dataset_url_count: '
  local count=$(get_dataset_url_count)
  local expected_count=$(cat $1/result__get_dataset_url_count.txt)
  if [ "$count" = "$expected_count" ]; then
    echo ok
  else
    echo "FAILED: $count dataset URLs found, but $expected_count expected"
  fi
}


# -------------------------------------------------------------------------------------------------
geonode_dataset_get_api_call() {
  . .geonode.conf
  curl -k -X 'GET' \
    -H "Authorization: Bearer $access_token" \
    -H 'accept: application/json' \
    "https://geo2.hyphae.design/api/v2/datasets/$1/"
}
geonode_dataset_get_all_api_call() {
  . .geonode.conf
  curl -k -X 'GET' \
    -H "Authorization: Bearer $access_token" \
    -H 'accept: application/json' \
    "https://geo2.hyphae.design/api/v2/datasets/?page=1&page_size=$1"
}


# -------------------------------------------------------------------------------------------------
geonode_uploaded_datasets_get() {
  # for every execution job ID, get the full dataset info
  #     (grep -h = no file name)
  echo_if_debug 'datasets/get dir+file: ' $geonode_upload_results_dir/upload-*.json
  local dataset_ids=( $(grep -hoE '/catalogue/#/dataset/[0-9]+' $geonode_upload_results_dir/upload-*.json 2>/dev/null | sed -e 's@/catalogue/#/dataset/@@'))
  for dataset_id in "${dataset_ids[@]}"; do
    # run the datasets/get API, save to <upload_dir>/dataset-<id>.json
    geonode_dataset_get_api_call $dataset_id >$geonode_upload_results_dir/dataset-$dataset_id.json 2>>$geonode_upload_results_dir/dataset-$dataset_id.log
    sleep .5
  done

  # if dataset known URLs are less than the upload jobs, then fetch all N latest datasets
  local dataset_count_to_request=$(datasets_get_all__count_to_request $(get_upload_job_count) $(get_dataset_url_count));
  if [ "$dataset_count_to_request" -gt 0 ]; then
    geonode_dataset_get_all_api_call $dataset_count_to_request > $geonode_upload_results_dir/datasets.json 2>$geonode_upload_results_dir/datasets.log
    echo_and_log " Some datasets IDs might not have been shown in above. Here are the last $dataset_count_to_request datasets uploaded: "
    grep -oE '"(uuid|name|detail_url|embed_url)":"[^"]+"' $geonode_upload_results_dir/datasets.json | \
        sed -E -e '/^"uuid/{s/"uuid.+//;N;s/\n/~/;}' -e '/^"name/d' -e 's/["~]//g;s/:/: /'
  fi

  unset dataset_id
  echo >> uploads.log
}

# -------------------------------------------------------------------------------------------------
datasets_get_all__count_to_request() {
  local upload_job_count=$1
  local dataset_known_url_count=$2
  local dataset_count_to_request=0
  if [ "$upload_job_count" -gt "$dataset_known_url_count" ]; then
    dataset_count_to_request=2
    if [ "$upload_job_count" -gt 1 ]; then
      dataset_count_to_request=$(expr $upload_job_count \* 150 / 100 )  # add 50% more to count (i.e. make it 150%)
    fi
  fi
  echo $dataset_count_to_request
}
test__datasets_get_all__count_to_request() {
  echo -n 'Testing datasets_get_all count_to_request: '
  local status_string='';
  local expected='0';

  expected=0 && actual=$(datasets_get_all__count_to_request 1 1);
  if [ "$actual" = "$expected" ]; then status_string='ok'; else status_string='FAILED:'; fi; echo "$status_string:  actual=$actual, expected=$expected";

  expected=0 && actual=$(datasets_get_all__count_to_request 2 2);
  if [ "$actual" = "$expected" ]; then status_string='ok'; else status_string='FAILED:'; fi; echo "$status_string:  actual=$actual, expected=$expected";

  expected=2 && actual=$(datasets_get_all__count_to_request 1 0);
  if [ "$actual" = "$expected" ]; then status_string='ok'; else status_string='FAILED:'; fi; echo "$status_string:  actual=$actual, expected=$expected";

  expected=3 && actual=$(datasets_get_all__count_to_request 2 1);
  if [ "$actual" = "$expected" ]; then status_string='ok'; else status_string='FAILED:'; fi; echo "$status_string:  actual=$actual, expected=$expected";


  expected=4 && actual=$(datasets_get_all__count_to_request 3 1);
  if [ "$actual" = "$expected" ]; then status_string='ok'; else status_string='FAILED:'; fi; echo "$status_string:  actual=$actual, expected=$expected";

  expected=4 && actual=$(datasets_get_all__count_to_request 3 2);
  if [ "$actual" = "$expected" ]; then status_string='ok'; else status_string='FAILED:'; fi; echo "$status_string:  actual=$actual, expected=$expected";

  expected=6 && actual=$(datasets_get_all__count_to_request 4 3);
  if [ "$actual" = "$expected" ]; then status_string='ok'; else status_string='FAILED:'; fi; echo "$status_string:  actual=$actual, expected=$expected";
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
_test() {
  _test_single get_dataset_url_count dataset__get_upload_job_count;
  _test_single get_upload_job_count dataset__get_upload_job_count;
  _test_single datasets_get_all__count_to_request
}
_test_single() {
  local fn_name=$1
  local test_dir=$2
  local d=''
  if [ "$test_dir" != '' ] && [ -d tests/${test_dir} ]; then
    for d in $(find tests/${test_dir} -mindepth 1 -type d); do
      echo "Testing $fn_name with $test_dir test data: "
      test__${fn_name} $d
    done
  else
    local args=($@)
    test__${fn_name} ${args[@]:1}
  fi
}
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------




if [ "$1" = 'run' ]; then
  geonode_dataset_get $1;
elif [ "$1" = 'test' ]; then
  if [ "$2" = '' ]; then
    _test;
  else
    _test_single $2 $3 $4 $5 $6 $7 $8
  fi
fi;