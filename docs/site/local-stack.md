---
title: "Local stack"
description: "Running the staging images of web and backend with Postgres on one machine, to try the first slice."
weight: 30
type: docs
params:
  doc_kind: runbook
---

`environments/local/compose.yaml` runs the staging images of backend and web with Postgres on one machine. It is the
way to try the first slice (sign in with an AT Proto handle, see the profile, change the display name, sign out)
before staging runs it. Alex starts it by hand; an assistant never makes, reads or places its secrets.

What it runs:

| Service | What it does | Networks |
| --- | --- | --- |
| `postgres` | PostgreSQL 18. Its first start creates `migrator` and the `unset` database (`postgres/00-bootstrap.sh`). | `data` |
| `migrate` | Backend's migrations as `migrator`, then the passwords of `backend` and `backend_auth`. Runs once and exits. | `data` |
| `backend` | Backend's internal API, on port 8080 over mutual TLS. It reaches no port on this machine. | `internal`, `data`, `egress` |
| `web` | The site, on `http://127.0.0.1:3000` of this machine only. | `internal`, `published` |

`internal` joins only web and backend (Alex, 2026-11-24), and `data` only backend, migrate and Postgres. Both are
internal Docker networks, with no way out. Backend reaches the internet through `egress` for handles, DID documents
and the member's PDS. Any PDS can sign in, so the stack runs none of its own.

It runs with `UNSET_ENV=dev`. This slice signs in with atproto's loopback client, whose redirect must be on
`127.0.0.1`, and web allows a plain-HTTP public origin only in dev. Web and backend still speak only mutual TLS,
with the staging certificates. Signing in on `staging.unset.sh` needs the confidential OAuth client, which is not
built yet.

## Before the first start

You need Docker with Compose v2, OpenSSL, and the staging certificate set from `scripts/internal-tls.sh`
([Web to backend TLS](internal-tls.md)) made for the host name `backend`.

The staging images are built for amd64 only (Alex, 2026-11-24). On an Apple Silicon Mac, run them under Rosetta 2,
not QEMU: under QEMU, Bun stops at start with `StackOverflow: failed to load bunfig`. With Colima (v0.5.3 or later,
macOS 13 or later), start the VM with Rosetta, as the [Colima README](https://github.com/abiosoft/colima#readme)
describes:

```sh
colima start --vm-type=vz --vz-rosetta
```

1. Make the secret files in a new folder outside every repository. The script writes the Postgres passwords, the
   seal keyring and the Better Auth secret, and copies the six certificate and key files web and backend use from
   the staging set (never its CA keys). It refuses a folder inside a git repository and a folder that is not empty:

   ```sh
   scripts/local-secrets.sh ~/.unset/tls/staging ~/.unset/local
   ```

2. Sign in to the GitHub container registry with a token that can only read packages, if the staging packages are
   private:

   ```sh
   docker login ghcr.io --username Undefined6799
   ```

3. Check that each image came from its repository's staging branch through tooling's workflow. The image references
   are the ones in `compose.yaml`:

   ```sh
   gh attestation verify oci://ghcr.io/unset-sh/staging/backend@sha256:<digest> \
     --repo unset-sh/backend --signer-workflow unset-sh/tooling/.github/workflows/image-staging.yml \
     --source-ref refs/heads/staging --deny-self-hosted-runners
   gh attestation verify oci://ghcr.io/unset-sh/staging/web@sha256:<digest> \
     --repo unset-sh/web --signer-workflow unset-sh/tooling/.github/workflows/image-staging.yml \
     --source-ref refs/heads/staging --deny-self-hosted-runners
   ```

## Start, use and stop

```sh
cd environments/local
LOCAL_SECRETS=~/.unset/local docker compose up -d
LOCAL_SECRETS=~/.unset/local docker compose ps
```

All four services should be `running (healthy)`, except `migrate`, which shows `exited (0)`. Then open
<http://127.0.0.1:3000> and sign in with a handle. Use `127.0.0.1`, not `localhost`: the OAuth redirect and the
host check both name `127.0.0.1`.

`docker compose logs backend web` shows one JSON line per request. No line carries a handle, a DID, a token or an
address.

To stop it, keeping the database, run `LOCAL_SECRETS=~/.unset/local docker compose down`. Add `-v` to delete the
database too. The next start then creates it again with the same secrets.

## When something fails

- **A service restarts with exit code 78.** A setting or secret file is wrong. Its log names the key and the
  reason, never the value. `unreadable` means the container cannot read the file: the script makes each file
  readable by every user, inside a folder only you can open, because a mounted secret file keeps its mode.
- **`migrate` exits 1.** Its last log line names the reason. `password sync secret_unreadable` names the role whose
  file is missing.
- **web is not healthy.** It starts after backend is healthy. If backend is up but web cannot reach it, check that
  the staging set was made for the host name `backend`.

## Updating the images

`compose.yaml` pins each image by digest. When a new staging image should run here, replace its digest and
`UNSET_COMMIT` with the values from that image's staging run summary in its repository's Actions tab, and verify it
as in step 3.
