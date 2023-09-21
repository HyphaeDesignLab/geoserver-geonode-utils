geonode_verbose_mode=0
geonode_upload_results_dir=''

echo_if_verbose() {
  if [ $1 = 1 ]; then
    local args=($@);
    echo ${args[@]:1};
  fi
}

unzip_files_and_ls() {
  # make a temp file and save file name to variable
  local tmp_file_dir=$(mktemp)
  # remove actual file
  rm $tmp_file_dir
  # make a directory with same name
  mkdir $tmp_file_dir
  # unzip: -d (to directory) -o (overwrite files) -q (quiet)
  unzip -oq -d $tmp_file_dir $1

  echo $tmp_file_dir
}

geonode_api_auth_test() {
  . .geonode.conf
  echo > auth-test.json
  curl --location --request GET -k -H "Authorization: Bearer $access_token" 'https://geo2.hyphae.design/api/v2/users' > auth-test.json 2>/dev/null
  grep not_authenticated auth-test.json >/dev/null 2>/dev/null
  if [ "$?" = "0" ]; then
    echo ' API authentication failed. Please request another API access token via "auth.sh run"'
    rm auth-test.json
    return 1
  fi
  rm auth-test.json
  return 0
}
geonode_upload_single_api_call() {
  . .geonode.conf

  local type="$1"

  # FINAL ARG-PARSER
  #  translates from <ext>=some/path/to/filename.<ext> to correct geonode API arguments
  #  Geonode expects
  #    'base_file=@some/path/file.shp' or .geojson ... or... the_main_file.<type>
  #    'sld_file=@some/path/some_style_file.sld" (optional for styles) for .geojson, .tif, .shp
  #    'shx_file=@...', etc: .shx, dbf, prj, xml for .shp files
  #    ... .aux, .sid.aux.xml, .xml, .sdw, .txt for .sid files
  local args_i=0
  local args=()
  local args_orig=($@)

  echo_if_debug "single api call: upload start:" ${args_orig[@]}

  # loop on 2nd (i=1) argument till end
  for fff in "${args_orig[@]:1}"; do
    local fff_slash_escaped=$(sed -E -e 's@/@\/@' <<< $fff)
    args[args_i]=$(sed -E -e "s/^$type=/base=/" -e 's/^([a-z]+)=(.+)$/-F "\1_file=@\2"/' <<< $fff_slash_escaped)
    ((args_i++))
  done

  eval "curl --location --request POST -k -H 'Authorization: Bearer $access_token' ${args[@]} 'https://geo2.hyphae.design/api/v2/uploads/upload' >>$geonode_upload_results_dir/_upload.json 2>>$geonode_upload_results_dir/upload.log"
  if grep '"success":false' $geonode_upload_results_dir/_upload.json >/dev/null 2>/dev/null; then
    grep -oE '"errors":\[[^]]+' $geonode_upload_results_dir/_upload.json | sed -e 's/"errors"://;s/\[//;' > $geonode_upload_results_dir/errors.log
  else
    cat $geonode_upload_results_dir/_upload.json >> $geonode_upload_results_dir/upload.json
    echo >> $geonode_upload_results_dir/upload.json
  fi
  rm $geonode_upload_results_dir/_upload.json
  echo_if_verbose $geonode_verbose_mode " output saved to $geonode_upload_results_dir/upload.json, errors to $geonode_upload_results_dir/upload.json"
}

geonode_upload_single() {
  local file_path="$1"
  local file_type="$2"
  local zip_type="$3"
  local file_type_number='';

  echo_if_debug "upload single: file_path=$file_path file_type=$file_type zip_type=$zip_type"

  local matcing_extensions=''
  # no args => all prompts from the command line
  if [ "$geonode_verbose_mode" = '1' ]; then
    read -p ' Which kind of data to you want to upload? SHP (1), GeoJSON (2), GeoTIF (3), GPKG (4) (.zip archives allowed), MrSID (5): ' file_type_number
    local next_prompt_message=''
    if [ "$file_type_number" = "1" ]; then
      next_prompt_message=' enter the path for SHP file (both .shp or .zip acceptable) (.shp or .zip): '
      file_type='shp'
      matcing_extensions='shp'
    elif [ "$file_type_number" = "2" ]; then
      next_prompt_message=' enter the path for: GeoJSON file (.geojson or .zip): '
      file_type='geojson'
      matcing_extensions='geojson|json'
    elif [ "$file_type_number" = "3" ]; then
      next_prompt_message=' enter the path for: Geo TIF file (.tif or .zip): '
      file_type='tif'
      matcing_extensions='tif|gtif|tiff'
    elif [ "$file_type_number" = "4" ]; then
      next_prompt_message='  enter the path for Geo Package file (.gpkg): '
      file_type='gpkg'
      matcing_extensions='gpkg'
    elif [ "$file_type_number" = "5" ]; then
      next_prompt_message='  enter the path for MrSID file (.sid or .zip): '
      file_type='sid'
      matcing_extensions='sid'
    else
      echo ' incorrect file type chosen'
      return 1
    fi

    read -p "$next_prompt_message" file_path
  fi

  local unzipped_file_path=''
  if [[ "$file_path" = *'.zip'* ]]; then
    unzipped_file_path=$(unzip_files_and_ls $file_path);
    if [ "$file_type" = "" ]; then
      read -p " what kind of file/data is in the ZIP file archive $file_path? (shp, geojson/json, tif/tiff/gtif, gpkg): " file_type
      if [ "$file_type" = "" ]; then
        echo " no file type given, skipping file $file_path"
        return 1;
      fi
    fi
    # ls the main file in unzipped archive
    file_path=$(find $unzipped_file_path/ -type f | grep -iE "\.($matcing_extensions)\$"| head -1 | tr -d '\n')
  fi

  if [ ! -f $file_path ] || [ ! -s $file_path ]; then
    echo_if_debug "debug: file upload empty or not exist: $file_path"
    echo " file upload does not exist or is empty $file_path" >> $geonode_upload_results_dir/errors.log
    echo " file upload does not exist or is empty $file_path" >> uploads.log
    return 1
  fi

  local requisite_files=()
  case $file_type in
    shp)
      requisite_files=(sld shx dbf prj xml)
      ;;
    geojson)
      requisite_files=(sld)
      ;;
    tif)
      requisite_files=(sld)
      ;;
    sid)
      requisite_files=(aux sid.aux.xml xml sdw txt)
      ;;
  esac

  # default first arg is the base file itself
  local args=("-f $file_type=$file_path")
  local args_i=1 # start index at 1
  echo_if_debug "upload single: requisite=$file_path file_type=$file_type zip_type=$zip_type"
  file_path_and_basename_no_ext=$(echo $file_path | sed -E -e 's/\.[a-z]+$//')
  for ext in "${requisite_files[@]}"; do
    if [ -f $file_path_and_basename_no_ext.$ext ]; then
      args[args_i]="$ext=$file_path_and_basename_no_ext.$ext"
      ((args_i++))
    fi
  done

  # Run API calls to upload
  echo_and_log "Uploading $file_type" "${args[@]}"
  geonode_upload_single_api_call $file_type "${args[@]}"
  sleep 1

  # Clean-up ZIP Archive
  if [ "$unzipped_file_path" != "" ] && [ -d "$unzipped_file_path" ]; then
    rm -rf $unzipped_file_path
  fi
}

