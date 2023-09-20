geonode_upload_log=uploads.log
# echo to STDOUT and to LOG
#  if LOG path is empty, then just ECHO to STDOUT
#  echo all args passed to
echo_and_log() {
  if [ "$geonode_upload_log" = '' ]; then
    echo $@
    return 0;
  fi
  local args_=($@)
  echo ${args_[@]};
  echo ${args_[@]} >> $geonode_upload_log;
}

# if first arg is DEBUG
if [ "$1" = 'debug' ]; then
  # and the script is called by itself (compare the filename without directory path to expected value
  _self_script_name=$(which $0 | sed -E -e 's@^.*/@@')
  if [ "$_self_script_name" = 'helpers.sh' ]; then
    if [ "$2" = 'no_log' ]; then
      geonode_upload_log=''
    else
      geonode_upload_log=$2
    fi
    echo_and_log $3 $4 $5 $6
  fi;
fi