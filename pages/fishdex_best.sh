cd "$FISH_ROOT/badcop_"
htmx_page <<-EOF
<table>
$(find . -maxdepth 1 -type f \
  | tr -d './' \
  | xargs -I {} bash -c "echo -n {}' '; cut -d',' -f1 {} | sort -u | wc -l" \
  | sort -k2nr \
  | head -n 5 \
  | awk '{ print "<tr><td><a href=\"/profile/"$1"\">"$1"</a></td><td>"$2"</td></tr>" }')
</table>
EOF
