
source config.sh

table_row() {
  awk '{ print "<tr><td><a href=\"profile/"$2"\">"$2"</a></td><td>"$1"</td></tr>" }'
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
  awk -F, '
BEGIN {
'"$RARITY_TABLE"'
}
  {
    print "<div class=famer>";
    print "<div class=famer-inner>";
    print "<div class=caughtBy><a href=\"/profile/"$5"\">"$5"</a></div>";
    print "<div class=streak>"$3"x Streak</div>";
    if ( $2 >= 5000 ) {
      print "<img hx-swap=\"outerHTML\" hx-target=\"#showcase\" hx-get=\"/fish/"$5"/"$4"\" src=\"https://stream.cgs.dev/fish/"tolower($1)".png\" loading=lazy '"$ATTR"' class=\"clickable "g" "r[$2]"\" />"
    } else {
      print "<img hx-swap=\"outerHTML\" hx-target=\"#showcase\" hx-get=\"/fish/"$5"/"$4"\" src=\"https://stream.cgs.dev/newfish/spr_fish_"$2"_x.png\" loading=lazy '"$ATTR"' class=\"clickable "r[$2]" newfish "g"\" />"
    }
    print "<div class=bar></div>";
    print "</div></div>";
}'
}


htmx_page <<-EOF
<div hx-ext="sse" sse-connect="/stream" sse-swap="fish" hx-swap="beforeend">
</div>
<div class="container">
<content>
  <h1>${PROJECT_NAME}</h1>
  <h2>Hall of Fame</h2>
  <div class="halloffame">
$({ echo '['; paste -sd',' hall-of-fame/json; echo ']'; } \
  | jq -rc 'map(select(.fishId != null)) | sort_by(.stats.wins) | reverse | .[] | [.fishType, .fishId, .stats.wins, .float, .caughtBy] | @tsv' \
  | tr ' ' '@' \
  | sort -t$'\t' -sk5 -k3nr \
  | uniq -f4 \
  | sort -t$'\t' -k3nr \
  | tr $'\t@' ', ' \
  | head -n9 \
  | fish_images)
</div>
  <h2>Most Complete Fishdexes</h2>
  <div hx-get="/fishdex_best" hx-trigger="load">Loading...</div>
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
