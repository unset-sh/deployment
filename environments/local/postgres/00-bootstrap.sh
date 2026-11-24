#!/usr/bin/env bash
# The cluster's first role, copied from the old app (Undefined6799/unset@60228f5,
# deployment/postgres/init/00-bootstrap.sh) without its `tap` role and database, which this stack does not run. The
# official image runs this once, at initdb, as the bootstrap superuser (an executable *.sh in
# /docker-entrypoint-initdb.d; docker-entrypoint.sh docker_process_init_files, postgres:18). It creates exactly
# `migrator` (runs every migration and sets the runtime roles' passwords), the `unset` database it owns and the PUBLIC
# revokes. Every other role comes from backend's migrations (0003_roles_and_grants.sql).
#
# The password is read inside psql with a backtick \set (psql shell-quotes :'name' there), so it never appears in argv
# or the environment, and reaches SQL only through :'name' literal quoting (psql docs, "SQL Interpolation", PG 18).
set -euo pipefail

SECRETS=/run/secrets

# Fail closed before any statement: a missing or empty secret file stops the container.
if [ ! -s "$SECRETS/pg_migrator_password" ]; then
  echo "00-bootstrap: secret pg_migrator_password is missing or empty" >&2
  exit 1
fi

psql -v ON_ERROR_STOP=1 --no-psqlrc --no-password --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  -v secrets="$SECRETS" <<'SQL'
-- SCRAM only, before any role gets a password (PG 18 deprecates MD5; stated, not assumed).
ALTER SYSTEM SET password_encryption = 'scram-sha-256';
SELECT pg_reload_conf();
SET password_encryption = 'scram-sha-256';

\set migrator_file :secrets '/pg_migrator_password'
\set migrator_password `cat :'migrator_file'`

CREATE ROLE migrator LOGIN NOSUPERUSER NOCREATEDB CREATEROLE NOREPLICATION NOBYPASSRLS
  PASSWORD :'migrator_password';
\unset migrator_password

CREATE DATABASE unset OWNER migrator;
REVOKE ALL ON DATABASE unset FROM PUBLIC;

\connect unset
REVOKE ALL ON SCHEMA public FROM PUBLIC;
SQL
