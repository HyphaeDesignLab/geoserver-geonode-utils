echo_if_debug() {
  if [ "$HYPHAE_GEONODE_UPLOADER_DEBUG" = 1 ]; then
    local args123=($@);
    echo "debug: ${args123[@]}"
  fi
}
