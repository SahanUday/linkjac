#!/usr/bin/env bash
# Runs "$@" in a network and mount namespace of its own (no root needed): private, link-local and public addresses
# on the loopback device and a hosts file of the guard checks' names. Nothing outside the namespace is reachable.
set -euo pipefail
if [ -z "${PARITY_IN_NETNS:-}" ]; then
  exec env PARITY_IN_NETNS=1 unshare -Urnm bash "$0" "$@"
fi
ip link set lo up
for address in 10.77.0.1 10.77.0.2 10.77.0.3 10.77.0.4 10.77.0.5 10.88.0.1 172.16.77.1 192.168.77.1 169.254.169.254 100.64.77.1 93.184.216.34; do
  ip addr add "$address/32" dev lo
done
for address in fd00::1 fd88::1 fec0::1 64:ff9b::a4d:1 ::a4d:1 2606:4700::1111; do
  ip -6 addr add "$address/128" dev lo nodad
done
hosts="$(mktemp)"
cat > "$hosts" <<'HOSTS'
127.0.0.1 localhost
::1 ip6-localhost
127.0.0.2 loop.test
::1 six.test
10.77.0.1 ten.test
10.88.0.1 inrange.test
10.77.0.2 named.test
10.77.0.3 a.sub.test
10.77.0.4 sub.test
10.77.0.5 xsub.test
93.184.216.34 public.test
93.184.216.34 mixed.test
10.77.0.1 mixed.test
HOSTS
mount --bind "$hosts" /etc/hosts
# A certificate for public.test alone, which both apps are told to trust, so a check can fetch a page over https.
certificate="$(mktemp -d)"
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=public.test -addext subjectAltName=DNS:public.test \
  -keyout "$certificate/key.pem" -out "$certificate/cert.pem" 2>/dev/null
export FIXTURE_CERT="$certificate/cert.pem" FIXTURE_KEY="$certificate/key.pem"
export SSL_CERT_FILE="$FIXTURE_CERT" REQUESTS_CA_BUNDLE="$FIXTURE_CERT"
exec "$@"
