# headers
header Set-Cookie "_session=; Path=/; Secure; HttpOnly"
end_headers


htmx_page <<EOF
<div _="init js window.close() end">
</div>
EOF
