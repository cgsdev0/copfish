# headers
HIDE_LOGO=true

source config.sh

HOST=${HTTP_HEADERS["host"]}
PROTOCOL="https://"
if [[ "$HOST" =~ "localhost"* ]]; then
  PROTOCOL="http://"
fi

USER_ID="${SESSION[id]}"

if [[ -z "$USER_ID" ]]; then
  header Location "https://id.twitch.tv/oauth2/authorize?client_id=${TWITCH_CLIENT_ID}&response_type=code&scope=&redirect_uri=${PROTOCOL}${HOST}/oauth"
  end_headers
  end_headers

  return $(status_code 302)
fi

end_headers

popout_button() {
  if [[ "${QUERY_PARAMS['popout']}" == "true" ]]; then
    return
  fi
  echo "<button onclick=\"window.open('/pond?popout=true', 'cop.fish', 'width=340,height=600');\">Pop-out</button>"
}

htmx_page <<-EOF
<div hx-ext="sse" sse-connect="/stream">
<h1>$PROJECT_NAME</h1>
<p>Logged in as <a href="/profile/${SESSION[id]}" target="_blank">${SESSION[username]}</a></p>
<h2>Fishing Rods</h2>
$(component /me/rod)
<div id="result"></div>
<button hx-post="/catch" hx-target="#result">Fish</button>
$(popout_button)
</div>
EOF
return $(status_code 200)
