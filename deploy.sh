#!/bin/bash
set -euo pipefail

BASE=/root/vds-trafficmonitor
DEST=/opt/vds-trafficmonitor
UNIT=/etc/systemd/system/vds-trafficmonitor.service
CONF=/etc/caddy/Caddyfile
USER_NAME=tm-widget

install -d -o root -g root -m 0755 "$DEST"
install -o root -g root -m 0644 "$BASE/metrics.py" "$DEST/metrics.py"
install -o root -g root -m 0644 "$BASE/vds-metrics.service" "$UNIT"

PASSWORD="$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')"
HASH="$(caddy hash-password --plaintext "$PASSWORD")"

python3 - "$CONF" "$USER_NAME" "$HASH" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
username, password_hash = sys.argv[2:]
text = path.read_text()
if "/tm-vds/metrics" in text:
    raise SystemExit("Refusing to overwrite an existing /tm-vds/metrics route")
marker = "\n\thandle {\n\t\trespond \"Not found\" 404\n\t}"
route = f'''\n\t@tm_vds path /tm-vds/metrics
\thandle @tm_vds {{
\t\tbasic_auth {{
\t\t\t{username} {password_hash}
\t\t}}
\t\trewrite * /metrics
\t\treverse_proxy 127.0.0.1:61235
\t}}
'''
if marker not in text:
    raise SystemExit("Could not find the expected Caddy catch-all route; no config changed")
path.write_text(text.replace(marker, route + marker))
PY

if ! caddy validate --config "$CONF"; then
    python3 - "$CONF" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
text = p.read_text()
start = text.find("\n\t@tm_vds path /tm-vds/metrics\n")
end = text.find("\n\thandle {\n\t\trespond \"Not found\" 404\n\t}", start)
if start >= 0 and end >= 0:
    p.write_text(text[:start] + text[end:])
PY
    exit 1
fi

install -o root -g root -m 0600 /dev/null "$BASE/credentials.txt"
printf 'username=%s\npassword=%s\nendpoint=https://45.136.7.49/tm-vds/metrics\n' "$USER_NAME" "$PASSWORD" > "$BASE/credentials.txt"
# Keep the generated password out of the source Lua file.
# Enter the credentials from credentials.txt on the Windows client.

systemctl daemon-reload
systemctl enable --now vds-trafficmonitor.service
systemctl reload caddy
printf 'VDS metrics endpoint installed. Credentials saved to %s/credentials.txt\n' "$BASE"
