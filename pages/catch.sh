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

rarity_table() {
  for file in "$FISH_ROOT"/fish-by-rarity2/*; do
    filename=${file##*/}
    cut "$file" -d' ' -f1 | awk '{ print "r["$1"]=\"'$filename'\";" }'
  done
}

ATTR='width=180 height=180'
RARITY_TABLE="$(rarity_table)"

fish_images() {
  awk -F, '
BEGIN {
'"$RARITY_TABLE"'
}
  {
    print "<div class=fishbig>";
    if ( $1 >= 5000 ) {
      print "<img src=\"https://stream.cgs.dev/fish/"tolower($2)".png\" loading=lazy '"$ATTR"' class=\""g" "r[$1]"\" />"
    } else {
      print "<img src=\"https://stream.cgs.dev/newfish/spr_fish_"$1"_x.png\" loading=lazy '"$ATTR"' class=\""r[$1]" newfish "g"\" />"
    }
    print "</div>";
}'
}

source fishutils.sh

catch_fish
echo "$fish_id,$fish" | fish_images
component /me/rod
