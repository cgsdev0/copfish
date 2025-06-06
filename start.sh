#!/usr/bin/env bash

if [[ "$$" != "$(pgrep -o -g $$ bash)" ]]; then
    exec setsid "$0" "$@"
fi

trap "kill -- -$$" EXIT

cd "${0%/*}"

[[ -f 'config.sh' ]] && source config.sh
regen_captcha
source message_broker.sh

if [[ "${DEV:-true}" == "true" ]] && [[ ! -z "$TAILWIND" ]]; then
   npx tailwindcss@v3 -i ./static/style.css -o ./static/tailwind.css --watch=always 2>&1 \
     | sed '/^[[:space:]]*$/d;s/^/[tailwind] /' &
   PID=$!
fi

# move me back
start_tau_websocket &
if [[ "${DEV:-true}" != "true" ]]; then
  export ROUTES_CACHE=$(mktemp)
fi

# remove any old subscriptions; they are no longer valid
rm -rf pubsub

mkdir -p sessions
mkdir -p pubsub
mkdir -p data
mkdir -p uploads

touch "$FISH_ROOT/license"

PORT=${PORT:-3000}

echo -n "Listening on port "
tcpserver -1 -o -l 0 -H -R -c 1000 0 $PORT ./core.sh

if [[ ! -z "$PID" ]]; then
  kill "$PID"
fi
