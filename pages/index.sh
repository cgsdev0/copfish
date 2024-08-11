
declare -A USERNAME_CACHE
load_user_cache

table_row() {
  local COUNT ID
  while IFS= read -r line; do
    read COUNT ID <<< "$line"
    echo "<tr><td><a href=\"profile/$ID\">${USERNAME_CACHE[$ID]:-twitch_user:$ID}</a></td><td class=text-right>$COUNT</td></tr>"
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
    printf "%s","<div class=\"famer flex items-end\">";
    printf "%s","<div class=\"famer-inner text-center\">";
    printf "%s","<div class=caughtBy><a href=\"/profile/"$5"\">"$6"</a></div>";
    printf "%s","<div class=streak>"$3"x Streak</div>";
    if ( $2 >= 5000 ) {
      printf "%s","<img hx-swap=\"outerHTML\" hx-target=\"#showcase\" hx-get=\"/fish/"$5"/"$4"\" src=\"https://stream.cgs.dev/fish/"tolower($1)".png\" loading=lazy '"$ATTR"' class=\"cursor-pointer "g" "r[$2]"\" />"
    } else {
      printf "%s","<img hx-swap=\"outerHTML\" hx-target=\"#showcase\" hx-get=\"/fish/"$5"/"$4"\" src=\"https://stream.cgs.dev/newfish/spr_fish_"$2"_x.png\" loading=lazy '"$ATTR"' class=\"cursor-pointer sprite "r[$2]" newfish "g"\" />"
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
    | head -n8 \
    | fish_images)"
  echo "<div class='stand flex'>"
  echo "$ROWS" | sed -n '1h; 2{p; g; p}; 3p;'
  echo "</div><div class='runnerups items-start flex flex-wrap mt-4'>"
  echo "$ROWS" | tail -n5
  echo "</div>"
}

search() {
  cat <<EOF
  <div class="relative group mb-4">
  <input class="form-control" type="search"
        autocomplete="off"
       name="search" placeholder="Search Users"
       hx-post="/search"
       hx-trigger="input changed delay:200ms, search"
       hx-target="#search-results"
       hx-indicator=".htmx-indicator">

    <div id="search-results"
    class="invisible group-[:focus-within]:visible empty:hidden absolute bg-white dark:bg-slate-800 border flex flex-col p-4 rounded-lg shadow"
    ></div>
    </div>
EOF
}

htmx_page <<-EOF
<div class="container mx-auto">
<content class="flex flex-col lg:grid lg:grid-cols-3 gap-4 mt-4">
  <div class="halloffame card flex flex-col col-span-2 items-center">
  <h2>Hall of Fame</h2>
  $(hall_of_fame)
  </div>
  <div class="h-full">
  <button
  onclick="window.open('/pond?popout=true', 'cop.fish', 'width=340,height=600');"
  class="w-full mb-4 rounded-lg">Launch</button>

  <div class="card flex-col w-full">
$(search)
  <h2>Most Complete Fishdexes</h2>
  <div hx-get="/cached/fishdex_best" hx-trigger="load">Loading...</div>
  <h2 class="mt-4">Fishers</h2>
  <table class="w-full max-w-72">
$(find . -maxdepth 1 -type f \
  | tr -d './' \
  | xargs wc -l \
  | sort -nr \
  | tail +2 \
  | head -n 12 \
  | table_row)
  </table>
  </div>
  </div>
  <div class="card w-full col-span-3 flex-col">
<h2>Recent Catches</h2>
<div hx-ext="sse" sse-connect="/stream" sse-swap="fish" hx-swap="beforeend"
class="flex flex-row-reverse overflow-x-hidden justify-end"
>
<div class="h-[96px] w-0"></div>
</div>
</div>
</content>
<aside id="showcase"></aside>
</div>
EOF
