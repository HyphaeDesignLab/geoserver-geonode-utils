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

geonode_upload_single_api_call() {
  . .geonode.conf

  local type="$1"

  # FINAL ARG-PARSER
  #  translates from <ext>=some/path/to/filename.<ext> to correct geonode API arguments
  #  Geonode expects
  #    'base_file=@some/path/file.shp' or .geojson or .tif
  #    'sld_file=@some/path/some_style_file.sld" (optional for styles)
  #    ...  for .shp files: .shx, dbf, prj, xml
  local args_i=0
  local args=()
  local args_orig=($@)
  # loop on 2nd (i=1) argument till end
  for fff in "${args_orig[@]:1}"; do
    local fff_slash_escaped=$(sed -E -e 's@/@\/@' <<< $fff)
    args[args_i]=$(sed -E -e "s/^$type=/base=/" -e 's/^([a-z]+)=(.+)$/-F "\1_file=@\2"/' <<< $fff_slash_escaped)
    ((args_i++))
  done

  eval "curl --location --request POST -k -H 'Authorization: Bearer $access_token' ${args[@]} 'https://geo2.hyphae.design/api/v2/uploads/upload' >>$geonode_upload_results_dir/upload.json 2>>$geonode_upload_results_dir/upload.log"
  echo >> $geonode_upload_results_dir/upload.json
  echo_if_verbose $geonode_verbose_mode " output saved to $geonode_upload_results_dir/upload.json, errors to $geonode_upload_results_dir/upload.json"
}

