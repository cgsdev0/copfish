

PROFILE="$(isanitize "${PATH_VARS['user']}")"
FISH="$(isanitize "${PATH_VARS['fish']}")"
if [[ -z "$PROFILE" ]]; then
  return $(status_code 404)
fi

declare -A USERNAME_CACHE
load_user_cache

cd "$FISH_ROOT/$CHAN"
FISH_ROW="$(grep -E "^[^,]+,[^,]+,[^,]+,$FISH," "$PROFILE")"

IFS=$'\n' read -d "" -ra FISH_DATA <<< "${FISH_ROW//,/$'\n'}"

ATTR='width=192 height=192'

rarity_table() {
  for file in "$FISH_ROOT"/fish-by-rarity2/*; do
    filename=${file##*/}
    cut "$file" -d' ' -f1 | awk '{ print "r["$1"]=\"'$filename'\";" }'
  done
}

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
      print "<img src=\"https://stream.cgs.dev/newfish/spr_fish_"$1"_x.png\" loading=lazy '"$ATTR"' class=\"sprite "r[$1]" newfish "g"\" />"
    }
    print "</div>";
}'
}

RARITY="$(echo "$RARITY_TABLE" \
  | grep "r\[${FISH_DATA[1]}\]" \
  | cut -d'=' -f2 \
  | tr -d '";')"
RARITY="${RARITY//_/ }"

htmx_page <<-EOF
<div id="modal" class="p-4 round-xl" hx-swap-oob="true" _="init showModal() the #dialog end">
<button _="on click close() the #dialog">X</button>
<h1>${USERNAME_CACHE[$PROFILE]}'s Fish</h1>
$(echo "${FISH_DATA[1]},${FISH_DATA[2]}" | fish_images)
<pre>
ID:       ${FISH_DATA[1]}
NAME:     ${FISH_DATA[2]}
SEED:     ${FISH_DATA[3]}
RARITY:   ${RARITY^}
HP:       ${FISH_DATA[4]}
BASE_DMG: ${FISH_DATA[5]}
VAR_DMG:  ${FISH_DATA[6]}
SPEED:    ${FISH_DATA[7]}
WINS:     ${FISH_DATA[8]:-UNKNOWN}
</pre>
</div>
EOF
