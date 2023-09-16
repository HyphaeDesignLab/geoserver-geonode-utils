
geonode_auth_client_credentials() {
  . .geonode.conf
  client_id_secret_concat_base64=$(python3 $client_id $client_secret)
  curl -k \
   -X POST \
   -d "grant_type=client_credentials" \
   -H "Authorization: Basic $client_id_secret_concat_base64" \
   https://geo2.hyphae.design/o/token/
}

geonode_auth_password() {
  local has_access_token=0
  geonode_auth_check_access_token_in_conf
  if [ "$?" = '0' ]; then
    has_access_token=1
    read -p 'Do you want to re-auth and get a new token? (y) ' zzz
    if [ "$zzz" != "y" ]; then
      return 0
    fi
  fi

  . .geonode.conf
  curl -k \
    -X POST \
    -d "grant_type=password&username=$user&password=$pass" \
    -u"$client_id:$client_secret" \
    https://geo2.hyphae.design/o/token/ > .access_token_response.txt 2>/dev/null
  # TEST: echo '{"access_token": "'$RANDOM'"}' > .access_token_response.txt
  grep -Eo 'access_token" *: *"([^"]+)' .access_token_response.txt > .access_token_match.txt 2>/dev/null
  if [ "$?" = "1" ]; then
    echo 'no access token in response: '
    cat .access_token_response.txt
  else
    if [ "$has_access_token" = '1' ]; then
      grep -v 'access_token=' .geonode.conf > .geonode.conf.tmp
      mv .geonode.conf.tmp .geonode.conf
    fi
    sed -E -e 's/access_token" *: *"/access_token=/' .access_token_match.txt >> .geonode.conf
  fi
  echo ' Access token was obtained!'
  rm .access_token_response.txt .access_token_match.txt 2>/dev/null
}

geonode_auth_check_access_token_in_conf() {
  # empty access token, should be replace (hence return 1 = the line exists in conf)
  grep -E 'access_token=.+$' .geonode.conf 2>/dev/null 1>/dev/null
  if [ "$?" = '1' ]; then
    echo 'access token does not exist'
    return 1
  fi

  # check non-empty access token
  grep -E 'access_token= *$' .geonode.conf 2>/dev/null 1>/dev/null
  # if match failed, then access_token is EMPTY
  if [ "$?" = '0' ]; then
    echo 'empty access token'
    return 1
  else
  # if exists, then echo to alert user the access token exists
    echo 'access_token already exists in .geonode.conf'
  fi
  return 0
}

geonode_auth() {
  echo
  echo ' Running API Auth to get an ACCESS TOKEN...'
  geonode_auth_password;
}

if [ "$1" = 'run' ]; then
 geonode_auth;
fi