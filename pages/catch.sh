if [[ "$REQUEST_METHOD" != "POST" ]]; then
  # only allow POST to this endpoint
  return $(status_code 405)
fi

USER_ID="${SESSION[id]}"
USER_NAME="${SESSION[username]}"

if [[ -z "$USER_ID" ]]; then
  return $(status_code 403)
fi

STATUS="$(cat "$FISH_ROOT/status")"
if [[ "$STATUS" == "OFFLINE" ]]; then
  echo "no offline fishing, sorry"
  return $(status_code 200)
elif [[ "$STATUS" != "ONLINE" ]]; then
  echo "can't fish because of $STATUS"
  return $(status_code 200)
fi

source fishutils.sh

catch_fish
