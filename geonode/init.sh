geonode_conf_sample_file() {
  echo ' here is a sample .geonode.conf file: '
  echo '   # Geonode credentials (likely in 1p)'
  echo '   user=someUserName'
  echo '   pass=aStrongPassword'
  echo
  echo '   # Application details from: https://geo2.hyphae.design/en-us/admin/oauth2_provider/application/'
  echo '    # pick an existing application of "grant type: Resource owner password-based" for the internal Geonode ID of the user (above)'
  echo '    #  OR '
  echo '    # create a new one application:'
  echo '     #  the application user has to match the internal Geonode ID of the user above'
  echo '     #  client type: confidential'
  echo '     #  authorization grant type: Resource owner password-based'
  echo '     #  name: something memorable'
  echo '     #  skip auhtorization: True'
  echo '     #  algorithm: RSA'
  echo '   client_id=clientId'
  echo '   client_secret=clientSecret'
  echo
  echo '   # Access Token'
  echo '    #  note: auto-filled from auth step later on OR '
  echo '     #       manually entered/picked from the list of access tokens in:'
  echo '     #         https://geo2.hyphae.design/en-us/admin/oauth2_provider/accesstoken/'
  echo '   access_token=<to be auto/manually filled>'
}
zz_clear_line() {
  printf "\r%*s\r" "$(tput cols)" " "
}
geonode_conf_create_or_update() {
  if [ ! -f .geonode.conf ]; then
    echo ' Creating .genode.conf'
    echo -n > .geonode.conf
  else
    echo ' Editing .genode.conf'
  fi
  echo -n > .geonode.new.conf

  for prop in user pass client_id client_secret access_token; do
    value_new=""
    value_original="$(grep "$prop=" .geonode.conf | sed -e "s/$prop=//" 2>/dev/null)"
    while [ "$value_new" = "" ]; do
      echo
      if [ "$prop" = 'access_token' ]; then
          echo " you do not need to enter 'access_token'; if blank it will be filled out automatically for you"
      fi
      if [ "$value_original" != "" ]; then
        read -p " enter \"$prop\" (or leave blank to use original value \"$value_original\"):" value_new
        break
      else
        read -p " enter \"$prop\": " value_new
      fi

      if [ "$value_new" = "" ]; then
        if [ "$prop" = 'access_token' ]; then
          echo " you entered a blank access_token; it will be filled out automatically for you"
          break
        else
          echo " you entered a blank $prop, try again"
          continue
        fi
      fi
    done
    if [ "$value_new" != "" ]; then
      echo " you entered: $prop=$value_new"
      echo "$prop=$value_new" >> .geonode.new.conf
    else
      echo " no change to existing value: $prop=$value_original"
      echo "$prop=$value_original" >> .geonode.new.conf
    fi
  done
  echo
  echo
  echo ' Here is the final conf file contents: '
  echo
  cat .geonode.new.conf
  echo
  read -p '  Do you accept the udpates (if any)? (y)' zzz
  if [ "$zzz" =  'y' ]; then
    mv .geonode.new.conf .geonode.conf
  fi
}

echo
echo ' initializing...'
if [ ! -f .geonode.conf ]; then
  echo ' .geonode.conf does not exist'
  geonode_conf_sample_file
  geonode_conf_create_or_update
else
  read -p ' Do you want to edit the config file (.geonode.conf) ? (y)' zzz
  if [ "$zzz" = "y" ]; then
    geonode_conf_create_or_update
  fi
fi
. auth.sh run