# headers

header Content-Type text/html
header Cache-Control "public, max-age=60"
end_headers

cd "$FISH_ROOT/$CHAN"

declare -A USERNAME_CACHE
load_user_cache

table_row() {
  local COUNT ID
  I=0
  while IFS= read -r line; do
    read ID COUNT <<< "$line"
    echo "<style> :root {"
    echo "--content-width-best-$ID: calc(90%*($COUNT / 111));"
    echo "}</style>"
    echo "<div class='flex justify-between relative mb-1'><div class='pl-2 z-10'><a href=\"profile/$ID\">${USERNAME_CACHE[$ID]:-twitch_user:$ID}</a></div><div class='pr-2 z-10 text-right'>$COUNT</div><div class='absolute h-full bg-blue-100 dark:bg-sky-900 rounded-md origin-left animate-grow left-0 scale-x-0' style='width: var(--content-width-best-$ID); animation-delay: 0.${I}s;'></div></div>"
    ((I++))
  done
}

htmx_page <<-EOF
<div class="w-full">
$(find . -maxdepth 1 -type f \
  | tr -d './' \
  | xargs -I {} bash -c "echo -n {}' '; cut -d',' -f2 {} | sort -u | wc -l" \
  | sort -k2nr \
  | head -n 5 \
  | table_row)
</div>
EOF
