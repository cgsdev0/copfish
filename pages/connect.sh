# headers

source config.sh

HOST=${HTTP_HEADERS["host"]}
PROTOCOL="https://"
if [[ "$HOST" =~ "localhost"* ]]; then
  PROTOCOL="http://"
fi

USER_ID="${SESSION[id]}"

if [[ -z "$USER_ID" ]]; then
end_headers
htmx_page <<-EOF
<h1>$PROJECT_NAME</h1>
<a href="https://id.twitch.tv/oauth2/authorize?client_id=${TWITCH_CLIENT_ID}&response_type=code&scope=&force_verify=true&redirect_uri=${PROTOCOL}${HOST}/oauth">Connect</a>
EOF
return $(status_code 200)
fi

header Location /dashboard
end_headers
end_headers

return $(status_code 302)
