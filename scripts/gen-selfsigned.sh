#!/usr/bin/env bash
set -euo pipefail

# --- arguments ---------------------------------------------------------
if [ $# -lt 1 ]; then
  echo "Usage: $0 <common‑name> [SAN1 SAN2 ...]" >&2
  exit 1
fi
CN=$1; shift          # mandatory Common Name
SAN_LIST=("$@")       # zero or more alt‑names
# -----------------------------------------------------------------------

DAYS=365
CURVE=prime256v1
mkdir -p dist && cd dist

# ----- build a SAN config ---------------------------------------------
cat > san.cnf <<EOF
[ req ]
distinguished_name = dn
req_extensions     = v3_req
prompt             = no

[ dn ]
CN = $CN

[ v3_req ]
subjectAltName     = @alt_names

[ alt_names ]
EOF

i=1
if [ ${#SAN_LIST[@]} -eq 0 ]; then
  SAN_LIST=("$CN")               # fallback: CN as SAN
fi
for san in "${SAN_LIST[@]}"; do
  echo "DNS.$i = $san" >> san.cnf
  i=$((i+1))
done
# -----------------------------------------------------------------------

# ----- CA --------------------------------------------------------------
openssl ecparam -name "$CURVE" -genkey -noout -out ca.key
openssl req -new -x509 -days "$DAYS" \
  -key ca.key -out ca.crt \
  -subj "/CN=LocalDevCA"

# ----- server ----------------------------------------------------------
openssl ecparam -name "$CURVE" -genkey -noout -out server.key
openssl req -new -key server.key -out server.csr -config san.cnf
openssl x509 -req -in server.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days "$DAYS" -sha256 \
  -extfile san.cnf -extensions v3_req

rm -f server.csr san.cnf
echo "Generated dist/: ca.crt  server.crt  server.key"
