source secrets.sh
PROJECT_NAME=cop.fish
PORT=5125
FISH_ROOT="${FISH_ROOT:-$HOME/fishing-data}"
mkdir -p $FISH_ROOT/data
ENABLE_SESSIONS=true

sanitize() {
  : "$(urldecode "$1")"
  : "$(htmlencode "$_")"
  : "${_//[$'\t\r\n'\/]}"
  printf '%s' "$_"
}

export -f sanitize
