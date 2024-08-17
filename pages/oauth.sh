# headers
source config.sh

HOST=${HTTP_HEADERS["host"]}
PROTOCOL="https://"
if [[ "$HOST" =~ "localhost"* ]]; then
  PROTOCOL="http://"
fi

AUTHORIZATION_CODE=${QUERY_PARAMS["code"]}

TWITCH_RESPONSE=$(curl -Ss -X POST \
  "https://id.twitch.tv/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=${TWITCH_CLIENT_ID}&client_secret=${TWITCH_CLIENT_SECRET}&code=${AUTHORIZATION_CODE}&grant_type=authorization_code&redirect_uri=${PROTOCOL}${HOST}/oauth")

ACCESS_TOKEN=$(echo "$TWITCH_RESPONSE" | jq -r '.access_token')
REFRESH_TOKEN=$(echo "$TWITCH_RESPONSE" | jq -r '.refresh_token')
RESPONSE="<pre>${TWITCH_RESPONSE}</pre>"

if [[ -z "$ACCESS_TOKEN" ]] || [[ "$ACCESS_TOKEN" == "null" ]]; then
end_headers
htmx_page <<-EOF
  <div class="container2">
    <h1>Error</h1>
    ${RESPONSE}
    <p>Something went wrong registering for ${PROJECT_NAME}. :(</p>
    <p><a href="/">Back to Home</a></p>
  </div>
EOF
  return $(status_code 400)
fi

# we have to get the stupid user id
TWITCH_RESPONSE=$(curl -Ss -X GET 'https://id.twitch.tv/oauth2/validate' \
  -H "Authorization: OAuth ${ACCESS_TOKEN}")

USER_ID=$(echo "$TWITCH_RESPONSE" | jq -r '.user_id')
USER_NAME=$(echo "$TWITCH_RESPONSE" | jq -r '.login')
RESPONSE="<pre>${TWITCH_RESPONSE}</pre>"

if [[ -z "$USER_ID" ]] || [[ "$USER_ID" == "null" ]]; then
  end_headers
  htmx_page <<-EOF
  <div class="container2">
    <h1>Error</h1>
    ${RESPONSE}
    <p>Something went wrong registering for ${PROJECT_NAME}. :(</p>
    <p><a href="/">Back to Home</a></p>
  </div>
EOF
  return $(status_code 400)
fi

TWITCH_RESPONSE=$(curl -Ss -X GET 'https://api.twitch.tv/helix/users?id='$USER_ID \
  -H "Client-Id: ${TWITCH_CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")
USER_NAME=$(echo "$TWITCH_RESPONSE" | jq -r '.data[0] | .display_name')
RESPONSE="<pre>${TWITCH_RESPONSE}</pre>"
if [[ -z "$USER_NAME" ]] || [[ "$USER_NAME" == "null" ]]; then
  end_headers
  htmx_page <<-EOF
  <div class="container2">
    <h1>Error</h1>
    ${RESPONSE}
    <p>Something went wrong registering for ${PROJECT_NAME}. :(</p>
    <p><a href="/">Back to Home</a></p>
  </div>
EOF
  return $(status_code 400)
fi


USER_ACCESS_TOKEN="$ACCESS_TOKEN"

# now we need to get a DIFFERENT token, unrelated, but actually kinda related lol
# see here: https://dev.twitch.tv/docs/eventsub/manage-subscriptions/#subscribing-to-events
TWITCH_RESPONSE=$(curl -Ss -X POST \
  "https://id.twitch.tv/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=${TWITCH_CLIENT_ID}&client_secret=${TWITCH_CLIENT_SECRET}&grant_type=client_credentials")

ACCESS_TOKEN=$(echo "$TWITCH_RESPONSE" | jq -r '.access_token')

# success! persist data
if grep -q "^$USER_ID " $FISH_ROOT/data/username_cache; then
  sed -i 's/^'$USER_ID' .*$/'$USER_ID' '$USER_NAME'/' $FISH_ROOT/data/username_cache
else
  printf "%s %s\n" "$USER_ID" "$USER_NAME" >> $FISH_ROOT/data/username_cache
fi
SESSION[id]="$USER_ID"
SESSION[username]="$USER_NAME"

save_session

header Location "/pond?popout=true"
end_headers
end_headers

return $(status_code 302)
