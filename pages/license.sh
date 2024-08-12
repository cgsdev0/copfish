if [[ "$REQUEST_METHOD" != "POST" ]]; then
  # only allow POST to this endpoint
  return $(status_code 405)
fi

USER_ID="${SESSION[id]}"
USER_NAME="${SESSION[username]}"

if [[ -z "$USER_ID" ]]; then
  return $(status_code 403)
fi

USER_LICENSE="${FORM_DATA[license],,}"
LICENSE="$(cat "$FISH_ROOT/license")"
if [[ "$USER_LICENSE" != "$LICENSE" ]]; then
  htmx_page <<-EOF
    <p class="text-red-500">Invalid fishing license!</p>
    $(component /catch)
EOF
  return $(status_code 200)
fi

SESSION[license]="$LICENSE"
save_session

echo "<p class='text-green-500'>License updated successfully!</p>"