geonode_upload_main() {
  if [ "$1" = "" ]; then
    geonode_verbose_mode=1
  fi

  geonode_api_auth_test
  if [ "$?" = '1' ]; then
    return
  fi

  ### Make an upload dir to save results of API calls to for follow-up API calls
  geonode_upload_results_dir=uploads/$(date +%Y-%m-%d---%H-%M-%S)
  # make a directory
  mkdir -p $geonode_upload_results_dir

  echo '------------------------' >>  uploads.log
  # Add current date
  date >>  uploads.log
  # current upload folder
  echo 'Upload dir: ' $geonode_upload_results_dir >> uploads.log
  echo >>  uploads.log


  ###
  # (no args) Prompt for file paths/names on command line
  if [ "$geonode_verbose_mode" = "1" ]; then
    local more_files=y;
    while [ "$more_files" = "y" ]; do
      geonode_upload_single;
      read -p ' Upload another file (set)? (y) ' more_files
    done

  # all upload data is in the arguments (no prompts, except if ZIP TYPE argument is not there and there are ZIP files)
  else
    local args_i=0;
    # get zip-type prefixed argument ahead of time
    local zip_type=$(echo "$@" | sed -nE -e '/zip-type=[a-z]+/{s/^.*zip-type=([a-z]+)($| .*)/\1/;p;}')
    # loop on all args
    for arg in "$@"; do
      local prefix=$(sed -nE -e '/^[a-z\-]+=/{s/^([a-z\-]+).+/\1/;p;}' <<< $arg);

      # extract file extension and replace alternate extensions with standard one; make lower case
      local ext=$(sed -nE -e '/\.([a-z]+)$/{s/^.+\.([A-Za-z]+)$/\1/;p;}' <<< $arg | tr 'A-Z' 'a-z' | sed -E -e 's/^(gtif|tiff)$/tif/;s/^json$/geojson/');

      echo_if_debug "upload main (args loop): $ext $arg";
      local path=$(sed -E -e 's/^[a-z\-]+=//' <<< $arg);

      if [ "$prefix" = "zip-type" ]; then
        # skip zip-type, already extracted above
        continue
      elif [ -d "$path" ]; then
        for fff in $(find $path -maxdepth 1 -type f -name '*.*' | grep -E '\.(shp|g?tiff?|(geo)?json|gpkg|sid|zip)$' ); do
          local ext_i=$(sed -E -e 's/.+\.([a-z]+)/\1/' <<< $fff);
          if [ "$ext_i" = 'zip' ] || [ "$ext_i" = 'ZIP' ]; then
            local zip_type_i="$zip_type"
            if [ "$prefix" != "" ]; then
              zip_type_i="$prefix"
            fi
            geonode_upload_single $fff $zip_type_i;
          else
            geonode_upload_single $fff $ext_i;
          fi
        done
      elif [ "$ext" = 'zip' ]; then
        local zip_type_i="$zip_type"
        if [ "$prefix" != "" ]; then
          zip_type_i="$prefix"
        fi
        geonode_upload_single $path $zip_type_i;
      else
        # if blank ext (somehow?!)
        if [ "$ext" = "" ]; then
          # if extension is BLANK, skip file (cannot assume anything about it)
          echo " file $path has no extension in the command line"
          continue
        else
          geonode_upload_single $path $ext
        fi
      fi
    done
  fi

  echo >>  uploads.log
}

geonode_api_auth_test