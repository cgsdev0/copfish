
start_message_broker() {
  rm -f /tmp/tau_tunnel;
  mkfifo /tmp/tau_tunnel;

  CHAN=badcop_

  reqreader() {
    while IFS= read -r line; do
      if [[ "$line" == "SYSTEM_EV "* ]]; then

        echo "$line" | cut -d' ' -f2- 1>&2
        echo "$line" | cut -d' ' -f2-
      else
        # parse incoming messages
        MESSAGE_TYPE=$(echo "$line" | jq -r '.message_type')
        case $MESSAGE_TYPE in
          "fish-champion")
            wins="$(echo "$line" | jq -cr '.data.stats.wins')"
            caughtBy="$(echo "$line" | jq -cr '.data.caughtBy')"
            fishfloat="$(echo "$line" | jq -cr '.data.float')"
            echo "$wins $caughtBy $fishfloat" 1>&2
            if [[ "$wins" -ge 10 ]]; then
              mkdir -p "$FISH_ROOT/$CHAN/hall-of-fame"
              echo "$line" | jq -cr '.data' >> "$FISH_ROOT/$CHAN/hall-of-fame/json"
            fi
            # update our fish in the database
            sed -i '/^[^,]\+,[^,]\+,'$fishfloat',[^,]\+,[^,]\+,[^,]\+,[^,]\+$/s/\(.*\)/\1,'$wins'/' "$FISH_ROOT/$CHAN/$caughtBy"
          ;;
        esac
      fi
    done;
    exit 0;
  }

  authenticate() {
      echo '{"token":"'${TAU_TOKEN}'"}'
  }

  set -o pipefail;
  while true; do
    {authenticate; reqreader < /tmp/tau_tunnel; } \
        | websocat -E 'wss://tau.cgs.dev/ws/message-broker/' --ping-interval 10 --ping-timeout 15 \
        >/tmp/tau_tunnel;
    FAILED=$?
    echo "$FAILED"
    if [[ "$FAILED" -ge 130 ]]; then
      exit 0
    fi
    echo "IT CRASHED, RESTARTING"
  done
}
