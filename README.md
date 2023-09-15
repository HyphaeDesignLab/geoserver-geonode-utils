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
