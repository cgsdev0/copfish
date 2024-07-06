CHAN=badcop_

tbus_send() {
    echo 'SYSTEM_EV {"message_type":"'$1'","source":"bash","data":'${2:-\{\}}'}' > /tmp/tau_tunnel
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

ITERATIONS=1
if [[ "$1" =~ -([0-9]+) ]]; then
  ITERATIONS="${BASH_REMATCH[1]}"
  shift
fi

for ((j=0; j<ITERATIONS; j++)); do
  roll "$@"
done

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
    rod_file="$FISH_ROOT/$CHAN/fishing-rods/$USER_NAME"
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
    rod_file="$FISH_ROOT/$CHAN/fishing-rods/$USER_NAME"
    rod="$(get_rod)"
    rod_name=$(echo "$rod" | cut -d' ' -f1)
    rod_uses=$(echo "$rod" | cut -d' ' -f2)
    rod_new_uses=$((rod_uses - 1))
    sed -i "s/$rod_name $rod_uses/$rod_name $rod_new_uses/" "$rod_file"
    echo "$rod_name"
}

give_rod() {
    rod_type="$1"
    quantity="$2"
    rod_file="$FISH_ROOT/$CHAN/fishing-rods/$USER_NAME"
    touch "$rod_file"
    if grep -q "$rod_type" "$rod_file"; then
        current_quantity=$(grep "$rod_type" "$rod_file" | cut -d' ' -f2)
        new_quantity=$((current_quantity + quantity))
        sed -i "s/$rod_type $current_quantity/$rod_type $new_quantity/" "$rod_file"
    else
        # Append
        echo "$rod_type $quantity" >> "$rod_file"
    fi
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
    cd "$FISH_ROOT/$CHAN"
    now=$(date +%s)
    if [[ -f "$HOME/fishing-cooldowns/.$USER_NAME.cooldown" ]]; then
        cooldown=$(cat "$HOME/fishing-cooldowns/.$USER_NAME.cooldown")
        if [[ $cooldown -gt $now ]]; then
            echo "you are on cooldown for $((cooldown-now)) seconds"
            return
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
        | xargs cut -d',' -f1 \
        | sort \
        | uniq -c \
        | sort -nr \
        | head -n 1 \
        | grep -oE '[0-9].*' \
        | cut -d' ' -f1)
    count=$(find * -maxdepth 0 -type f | xargs cut -d',' -f1 | grep "^${fish_id}$" | wc -l)
    description="a"
    touch "$FISH_ROOT/${CHAN}/$USER_NAME"
    personalcount=$(cut -d',' -f1 "$FISH_ROOT/${CHAN}/$USER_NAME" | grep "$fish_id" | wc -l)
    if [[ $personalcount -eq 0 ]]; then
        description="their first"
    fi

    rarity=$(bc <<< "scale=2; 100 - ( $count / $most_count * 100 )")

    echo "$fish_id,$fish,$fish_float,$stats_raw" >> "$FISH_ROOT/${CHAN}/$USER_NAME"
    if [[ "$USER_NAME" != "$CHAN" ]]; then
      if [[ "$IS_SUBSCRIBER" == "1" ]]; then
        echo $(( now + 90 )) > "$HOME/fishing-cooldowns/.$USER_NAME.cooldown"
      else
        echo $(( now + 120 )) > "$HOME/fishing-cooldowns/.$USER_NAME.cooldown"
      fi
    fi
    if [[ $count -eq 0 ]]; then
        description="THE FIRST"
        echo "@$USER_NAME caught and DISCOVERED $description $fish ($class_pretty)! ( never caught before :O ) ($fishing_rod rod used)"
    else
        echo "@$USER_NAME caught $description $fish ($class_pretty)! ($rarity% rarity) ($fishing_rod rod used)"
    fi
    FISH_JSON='{"fish":"'$fish'","classification":"'$classification'","caught_by":"'$USER_NAME'","id":'$fish_id',"stats":'$stats_json',"float":"'$fish_float'"}'
    tbus_send "fish-catch" "$FISH_JSON"
    if [[ "$(fishdex check)" != "$PRECHECK" ]]; then
      send_twitch_msg "@$USER_NAME HAS COMPLETED THEIR FISHDEX!!!!!!!!"
    fi
}

uncaught_fish() {
    cd "$FISH_ROOT/${CHAN:-badcop_}"
    diff <(find * -maxdepth 0 -type f | xargs cut -d',' -f1 | sort -nu) <(cut -d' ' -f1 $FISH_ROOT/fish-by-rarity2/* | sort -nu) | grep '>'
}

fishdex_all() {
    cd "$FISH_ROOT/$CHAN"
    total=$(cut -d' ' -f1 $FISH_ROOT/fish-by-rarity2/* | sort -nu | wc -l)
    count=$(find * -maxdepth 0 -type f | xargs cut -d',' -f1 | sort -nu | wc -l)
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
    touch "$FISH_ROOT/${CHAN}/$USER_NAME"
    count=$(cut -d',' -f1 "$FISH_ROOT/${CHAN}/$USER_NAME" | sort -nu | wc -l)
    if [[ -z "$1" ]]; then
      echo "@$USER_NAME has caught $count out of $total possible fish!"
    else
      echo "$total > $count" | bc
    fi
}