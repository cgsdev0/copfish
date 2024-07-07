
PROFILE="$(isanitize "${PATH_VARS['user']}")"

declare -A USERNAME_CACHE
load_user_cache

total=$(cut -d' ' -f1 "$FISH_ROOT"/fish-by-rarity2/* | sort -nu | wc -l)
count=$(cut -d',' -f1 "$FISH_ROOT/badcop_/$PROFILE" | sort -nu | wc -l)
cd "$FISH_ROOT/badcop_"

ATTR='width=64 height=64'

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
    if ( $3 == "" ) {
      printf "<div hx-target=\"#showcase\" hx-swap=\"outerHTML\" hx-get=\"/fish/"'$PROFILE'"/"$4"\" class=\"clickable fish\">";
    } else {
      print "<div class=fish>";
    }
    if ( $3 == 0 ) {
      print "<div class=name>?????</div>";
      g="uncaught";
    } else {
      print "<div class=name>"$2"</div>";
      g="";
    }
    if ( $3 > 0 ) {
      print "<div class=count>"$3"</div>";
    }
  if ( $1 >= 5000 ) {
    print "<img src=\"https://stream.cgs.dev/fish/"tolower($2)".png\" loading=lazy '"$ATTR"' class=\""g" "r[$1]"\" />"
  } else {
  print "<img src=\"https://stream.cgs.dev/newfish/spr_fish_"$1"_x.png\" loading=lazy '"$ATTR"' class=\""r[$1]" newfish "g"\" />"
}
    print "</div>";
}'
}
fresh_catches() {
  tac "$PROFILE" | head -n 26 | sed 's/^\([^,]*,[^,]*,\)/\1,/' | fish_images
}

fresh_catches_all() {
  tac "$PROFILE" | sed 's/^\([^,]*,[^,]*,\)/\1,/' | fish_images
}

fishdex() {
  cut -d',' -f1-2 $PROFILE \
    | sort -n \
    | uniq -c \
    | tr -s ' ' \
    | sed 's/ \([^ ]*\) /\1,/' \
    | sort -t"," -k1nr,1 \
    | awk -F, '{ print $2","$3","$1 }' \
    | fish_images
}

uncaught_fish() {
    diff <(cut -d',' -f1-2 "$PROFILE" | sort -nu) <(cat "$FISH_ROOT"/fish-by-rarity2/* | sed 's/ /,/' | sort -nu) | grep '>' | sed 's/^> //;s/$/,0/' | fish_images
}
famous=$(jq -r '.twitchID' "$FISH_ROOT/badcop_/hall-of-fame/json" | grep "^$PROFILE$" | wc -l)

if [[ "${QUERY_PARAMS['load']}" == "rest" ]]; then
  htmx_page <<-EOF
$(fresh_catches_all)
EOF
  return
fi
htmx_page <<-EOF
<div class="container">
<content>
<a href="/">&larr; Back to Home</a>
<h1>${USERNAME_CACHE[$PROFILE]}'s Profile</h1>
<p>Hall of Famers: $famous</p>
<h2>Fishdex</h2>
<p>Species Caught: $count / $total</p>
<div class="fishdex">
$(fishdex)
$(uncaught_fish)
</div>
<h2>Fresh Catches</h2>
<div class="fishtank">
$(fresh_catches)
<button hx-target="closest div" hx-get="/profile/$PROFILE?load=rest">Load All Fish</button>
</div>
</content>
<aside id="showcase"></aside>
</div>
EOF
