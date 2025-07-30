#!/bin/sh
set -eu

REMOTE_HOST=${REMOTE_HOST:?REMOTE_HOST env‑var required}
REMOTE_PORT=${REMOTE_PORT:-50001}

CUSTOM_CA=/etc/ssl/custom/ca.crt

# decide which CA bundle to use
if [ -s "$CUSTOM_CA" ]; then            # file exists and is non‑empty
    CA_BUNDLE=$CUSTOM_CA
else
    CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt   # system trust (LetsEncrypt)
fi
export REMOTE_HOST REMOTE_PORT CA_BUNDLE

envsubst < /etc/rsyslog.conf.tmpl > /etc/rsyslog.conf
exec /usr/sbin/rsyslogd -n -f /etc/rsyslog.conf
