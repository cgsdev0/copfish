
HOST=${HTTP_HEADERS["host"]}
PROTOCOL="https://"
if [[ "$HOST" =~ "localhost"* ]]; then
  PROTOCOL="http://"
fi
SEARCH="${FORM_DATA[search]##-*}"
if [[ -z "$SEARCH" ]]; then
  return
fi
sed "s/^/--/;s/ /\n/" < "$FISH_ROOT/data/username_cache" \
  | grep -iF --no-group-separator -B1 -- "$SEARCH" \
  | paste -sd" \n" \
  | grep "^--.* " \
  | sed "s/^--//" \
  | head -n 10 \
  | awk '{ printf "<a href=%s/profile/%s>%s</a>\n",
    "'$PROTOCOL$HOST'",
    $1, $2; }'
