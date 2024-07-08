
declare -A USERNAME_CACHE
load_user_cache

table_row() {
  local COUNT ID
  while IFS= read -r line; do
    read COUNT ID <<< "$line"
    echo "<tr><td><a href=\"profile/$ID\">${USERNAME_CACHE[$ID]:-twitch_user:$ID}</a></td><td>$COUNT</td></tr>"
  done
}
cd "$FISH_ROOT/badcop_"

ATTR='width=128 height=128'

rarity_table() {
  for file in "$FISH_ROOT"/fish-by-rarity2/*; do
    filename=${file##*/}
    cut "$file" -d' ' -f1 | awk '{ print "r["$1"]=\"'$filename'\";" }'
  done
}

RARITY_TABLE="$(rarity_table)"

fish_images() {
  while IFS= read -r line; do
    E="${line##*,}"
    printf "$line, ${USERNAME_CACHE[$E]}\n"
  done | awk -F, '
BEGIN {
'"$RARITY_TABLE"'
}
  {
    printf "%s","<div class=famer>";
    printf "%s","<div class=famer-inner>";
    printf "%s","<div class=caughtBy><a href=\"/profile/"$5"\">"$6"</a></div>";
    printf "%s","<div class=streak>"$3"x Streak</div>";
    if ( $2 >= 5000 ) {
      printf "%s","<img hx-swap=\"outerHTML\" hx-target=\"#showcase\" hx-get=\"/fish/"$5"/"$4"\" src=\"https://stream.cgs.dev/fish/"tolower($1)".png\" loading=lazy '"$ATTR"' class=\"clickable "g" "r[$2]"\" />"
    } else {
      printf "%s","<img hx-swap=\"outerHTML\" hx-target=\"#showcase\" hx-get=\"/fish/"$5"/"$4"\" src=\"https://stream.cgs.dev/newfish/spr_fish_"$2"_x.png\" loading=lazy '"$ATTR"' class=\"clickable "r[$2]" newfish "g"\" />"
    }
    printf "%s","<div class=bar></div>";
    print "</div></div>";
}'
}

hall_of_fame() {
  ROWS="$({ echo '['; paste -sd',' hall-of-fame/json; echo ']'; } \
    | jq -rc 'map(select(.fishId != null)) | sort_by(.stats.wins) | reverse | .[] | [.fishType, .fishId, .stats.wins, .float, .twitchID] | @tsv' \
    | tr ' ' '@' \
    | sort -t$'\t' -sk5 -k3nr \
    | uniq -f4 \
    | sort -t$'\t' -k3nr \
    | tr $'\t@' ', ' \
    | head -n9 \
    | fish_images)"
  echo "<div class='stand'>"
  echo "$ROWS" | sed -n '2p;1p;3p'
  echo "</div><div class='runnerups'>"
  echo "$ROWS" | tail -n6
  echo "</div>"
}

htmx_page <<-EOF
<div hx-ext="sse" sse-connect="/stream" sse-swap="fish" hx-swap="beforeend">
</div>
<div class="container">
<content>
  <h1>${PROJECT_NAME}</h1>
  <h2>Hall of Fame</h2>
  <div class="halloffame">
  $(hall_of_fame)
  </div>
  <h2>Most Complete Fishdexes</h2>
  <div hx-get="/cached/fishdex_best" hx-trigger="load">Loading...</div>
  <h2>Fishers</h2>
  <table>
$(find . -maxdepth 1 -type f \
  | tr -d './' \
  | xargs wc -l \
  | sort -nr \
  | tail +2 \
  | table_row)
  </table>
</content>
<aside id="showcase"></aside>
</div>
EOF
