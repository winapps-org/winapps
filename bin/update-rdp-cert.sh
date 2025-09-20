#!/bin/bash
CERT_PATH="$HOME/.var/app/com.freerdp.FreeRDP/config/freerdp/server/127.0.0.1_3389.pem"
mkdir -p "$(dirname "$CERT_PATH")"
openssl s_client -connect 127.0.0.1:3389 -showcerts </dev/null 2>/dev/null | \
  sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > "$CERT_PATH"
