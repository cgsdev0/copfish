CHAN=badcop_


tbus_send() {

    rarity_table() {
      for file in "$FISH_ROOT"/fish-by-rarity2/*; do
        filename=${file##*/}
        cut "$file" -d' ' -f1 | awk '{ print "r["$1"]=\"'$filename'\";" }'
      done
    }

    RARITY_TABLE="$(rarity_table)"

    the_other_fish_images() {
      while IFS= read -r line; do
        [[ -z "$line" ]] && break
        E="${line##*,}"
        printf "$line, ${USERNAME_CACHE[$E]}\n"
      done | awk -F, '
    BEGIN {
    '"$RARITY_TABLE"'
    }
      {
        printf "%s","<div class=\"flex items-end\">";
        printf "%s","<div class=\"text-center\">";
        printf "%s","<div class=\"caughtBy hidden\"><a href=\"/profile/"$4"\">"$5"</a></div>";
        if ( $2 >= 5000 ) {
          printf "%s","<img hx-swap=\"outerHTML\" hx-target=\"#showcase\" hx-get=\"/fish/"$4"/"$3"\" src=\"https://stream.cgs.dev/fish/"tolower($1)".png\" loading=lazy '"$ATTR"' class=\"cursor-pointer size-[96px] shrink-0 "g" "r[$2]"\" />"
        } else {
          printf "%s","<img hx-swap=\"outerHTML\" hx-target=\"#showcase\" hx-get=\"/fish/"$4"/"$3"\" src=\"https://stream.cgs.dev/newfish/spr_fish_"$2"_x.png\" loading=lazy '"$ATTR"' class=\"cursor-pointer sprite size-[96px] shrink-0 "r[$2]" newfish "g"\" />"
        }
        print "</div></div>";
    }'
    }
    function publish() {
      local TOPIC
      local line
      TOPIC="$1"
      if [[ -z "$TOPIC" ]]; then
        return
      fi
      if [[ ! -d "pubsub/${TOPIC}" ]]; then
        return
      fi
      TEE_ARGS=$(find pubsub/"${TOPIC}" -type p)
      if [[ -z "$TEE_ARGS" ]]; then
        return
      fi
      tee $TEE_ARGS > /dev/null
    }

    event() {
      printf "event: %s\ndata: %s\n\n" "$@"
    }

    fish="$(jq -r '[.fish, .id, .float, .twitch_id, .caught_by] | @csv' <<< "${2:-\{\}}")"
    stuff="$(the_other_fish_images <<< "${fish//$'"'/}")"
    event "fish" "${stuff//$'\n'/}" | publish stream
    echo 'SYSTEM_EV {"message_type":"'"$1"'","source":"bash","data":'"${2:-\{\}}"'}' > /tmp/tau_tunnel

}

send_twitch_msg() {
    # TODO
    echo "$@"
}

function _roll_n() {
  local i
  local N=$1
  local DSIZE=$2
  for ((i=0; i<N; i++)); do
    local ROLLED=$((RANDOM % DSIZE + 1))
    if [[ "$SIGN" == "-" ]]; then
      ((ACC-=ROLLED))
    else
      ((ACC+=ROLLED))
    fi
  done
}

function roll() {
  local INPUT="$*"
  INPUT="${INPUT// /}"
  local -a arr
  local ACC=0
  INPUT="${INPUT//+/$'\n'+}"
  INPUT="${INPUT//-/$'\n'-}"
  IFS=$'\n' read -d "" -ra arr \
    <<< "$INPUT"
  for element in "${arr[@]}"; do
    if [[ "$element" =~ ([+-]?)([0-9]+)d([0-9]+) ]]; then
      local SIGN="${BASH_REMATCH[1]}"
      local AMT="${BASH_REMATCH[2]}"
      local DSIZE="${BASH_REMATCH[3]}"
      _roll_n $AMT $DSIZE
    elif [[ "$element" =~ ^[+-]?[0-9]+$ ]]; then
      ((ACC+=element))
    else
      echo "invalid expression" 1>&2
      exit 1
    fi
  done
  echo $ACC
}

fish_leaderboard() {
    cd "$FISH_ROOT/$CHAN"
    find * -maxdepth 0 -type f \
        | xargs wc -l \
        | head -n -1 \
        | sort -nr \
        | head -n 5 \
        | paste -sd '|' \
        | sed 's/|/ | /g'
}

