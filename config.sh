source secrets.sh
PROJECT_NAME=cop.fish
PORT=5125
TAILWIND=on
HIDE_LOGO=true
FISH_ROOT="${FISH_ROOT:-$HOME/data/fishing}"
mkdir -p $FISH_ROOT/data
ENABLE_SESSIONS=true

sanitize() {
  : "$(urldecode "$1")"
  : "$(htmlencode "$_")"
  : "${_//[$'\t\r\n'\/]}"
  printf '%s' "$_"
}

function load_user_cache() {
  local USER_ID
  local USER_NAME
  while read -r USER_ID USER_NAME; do
    USERNAME_CACHE[$USER_ID]=$USER_NAME
  done < "$FISH_ROOT/data/username_cache"
}
export -f load_user_cache

function load_id_cache() {
  local USER_ID
  local USER_NAME
  while read -r USER_ID USER_NAME; do
    USERID_CACHE[${USER_NAME,,}]=$USER_ID
  done < "$FISH_ROOT/data/username_cache"
}
export -f load_id_cache


isanitize() {
  : "$(urldecode "$1")"
  : "$(htmlencode "$_")"
  : "${_//[$'\t\r\n'\/]}"
  : "${_//[^0-9]}"
  printf '%s' "$_"
}

gen_license() {
  local chars="ABCDEFGHJKLMNPQRSTUVWXYZ234679"
  local code=""

  for i in {1..4}; do
      code="$code${chars:RANDOM%${#chars}:1}"
  done

  echo "$code"
}

export -f gen_license
export -f sanitize
export -f isanitize
