if [[ "$REQUEST_METHOD" != "POST" && -z "$INTERNAL_REQUEST" ]]; then
  # only allow POST to this endpoint
  return $(status_code 405)
fi

USER_ID="${SESSION[id]}"
USER_NAME="${SESSION[username]}"
CAPTCHA="${QUERY_PARAMS[captcha]}"

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

LICENSE="$(cat "$FISH_ROOT/license")"
USER_LICENSE="${SESSION[license]}"
# if [[ "$LICENSE" != "$USER_LICENSE" ]]; then
# cat <<EOF
# Your fishing license is expired! You can find a new one on the screen on stream
# <form class="flex gap-1">
# <input name="license" type="text" placeholder="Enter new license">
# <button hx-post="/license" hx-target="#result">Submit</button>
# </form>
# EOF
#   return $(status_code 200)
# fi

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
    print "<div class=\"fishbig flex justify-center\">";
    if ( $1 >= 5000 ) {
      printf "%s", "<img src=\"https://stream.cgs.dev/fish/"tolower($2)".png\" loading=lazy '"$ATTR"' class=\""g" "r[$1]"\" />"
    } else {
      print "<img src=\"https://stream.cgs.dev/newfish/spr_fish_"$1"_x.png\" loading=lazy '"$ATTR"' class=\"sprite "r[$1]" newfish "g"\" />"
    }
    print "</div>";
}'
}

source fishutils.sh


if [[ -z "$CAPTCHA" ]]; then
  CURRENT="$(cat "$FISH_ROOT/$CHAN/captcha/id")"
  SESSION[captcha]="$CURRENT"
  save_session
  echo "<div class='captcha-wrapper'><div class='captcha' style=\"display: grid;grid-template-columns: repeat(3, 1fr);grid-template-rows: repeat(3, 1fr);width:256px;height:256px;background-size:cover;background-image:url('data:image/gif;base64,$(base64 -w 0 static/captcha.gif)');\">"
  echo "<div hx-target='#result' hx-post='/catch?captcha=0'></div>"
  echo "<div hx-target='#result' hx-post='/catch?captcha=1'></div>"
  echo "<div hx-target='#result' hx-post='/catch?captcha=2'></div>"
  echo "<div hx-target='#result' hx-post='/catch?captcha=3'></div>"
  echo "<div hx-target='#result' hx-post='/catch?captcha=4'></div>"
  echo "<div hx-target='#result' hx-post='/catch?captcha=5'></div>"
  echo "<div hx-target='#result' hx-post='/catch?captcha=6'></div>"
  echo "<div hx-target='#result' hx-post='/catch?captcha=7'></div>"
  echo "<div hx-target='#result' hx-post='/catch?captcha=8'></div>"
  echo "</div></div>"
  echo '<button hx-swap-oob="true" id="fish-button" disabled class="w-full">Fish</button>'

  # start background task
  # see here for explanation:
  # https://github.com/cgsdev0/bash-stack/blob/main/examples/bg-task/pages/bg.sh
  0>&- regen_captcha 1>&- 2>&- &

  return $(status_code 200)
fi

CURRENT="${SESSION[captcha]}"
if [[ -n "$CURRENT" ]]; then
  SESSION[captcha]=
  if [[ "$CAPTCHA" != "$CURRENT" ]]; then
    FAILED=1
  fi
else
  FAILED=1
fi
save_session

if [[ -n $FAILED ]]; then
  echo $(( now + 120 )) > "$FISH_ROOT/fishing-cooldowns/.$USER_ID.cooldown"
  echo "<div>not even a nibble...</div>"
  cooldown_button
  return $(status_code 200)
fi

catch_fish
if [[ -z "$COOLDOWN" ]]; then
cat <<-EOF
$(echo "$fish_id,$fish" | fish_images)
$(component /me/rod)
EOF
fi
