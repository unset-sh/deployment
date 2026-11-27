#!/bin/sh
# The secret files of the local stack (environments/local/compose.yaml): Postgres passwords, the RustFS root keys, the
# seal keyring and the Better Auth secret, each random and made on this machine. Alex runs this by hand; an assistant never does (agent-kit
# rules/org.md, "Keys, tokens and secrets"). The runbook is docs/site/local-stack.md. Needs OpenSSL.
#
#   scripts/local-secrets.sh <tls-dir> <out-dir>
#       Every file in a new, empty <out-dir> outside any git repository, with a copy of the certificates and keys
#       web and backend use from <tls-dir>, the staging set scripts/internal-tls.sh wrote (never its CA keys).
#
# These are for the local stack only. Staging and production get their own, made where they run.
set -eu
umask 077

fail() {
  printf 'local-secrets: %s\n' "$1" >&2
  exit 1
}

command -v openssl >/dev/null 2>&1 || fail "openssl is not installed"
[ "$#" -eq 2 ] || fail "usage: local-secrets.sh <tls-dir> <out-dir>"
TLS=$1 OUT=$2
for name in backend.crt backend.key client-ca.crt web.crt web.key server-ca.crt; do
  [ -s "$TLS/$name" ] || fail "$TLS/$name is missing; make the staging set with scripts/internal-tls.sh first"
done
[ -d "$(dirname "$OUT")" ] || fail "$(dirname "$OUT") does not exist"
# Refuse a folder inside a git work tree: these files must never be committed.
if git -C "$(dirname "$OUT")" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "$(dirname "$OUT") is inside a git repository; choose a folder outside any repository"
fi
if [ -e "$OUT" ] && [ -n "$(ls -A "$OUT")" ]; then fail "$OUT is not empty; a new set needs a new folder"; fi
mkdir -p "$OUT"
chmod 700 "$OUT"

# 32 random bytes as hex: printable ASCII, as backend's role password sync requires.
password() { openssl rand -hex 32 >"$OUT/$1"; }

password pg_superuser_password
password pg_migrator_password
password pg_backend_password
password pg_backend_auth_password
password better_auth_secret
password rustfs_access_key
password rustfs_secret_key
# One seal key (backend src/adapters/seal/keyring.ts: kid, then 32 bytes in padded base64).
printf '{"active":"k1","keys":{"k1":"%s"}}\n' "$(openssl rand -base64 32)" >"$OUT/seal_keyring"
# The TLS files, copied rather than mounted from <tls-dir>, so their modes below apply to the copies only.
for name in backend.crt backend.key client-ca.crt web.crt web.key server-ca.crt; do cp "$TLS/$name" "$OUT/$name"; done

# Each container runs as its own non-root user and reads its file through a bind mount, which keeps the file's owner
# and mode (Compose specification, secrets: uid, gid and mode are not applied to file secrets). The folder stays 0700,
# so on this machine only its owner can reach the files.
chmod 444 "$OUT"/*
printf 'local-secrets: wrote %s\n' "$OUT"
