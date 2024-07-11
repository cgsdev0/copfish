
ROD_INFO="$(grep -v ' 0$' "$FISH_ROOT/badcop_/fishing-rods/${SESSION[id]}" \
  | sed 's/ / rod, /;s/$/ uses/')"

htmx_page <<-EOF
<pre id="rod" hx-trigger="sse:rod" hx-get="/me/rod" hx-swap-oob="true">${ROD_INFO:-old rod, infinite uses}</pre>
EOF
