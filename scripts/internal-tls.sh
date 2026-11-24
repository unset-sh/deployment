#!/bin/sh
# Certificates for the private link between web and backend (mutual TLS; Alex, 2026-11-24), one set per environment.
# Alex runs this by hand; an assistant never does (agent-kit rules/org.md, "Keys, tokens and secrets"). The runbook is
# docs/site/internal-tls.md. Needs OpenSSL 3.
#
#   scripts/internal-tls.sh new <staging|production> <backend-host> <out-dir>
#       Two CAs and two certificates in a new, empty <out-dir> outside any git repository.
#   scripts/internal-tls.sh renew <out-dir>
#       New backend and web certificates (and keys) from the CAs already in <out-dir>.
#
# Two CAs, so each side trusts only the other: backend trusts client-ca.crt, which signs nothing but web's client
# certificate; web trusts server-ca.crt, which signs nothing but backend's server certificate. Keys are ECDSA P-256.
set -eu
umask 077

CA_DAYS=1825 # five years
LEAF_DAYS=397 # thirteen months: renew yearly

fail() {
  printf 'internal-tls: %s\n' "$1" >&2
  exit 1
}

command -v openssl >/dev/null 2>&1 || fail "openssl is not installed"
case "$(openssl version)" in OpenSSL\ 3.*) ;; *) fail "OpenSSL 3 is needed, found: $(openssl version)" ;; esac

# Refuse a folder inside a git work tree: these keys must never be committed.
outside_git() {
  if git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    fail "$1 is inside a git repository; choose a folder outside any repository"
  fi
}

serial() { printf '0x%s' "$(openssl rand -hex 16)"; }

new_key() { openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$1"; }

# new_ca <name> <common name>
new_ca() {
  new_key "$OUT/$1.key"
  openssl req -x509 -new -key "$OUT/$1.key" -out "$OUT/$1.crt" -days "$CA_DAYS" -set_serial "$(serial)" \
    -subj "/O=unset.sh/CN=$2" \
    -addext "basicConstraints=critical,CA:TRUE,pathlen:0" \
    -addext "keyUsage=critical,keyCertSign,cRLSign"
}

# new_leaf <name> <ca> <common name> <extensions>
new_leaf() {
  new_key "$OUT/$1.key.next"
  printf '%b' "$4" >"$OUT/$1.ext"
  openssl req -new -key "$OUT/$1.key.next" -subj "/O=unset.sh/CN=$3" -out "$OUT/$1.csr"
  openssl x509 -req -in "$OUT/$1.csr" -CA "$OUT/$2.crt" -CAkey "$OUT/$2.key" -set_serial "$(serial)" \
    -days "$LEAF_DAYS" -extfile "$OUT/$1.ext" -out "$OUT/$1.crt.next"
  openssl verify -CAfile "$OUT/$2.crt" -purpose "$5" "$OUT/$1.crt.next" >/dev/null || fail "$1.crt did not verify"
  rm -f "$OUT/$1.csr" "$OUT/$1.ext"
  mv "$OUT/$1.key.next" "$OUT/$1.key"
  mv "$OUT/$1.crt.next" "$OUT/$1.crt"
}

leaves() {
  new_leaf backend server-ca "$HOST" \
    "basicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature\nextendedKeyUsage=serverAuth\nsubjectAltName=DNS:$HOST\n" \
    sslserver
  new_leaf web client-ca "web $ENV" \
    "basicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature\nextendedKeyUsage=clientAuth\n" \
    sslclient
  chmod 600 "$OUT"/*.key
  chmod 644 "$OUT"/*.crt
}

case "${1:-}" in
new)
  [ "$#" -eq 4 ] || fail "usage: internal-tls.sh new <staging|production> <backend-host> <out-dir>"
  ENV=$2 HOST=$3 OUT=$4
  case "$ENV" in staging | production) ;; *) fail "the environment is staging or production" ;; esac
  printf '%s' "$HOST" | grep -Eq '^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)*$' ||
    fail "the backend host is a lowercase DNS name, such as backend.internal"
  [ -d "$(dirname "$OUT")" ] || fail "$(dirname "$OUT") does not exist"
  outside_git "$(dirname "$OUT")"
  if [ -e "$OUT" ] && [ -n "$(ls -A "$OUT")" ]; then fail "$OUT is not empty; a new set needs a new folder"; fi
  mkdir -p "$OUT"
  printf 'environment=%s\nbackend_host=%s\n' "$ENV" "$HOST" >"$OUT/set.txt"
  chmod 644 "$OUT/set.txt"
  new_ca server-ca "unset.sh $ENV backend CA"
  new_ca client-ca "unset.sh $ENV web CA"
  leaves
  ;;
renew)
  [ "$#" -eq 2 ] || fail "usage: internal-tls.sh renew <out-dir>"
  OUT=$2
  [ -f "$OUT/set.txt" ] && [ -f "$OUT/server-ca.key" ] && [ -f "$OUT/client-ca.key" ] ||
    fail "$OUT holds no set made by 'new'"
  outside_git "$OUT"
  ENV=$(sed -n 's/^environment=//p' "$OUT/set.txt")
  HOST=$(sed -n 's/^backend_host=//p' "$OUT/set.txt")
  leaves
  ;;
*)
  fail "usage: internal-tls.sh new <staging|production> <backend-host> <out-dir> | renew <out-dir>"
  ;;
esac

printf 'internal-tls: %s set in %s, certificates valid until %s\n' "$ENV" "$OUT" \
  "$(openssl x509 -in "$OUT/web.crt" -noout -enddate | cut -d= -f2)"
printf 'Backend gets backend.crt, backend.key and client-ca.crt; web gets web.crt, web.key and server-ca.crt.\n'
printf 'Keep server-ca.key and client-ca.key offline: they are only needed to renew.\n'