gen_loot_tables() {
    (repeat 300 echo "common";\
    repeat 200 echo "fairly_common";\
    repeat 100 echo "uncommon";\
    repeat 50 echo "scarce";\
    repeat 10 echo "rare";\
    repeat 1 echo "epic";\
    repeat 0 echo "legendary") > old

    (repeat 100 echo "common";\
    repeat 80 echo "fairly_common";\
    repeat 70 echo "uncommon";\
    repeat 50 echo "scarce";\
    repeat 10 echo "rare";\
    repeat 5 echo "epic";\
    repeat 1 echo "legendary") > good

    (repeat 40 echo "common";\
    repeat 80 echo "fairly_common";\
    repeat 100 echo "uncommon";\
    repeat 60 echo "scarce";\
    repeat 20 echo "rare";\
    repeat 10 echo "epic";\
    repeat 5 echo "legendary") > super

    echo "null" > null
}

show_loot_tables() {
    for rod_type in $FISH_ROOT/$CHAN/fishing-rods/*; do
        echo "$(basename $rod_type)" | tr '[:lower:]' '[:upper:]'
        total=$(uniq -c "$rod_type" | grep -o '[0-9]*' | paste -sd+ | bc)
        for STUFF in $(uniq -c "$rod_type"); do
            read count fish_type <<< "$STUFF"
            echo $(bc <<<"scale=2; $count * 100 / $total" | sed 's/^\./0./')'%',$fish_type | sed 's/_/ /g'
        done | column -t -s','
        echo
    done
}

get_rod() {
    rod_file="$FISH_ROOT/$CHAN/fishing-rods/$USER_ID"
    touch "$rod_file"
    usable_rods=$(grep ' [1-9][0-9]*$' "$rod_file" | cut -d' ' -f1)
    best_rod="old"
    case $usable_rods in
        *"admin"*)
            best_rod="admin"
            ;;
        *"null"*)
            best_rod="null"
            ;;
        *"super"*)
            best_rod="super"
            ;;
        *"good"*)
            best_rod="good"
            ;;
    esac
    if [[ "$best_rod" == "old" ]]; then
        echo "$best_rod unlimited"
    else
        echo "$(grep $best_rod $rod_file)"
    fi
}

use_rod() {
    rod_file="$FISH_ROOT/$CHAN/fishing-rods/$USER_ID"
    rod="$(get_rod)"
    rod_name=$(echo "$rod" | cut -d' ' -f1)
    rod_uses=$(echo "$rod" | cut -d' ' -f2)
    rod_new_uses=$((rod_uses - 1))
    sed -i "s/$rod_name $rod_uses/$rod_name $rod_new_uses/" "$rod_file"
    echo "$rod_name"
}

declare -A stats_speed=(
       ["common"]="1d20"
["fairly_common"]="1d20"
     ["uncommon"]="1d20"
       ["scarce"]="1d20 + 1"
         ["rare"]="1d20 + 1"
         ["epic"]="1d20 + 2"
    ["legendary"]="1d20 + 3"
         ["null"]="0"
)

declare -A stats_hp=(
       ["common"]="2d8 + 10"
["fairly_common"]="2d8 + 10"
     ["uncommon"]="2d8 + 10"
       ["scarce"]="2d10 + 1d6 + 10"
         ["rare"]="2d10 + 1d6 + 10"
         ["epic"]="2d10 + 1d6 + 10"
    ["legendary"]="3d10 + 15"
         ["null"]="100"
)

declare -A stats_base_dmg=(
       ["common"]="1d6"
["fairly_common"]="1d6"
     ["uncommon"]="1d6"
       ["scarce"]="1d6 + 1"
         ["rare"]="1d6 + 1"
         ["epic"]="1d8 + 2"
    ["legendary"]="1d8 + 3"
         ["null"]="0"
)

declare -A stats_var_dmg=(
       ["common"]="1d4"
["fairly_common"]="1d4"
     ["uncommon"]="1d4"
       ["scarce"]="1d4"
         ["rare"]="1d4"
         ["epic"]="1d6"
    ["legendary"]="6"
         ["null"]="0"
)

roll_stats() {
    local classification="$1"
    local a=$(roll "${stats_hp[$classification]}")
    local b=$(roll "${stats_base_dmg[$classification]}")
    local c=$(roll "${stats_var_dmg[$classification]}")
    local d=$(roll "${stats_speed[$classification]}")
    echo '{"hp":'$a',"baseDmg":'$b',"varDmg":'$c',"speed":'$d'}' 1>&2
    stats_raw="$a,$b,$c,$d"
    stats_json='{"hp":'$a',"baseDmg":'$b',"varDmg":'$c',"speed":'$d'}'
}

catch_fish() {
    mkdir -p "$FISH_ROOT/fishing-cooldowns"

    pushd "$FISH_ROOT/$CHAN" &> /dev/null
    now=$(date +%s)
    if [[ "$USER_NAME" != "badcop_" ]]; then
      if [[ -f "$FISH_ROOT/fishing-cooldowns/.$USER_ID.cooldown" ]]; then
          cooldown=$(cat "$FISH_ROOT/fishing-cooldowns/.$USER_ID.cooldown")
          if [[ $cooldown -gt $now ]]; then
              echo "you are on cooldown for $((cooldown-now)) seconds"
              return
          fi
      fi
    fi
    fishing_rod="$(use_rod)"
    if [[ ! -f "$FISH_ROOT/fishing-rods/${fishing_rod}" ]]; then
        echo "You have an invalid fishing rod!"
        return
    fi
    PRECHECK="$(fishdex check)"
    classification=$(shuf -n 1 $FISH_ROOT/fishing-rods/${fishing_rod})
    class_pretty=$(echo "$classification" | tr '_' ' ' | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
    fish_raw=$(shuf -n 1 $FISH_ROOT/fish-by-rarity2/${classification})
    fish_id="${fish_raw%% *}"
    fish="${fish_raw#* }"

    # generate stats for our fish
    roll_stats "$classification"
    RNG="$(head -c 8 < /dev/urandom | od -tu8 -An)"
    fish_float="${RNG// /}"

    most_count=$(find * -maxdepth 0 -type f \
        | xargs cut -d',' -f2 \
        | sort \
        | uniq -c \
        | sort -nr \
        | head -n 1 \
        | grep -oE '[0-9].*' \
        | cut -d' ' -f1)
    count=$(find * -maxdepth 0 -type f | xargs cut -d',' -f2 | grep "^${fish_id}$" | wc -l)
    description="a"
    touch "$FISH_ROOT/${CHAN}/$USER_ID"
    personalcount=$(cut -d',' -f2 "$FISH_ROOT/${CHAN}/$USER_ID" | grep "$fish_id" | wc -l)
    if [[ $personalcount -eq 0 ]]; then
        description="your first"
    fi

    rarity=$(bc <<< "scale=2; 100 - ( $count / $most_count * 100 )")

    timestamp="$(date '+%s')"
    echo "$timestamp,$fish_id,$fish,$fish_float,$stats_raw" >> "$FISH_ROOT/${CHAN}/$USER_ID"
    echo $(( now + 120 )) > "$FISH_ROOT/fishing-cooldowns/.$USER_ID.cooldown"

    if [[ $count -eq 0 ]]; then
        description="THE FIRST"
        echo "You caught and DISCOVERED $description $fish ($class_pretty)! ( never caught before :O ) ($fishing_rod rod used)"
    else
        echo "You caught $description $fish ($class_pretty)! ($rarity% rarity) ($fishing_rod rod used)"
    fi
    FISH_JSON='{"fish":"'$fish'","classification":"'$classification'","caught_by":"'$USER_NAME'","twitch_id":'$USER_ID',"id":'$fish_id',"stats":'$stats_json',"float":"'$fish_float'"}'
    popd &> /dev/null
    tbus_send "fish-catch" "$FISH_JSON"
    if [[ "$(fishdex check)" != "$PRECHECK" ]]; then
      send_twitch_msg "YOU HAVE COMPLETED THEIR FISHDEX!!!!!!!!"
    fi
}

uncaught_fish() {
    cd "$FISH_ROOT/${CHAN:-badcop_}"
    diff <(find * -maxdepth 0 -type f | xargs cut -d',' -f1 | sort -nu) <(cut -d' ' -f1 $FISH_ROOT/fish-by-rarity2/* | sort -nu) | grep '>'
}

fishdex_all() {
    cd "$FISH_ROOT/$CHAN"
    total=$(cut -d' ' -f1 $FISH_ROOT/fish-by-rarity2/* | sort -nu | wc -l)
    count=$(find * -maxdepth 0 -type f | xargs cut -d',' -f2 | sort -nu | wc -l)
    echo "$count out of $total possible fish have been caught."
}

fishdex_check() {
    cd "$FISH_ROOT/$CHAN"
    total=$(cut -d' ' -f1 $FISH_ROOT/fish-by-rarity2/* | sort -nu | wc -l)
    if [[ ! -f "$FISH_ROOT/${CHAN}/$1" ]]; then
      echo "No fishdex found!"
    fi
    count=$(cut -d',' -f1 "$FISH_ROOT/${CHAN}/$1" | sort -nu | wc -l)
    echo "@$1 has caught $count out of $total possible fish!"
}

fishdex() {
    cd "$FISH_ROOT/$CHAN"
    total=$(cut -d' ' -f1 $FISH_ROOT/fish-by-rarity2/* | sort -nu | wc -l)
    touch "$FISH_ROOT/${CHAN}/$USER_ID"
    count=$(cut -d',' -f2 "$FISH_ROOT/${CHAN}/$USER_ID" | sort -nu | wc -l)
    if [[ -z "$1" ]]; then
      echo "You have caught $count out of $total possible fish!"
    else
      echo "$total > $count" | bc
    fi
}
