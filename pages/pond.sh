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
  echo "<button class='w-full' onclick=\"window.open('/pond?popout=true', 'cop.fish', 'width=340,height=600');\">Pop-out</button>"
}

htmx_page <<-EOF
<div hx-ext="sse" sse-connect="/stream">
<div class="container flex flex-col min-h-dvh justify-between p-4">
<div>
<div class="text-right">Logged in as <a href="/profile/${SESSION[id]}" target="_blank">${SESSION[username]}</a></div>
<div class="text-right">(<a href="/logout">Logout</a>)</div>
<div class="mt-4">
<h2>Fishing Rods</h2>
$(component /me/rod)
</div>
</div>
<div id="result"></div>
<div class="w-full flex flex-col sm:flex-row gap-4 mt-4">
<button id="fish-button" hx-post="/catch" hx-target="#result" class="w-full">Fish</button>
$(popout_button)
</div>
</div>
</div>
EOF
return $(status_code 200)
