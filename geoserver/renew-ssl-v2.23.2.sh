geoserver_2_23_ssl_renew() {
  local is_debug="$GEOSERVER_SSL_RENEW_DEBUG"

  local cert_lifetime_days=60
  # can be overridden by the argument 1
  if [ "$1" ]; then
    cert_lifetime_days=$1
  fi

  local cert_lifetime_seconds=$(expr 3600 \* 24 \* $cert_lifetime_days)

  local cert_lastmod_time=$(sudo stat -c%Y /etc/letsencrypt/live/geo.hyphae.design/cert.pem)
  local cert_expiration_time=$(expr $cert_lastmod_time + $cert_lifetime_seconds)

  local now=$(date +%s)

  echo && echo
  date && echo

  echo "Cert Lifetime: $cert_lifetime_days days";
  echo "Cert Lifetime: $cert_lifetime_seconds seconds";
  echo "Cert last modified: $cert_lastmod_time";
  echo "Cert expiration time (calculated): $cert_expiration_time";
  echo "Time left till renewal: $(expr \( $now - $cert_expiration_time \) / \( 24 \* 3600 \) + 1) days"

  if [ $now -gt $cert_expiration_time ]; then
    if [ "$is_debug" ]; then
      echo 'stop geoserver tomcat'
      echo sudo /opt/tomcat/bin/shutdown.sh
      ls /opt/tomcat/bin/shutdown.sh
      sudo certbot renew --cert-name geo.hyphae.design --force-renew --standalone --dry-run
      local filename;
      for filename in cert.pem chain.pem fullchain.pem privkey.pem; do
        sudo ls /etc/letsencrypt/live/geo.hyphae.design/$filename /opt/tomcat/conf/$filename
      done;
      echo 'start geoserver tomcat'
      echo sudo /usr/bin/authbind --deep /opt/tomcat/bin/startup.sh
      ls /usr/bin/authbind /opt/tomcat/bin/startup.sh
    else
      echo 'stop geoserver tomcat'
      sudo /opt/tomcat/bin/shutdown.sh
      sudo certbot renew --cert-name geo.hyphae.design --force-renew --standalone
      local filename;
      for filename in cert.pem chain.pem fullchain.pem privkey.pem; do
        sudo cp -v /etc/letsencrypt/live/geo.hyphae.design/$filename /opt/tomcat/conf/$filename
      done;
      echo 'start geoserver tomcat'
      sudo /usr/bin/authbind --deep /opt/tomcat/bin/startup.sh
    fi
  else
    echo "Cert is not expiring soon... all done"
  fi

}
geoserver_2_23_ssl_renew $1;