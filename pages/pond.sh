# headers

source config.sh

HOST=${HTTP_HEADERS["host"]}
PROTOCOL="https://"
if [[ "$HOST" =~ "localhost"* ]]; then
  PROTOCOL="http://"
fi

USER_ID="${SESSION[id]}"

if [[ -z "$USER_ID" ]]; then
  header Location /connect
  end_headers
  end_headers

  return $(status_code 302)
fi

end_headers
htmx_page <<-EOF
<h1>$PROJECT_NAME</h1>
<p>${SESSION[username]}</p>
<div id="result"></div>
<button hx-post="/catch" hx-target="#result">Fish</button>
EOF
return $(status_code 200)
