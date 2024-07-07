cd "$FISH_ROOT/badcop_"

declare -A USERNAME_CACHE
load_cache

table_row() {
  local COUNT ID
  while IFS= read -r line; do
    read ID COUNT <<< "$line"
    echo "<tr><td><a href=\"profile/$ID\">${USERNAME_CACHE[$ID]:-twitch_user:$ID}</a></td><td>$COUNT</td></tr>"
  done
}

htmx_page <<-EOF
<table>
$(find . -maxdepth 1 -type f \
  | tr -d './' \
  | xargs -I {} bash -c "echo -n {}' '; cut -d',' -f1 {} | sort -u | wc -l" \
  | sort -k2nr \
  | head -n 5 \
  | table_row)
</table>
EOF
