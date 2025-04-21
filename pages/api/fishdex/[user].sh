# headers
header Content-Type text/plain
end_headers

PROFILE="$(sanitize "${PATH_VARS['user']}")"
if [[ -z "$PROFILE" ]]; then
  return $(status_code 404)
fi
declare -A USERID_CACHE
load_id_cache

USERNAME="${USERID_CACHE[${PROFILE,,}]}"

if [[ ! -f "$FISH_ROOT/$CHAN/$USERNAME" ]]; then
  echo "user not found"
  return $(status_code 404)
fi

total=$(cut -d' ' -f1 "$FISH_ROOT"/fish-by-rarity2/* | sort -nu | wc -l)
count=$(cut -d',' -f2 "$FISH_ROOT/$CHAN/$USERNAME" | sort -nu | wc -l)
echo $count $total
