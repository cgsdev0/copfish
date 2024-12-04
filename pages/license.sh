if [[ "$REQUEST_METHOD" != "POST" ]]; then
  # only allow POST to this endpoint
  return $(status_code 405)
fi

USER_ID="${SESSION[id]}"
USER_NAME="${SESSION[username]}"

if [[ -z "$USER_ID" ]]; then
  return $(status_code 403)
fi

now=$(date +%s)
if [[ -f "$FISH_ROOT/fishing-cooldowns/.$USER_ID.cooldown" ]]; then
    cooldown=$(cat "$FISH_ROOT/fishing-cooldowns/.$USER_ID.cooldown")
    if [[ $cooldown -gt $now ]]; then
        echo "you are on cooldown for $((cooldown-now)) seconds"
        return $(status_code 200)
    fi
fi

USER_LICENSE="${FORM_DATA[license],,}"
LICENSE="$(cat "$FISH_ROOT/license")"
if [[ "$USER_LICENSE" != "$LICENSE" ]]; then
  echo $(( now + 120 )) > "$FISH_ROOT/fishing-cooldowns/.$USER_ID.cooldown"
  htmx_page <<-EOF
    <p class="text-red-500">Invalid fishing license!</p>
    $(component /catch)
EOF
  return $(status_code 200)
fi

SESSION[license]="$LICENSE"
save_session

echo "<p class='text-green-500'>License updated successfully!</p>"