geonode_upload_single() {
  local file_path="$1"
  local file_type="$2"
  local zip_type="$3"
  local file_type_number='';
  # no args => all prompts from the command line
  if [ "$geonode_verbose_mode" = '1' ]; then
    read -p ' Which kind of data to you want to upload? SHP (1), GeoJSON (2), GeoTIF (3) ' file_type_number
    local next_prompt_message=''
    if [ "$file_type_number" = "1" ]; then
      echo ' enter the path for: SHP file (both .shp or .zip acceptable)'
      echo '  if .shp - all other requisite files like: SLD (style), SHX, DBF, PRJ, XML, '
      echo '   will be checked by script; they should be named the same file-name base'
      echo '   with the respecitve file extension: e.g. if SHP file is somefile.shp, then '
      echo '   the SLD file is somefile.sld'
      echo '  if .zip - all requisite files will be extracted from the zip archive'
      echo

      next_prompt_message=' enter file path (.shp or .zip): '
      file_type='shp'
    elif [ "$file_type_number" = "2" ]; then
      echo ' enter the path for: GeoJSON file (.geojson or .zip)'
      echo '  if .geojson, the style file (SLD) will be checked by script; it should be named the same file-name base'
      echo '   e.g. if GeoJSON file is somefile.geojson, then the SLD file is somefile.sld'
      echo '  if .zip - all requisite files will be extracted from the zip archive and inspected'
      echo
      next_prompt_message=' enter file path (.geojson or .zip): '
      file_type='geojson'
    elif [ "$file_type_number" = "3" ]; then
      echo ' enter the path for: Geo TIF file (.tif or .zip)'
      echo '  if .tif, the style file (SLD) will be checked by script; it should be named the same file-name base'
      echo '   e.g. if GeoJSON file is somefiletifgeojson, then the SLD file is somefile.sld'
      echo '  if .zip - all requisite files will be extracted from the zip archive'
      echo
      next_prompt_message=' enter file path (.tif or .zip): '
      file_type='tif'
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
      read -p " what kind of file/data is in the ZIP file archive $file_path? (shp, geojson, tif): " file_type
      if [ "$file_type" = "" ]; then
        echo " no file type given, skipping file $file_path"
        return 1;
      fi
    fi
    # ls the main file in unzipped archive
    file_path=$(ls -1 $unzipped_file_path/*.$file_type | head -1 | tr -d '\n')
  fi

  local requisite_files=()
  case $file_type in
    shp)
      requisite_files=(shp sld shx dbf prj xml)
      ;;
    geojson)
      requisite_files=(geojson sld)
      ;;
    tif)
      requisite_files=(tif sld)
      ;;
  esac

  local args=()
  local args_i=0
  file_path_and_basename_no_ext=$(echo $file_path | sed -E -e 's/\.[a-z]+$//')
  for ext in "${requisite_files[@]}"; do
    if [ -f $file_path_and_basename_no_ext.$ext ]; then
      args[args_i]="$ext=$file_path_and_basename_no_ext.$ext"
      ((args_i++))
    fi
  done

  # Run API calls to upload
  echo Uploading $file_type "${args[@]}" >>  geonode_upload.log
  sleep 1
  geonode_upload_single_api_call $file_type "${args[@]}"

  # Clean-up ZIP Archive
  if [ "$unzipped_file_path" != "" ] && [ -d "$unzipped_file_path" ]; then
    rm -rf $unzipped_file_path
  fi
}

geonode_verbose_mode=0
geonode_upload_results_dir=''
geonode_upload_main() {
  if [ "$1" = "" ]; then
    geonode_verbose_mode=1
    echo ' You can upload a single/multiple files/sets of files by'
    echo '  passing the director(ies) or file(s) paths as arguments'
    echo '  OR'
    echo '  getting prompted at the command line for each file/directory'
    echo
    echo ' If you choose to pass directories or file paths/names as command line arguments, then'
    echo '  you will get no prompts, and be able to run the script programmatically'
    echo
    echo ' Here is the style of directory/file path arguments to pass'
    echo '  upload.sh some/path/to/dir some/path/to/file.shp a/third/file.geojson'
    echo '            shp=some/other/file.zip '
    echo '            zip-type=shp|geojson|tif '
    echo '    if argument is a directory, then all files in the FIRST level of the directory '
    echo '     will be listed and uploaded as SEPARATE individual datasets'
    echo '    if argument is a file, then it will uploaded as a SINGLE dataset'
    echo
    echo '    if argument begins on a <type>=some/path/to/file.<ext>, then the dataset will be treated as'
    echo '      the <type> specified; e.g. shp=some/file;  this is useful to .zip archives containing a set of files'
    echo '      types allowed: geojson, shp, tif'
    echo
    echo '    if argument begins on a <type>=some/path/to/dir, then the all ZIP files in dir will be treated as'
    echo '      the <type> specified; types allowed: geojson, shp, tif'
    echo
    echo '    if argument is a ZIP file archive -OR- one/many of the files in the directory is a ZIP file archive, '
    echo '      it will be unzipped to a temporary location and its individual files uploaded as a SINGLE dataset'
    echo '      it helps to specify what the ZIP archive contains by prefixing it with "shp=some/archive.zip'
    echo
    echo '    if argument begins on "zip-type=<type>" then it will tell the script to treat ALL ZIP archives encountered as this type'
    echo
    echo '    if no "zip-type=<type>" is specified and the individual ZIP archive argument(s) has no type prefix (shp=some/file.zip)'
    echo '       then you will BE PROMPTED on the command line; YOU WILL NOT BE ABLE TO JUST RUN this PROGRAMMATICALLY; SCRIPT NEEDS YOUR INPUT to decide'
    echo '    '
    echo '    '
    echo '    for SHP file sets: you can specify just the SHP path/to/some_file.shp and script will '
    echo '       automatically look for the other files expected: SLD (style), SHX, PRJ, XML, DBF'
    echo '       they must be named the same and in the same directory:'
    echo '       e.g. if path/to/some_file.shp, then the SLD file must be path/to/some_file.sld'
    echo '       you can also specify the ZIP archive containing all of the files in the set'
    echo
    echo '    for GEOJSON and TIF file sets: you can specify just the .geojson/.tif file path '
    echo '       the script will automatically look for an SLD (style) file named the same and in the same directory:'
    echo '       e.g. if path/to/some_file.geojson, then the SLD file must be path/to/some_file.sld'
    echo '       you can also specify the ZIP archive containing all of the files in the set'
    echo '    '
  fi

  ### Make an upload dir to save results of API calls to for follow-up API calls
  geonode_upload_results_dir=$(mktemp)
  # remove actual file
  rm $geonode_upload_results_dir
  # make a directory with same name
  mkdir $geonode_upload_results_dir

  # Add current date
  date >>  geonode_upload.log
  # current upload folder
  echo $geonode_upload_results_dir >> geonode_upload.log
  echo >>  geonode_upload.log


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

      local ext=$(sed -nE -e '/\.([a-z]+)$/{s/^.+\.([a-z]+)$/\1/;p;}' <<< $arg);
      local path=$(sed -E -e 's/^[a-z\-]+=//' <<< $arg);

      if [ "$prefix" = "zip-type" ]; then
        # skip zip-type, already extracted above
        continue
      elif [ -d "$path" ]; then
        for fff in $(find $path -maxdepth 1 -type f \( -iname '*.shp' -or -iname '*.geojson' -or -iname '*.tif' -or -iname '*.zip' \) ); do
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
      elif [ "$ext" = 'zip' ] || [ "$ext" = 'ZIP' ]; then
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

  echo '------------------------' >>  geonode_upload.log
  echo >>  geonode_upload.log
}

# ecoreg/Oakland_ecoregion.shp