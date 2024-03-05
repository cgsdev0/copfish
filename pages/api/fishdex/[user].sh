# headers
header Content-Type text/plain
end_headers

PROFILE="$(urldecode "$(basename "${PATH_VARS['user']}")")"

cd "$FISH_ROOT/badcop_"
if [[ ! -f "$PROFILE" ]]; then
  echo "user not found"
  return $(status_code 404)
fi

total=$(cut -d' ' -f1 "$FISH_ROOT"/fish-by-rarity2/* | sort -nu | wc -l)
count=$(cut -d',' -f1 "$FISH_ROOT/badcop_/$PROFILE" | sort -nu | wc -l)
echo $count $total
