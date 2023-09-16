# Geonode Geoserver Utils

Utility scripts written and used by Hyphae Design Lab

*Contributors*: Ivan Velev (ivanski@hyphae.net)

## Geonode Utils

All scripts live in `geonode/` directory

Run `init.sh` to be prompted to create a configuration file (`.geonode.conf`) and given an
example of a configuration file. If you prefer to copy-paste the example code and manually 
edit/compose the file, then cancel out of the script and paste the example code into `.geonode.conf`. 
Else, you will be prompted for every allowed property in the configuration file.

If you run `init.sh`, after a `.geonode.conf` already exists, you will be prompted to edit the 
file properties, one by one; and you will be asked if you want to keep the final edits.  

The access token property can be filled out by hand or it will be auto-filled by `auth.sh` (below)


### Auth

Auth will automatically run after `init.sh` completes.

Auth can be run by hand like this: `auth.sh run` 

It will prompt you to enter OAuth application client ID and secret. The application must be  
of grant type "Resource owner password-based". It will fetch the access token and 
save it to `.geonode.conf`

### Uploader 

Run `upload.sh` and follow prompts.  You will be given instructions. 

You can run this entirely interactively (waiting for prompts from the script)

OR 

You can list a directory, a file, or both, or multiple of both as arguments and 
the script will upload all files of type .shp, .geojson, .tif as individual datasets.
Zip archives will be auto-unzipped and its contents will be uploaded according to the same rules.

Script will complain if the AUTH access token expires or is missing. It will ask you to re-run `auth.sh run`

#### Output of Uploader

Once uploaded all dataset(s) info is saved to *`uploads.log`*. The log file will presist and keep 
getting appended more info to it from subsequent uploads. No information can get lost.

The data saved to `uploads.log` is dataset ID, dataset URL and dataset Embed URL