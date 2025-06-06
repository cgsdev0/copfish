source ./fishutils.sh

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

start_tau_websocket() {
  rm -f /tmp/tau_tunnel;
  mkfifo /tmp/tau_tunnel;

  give_rod() {
      rod_type="$1"
      quantity="$2"
      rod_file="$FISH_ROOT/$CHAN/fishing-rods/$USER_ID"
      touch "$rod_file"
      if grep -q "$rod_type" "$rod_file"; then
          current_quantity=$(grep "$rod_type" "$rod_file" | cut -d' ' -f2)
          new_quantity=$((current_quantity + quantity))
          sed -i "s/$rod_type $current_quantity/$rod_type $new_quantity/" "$rod_file"
      else
          # Append
          echo "$rod_type $quantity" >> "$rod_file"
      fi
      event 'rod' | publish stream &
  }

  reqreader() {
    while IFS= read -r line; do
      if [[ "$line" == "SYSTEM_EV "* ]]; then
        echo "$line" | cut -d' ' -f2-
      else
        # echo "$line" | jq
        eventType=$(echo "$line" | jq -r '."event_type"');
        event_key=$(echo "$line" | jq -r '."event"');
        if [[ "$event_key" != "keep_alive" ]]; then
          case $eventType in
              "fish-champion")
                wins="$(echo "$line" | jq -cr '.event_data.stats.wins')"
                twitchID="$(echo "$line" | jq -cr '.event_data.twitchID')"
                fishfloat="$(echo "$line" | jq -cr '.event_data.float')"
                if [[ "$wins" -ge 10 ]]; then
                  mkdir -p "$FISH_ROOT/$CHAN/hall-of-fame"
                  echo "$line" | jq -cr '.event_data' >> "$FISH_ROOT/$CHAN/hall-of-fame/json"
                fi
                # update our fish in the database
                sed -i '/^[^,]\+,[^,]\+,[^,]\+,'$fishfloat',[^,]\+,[^,]\+,[^,]\+,[^,]\+$/s/\(.*\)/\1,'$wins'/' "$FISH_ROOT/$CHAN/$twitchID"
              ;;
              "stream-offline")
                  login=$(echo "$line" | jq -r '.event_data.broadcaster_user_login')
                  if [[ "$login" == "$CHAN" ]]; then
                    echo "OFFLINE" > "$FISH_ROOT/status"
                  fi
                  ;;
              "stream-online")
                  [[ -f "$FISH_ROOT/$CHAN/recent-catches/data" ]] && rm "$FISH_ROOT/$CHAN/recent-catches/data"
                  touch "$FISH_ROOT/$CHAN/recent-catches/data"
                  login=$(echo "$line" | jq -r '.event_data.broadcaster_user_login')
                  if [[ "$login" == "$CHAN" ]]; then
                    echo "ONLINE" > "$FISH_ROOT/status"
                  fi
                  # LICENSE="$(gen_license)"
                  # echo "${LICENSE,,}" > "$FISH_ROOT/license"
                  # tbus_send "new-license" "{\"license\": \"$LICENSE\"}" &
                  ;;
              "channel-channel_points_custom_reward_redemption-add")
                  who=$(echo "$line" | jq -r '.event_data.user_id');
                  reward=$(echo "$line" | jq -r '.event_data.reward.title');
                  case $reward in
                      "Good Rod")
                          USER_ID=$who
                          give_rod good 30 1>&2
                          ;;
                      "Admin Rod")
                          USER_ID=$who
                          give_rod admin 1 1>&2
                          ;;
                      "Super Rod")
                          USER_ID=$who
                          give_rod super 30 1>&2
                          ;;
                      "NULL Rod")
                          USER_ID=$who
                          give_rod null 1 1>&2
                          ;;
                  esac
                  ;;
          esac
        fi
      fi
    done
  }

  authenticate() {
      echo '{"token":"'${TAU_TOKEN}'"}'
  }

  set -o pipefail;
  while true; do
    echo "starting tau socket"
    { authenticate; reqreader < /tmp/tau_tunnel; } \
        | websocat -E wss://tau.cgs.dev/ws/twitch-events/ --ping-interval 10 --ping-timeout 15 \
        > /tmp/tau_tunnel
    FAILED=$?
    echo "TAU SOCKET FAILED: $FAILED"
  done
}
