#!/usr/bin/env bash
# Local HTTPS for testing the web export on a phone over the LAN: a personal CA (trusted
# once on the phone) and a server certificate for this Mac's .local name and current IP.
# Re-run after the Mac's IP changes; the CA is kept, so the phone needs no new setup.
set -euo pipefail

DIR="${CLICKER_TLS_DIR:-$HOME/.clicker-band-tls}"
HOST="$(scutil --get LocalHostName).local"
IP="$(ipconfig getifaddr en0 || true)"

mkdir -p "$DIR"
chmod 700 "$DIR"
cd "$DIR"

if [[ ! -f ca.key || ! -f ca.crt ]]; then
	openssl genrsa -out ca.key 2048 2>/dev/null
	chmod 600 ca.key
	cat > ca.ext <<-EOF
		basicConstraints = critical, CA:TRUE
		keyUsage = critical, keyCertSign, cRLSign
		subjectKeyIdentifier = hash
	EOF
	openssl req -new -key ca.key -subj "/CN=Clicker Band dev CA ($HOST)" -out ca.csr
	openssl x509 -req -in ca.csr -signkey ca.key -days 3650 -sha256 -extfile ca.ext -out ca.crt 2>/dev/null
	rm ca.csr ca.ext
	echo "CA nueva: hay que instalarla y activarla en el iPhone (ver README)."
fi

SAN="DNS:$HOST,DNS:localhost,IP:127.0.0.1"
[[ -n "$IP" ]] && SAN="$SAN,IP:$IP"

openssl genrsa -out server.key 2048 2>/dev/null
chmod 600 server.key
cat > server.ext <<EOF
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = $SAN
authorityKeyIdentifier = keyid
EOF
openssl req -new -key server.key -subj "/CN=$HOST" -out server.csr
# iOS rejects TLS server certificates valid for more than 825 days.
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
	-days 825 -sha256 -extfile server.ext -out server.crt 2>/dev/null
rm server.csr server.ext

echo "CA para el iPhone:  $DIR/ca.crt"
echo "Clave del servidor: $DIR/server.key"
echo "Cert del servidor:  $DIR/server.crt ($SAN)"
echo "URL en el iPhone:   https://$HOST:8060/tmp_js_export.html${IP:+  (o https://$IP:8060/tmp_js_export.html)}"
