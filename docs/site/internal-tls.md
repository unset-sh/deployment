---
title: "Web to backend TLS"
description: "Making, installing and renewing the certificates for the private link between web and backend."
weight: 20
type: docs
params:
  doc_kind: runbook
---

Web calls backend's internal API over mutual TLS in staging and production (Alex, 2026-11-24): backend accepts a
connection only from web's client certificate, and web accepts only backend's server certificate. Local dev and the
test suites use plain HTTP (`UNSET_ENV` `dev` or `test`). The browser never calls backend.

Staging and production each have their own set. A certificate from one never works in the other.

## What a set holds

`scripts/internal-tls.sh` in this repository makes a set with OpenSSL 3. Each set has two small CAs, so each side
trusts only the other:

| File | What it is | Where it goes |
| --- | --- | --- |
| `server-ca.crt` | The CA that signs backend's certificate | Web: the CA it trusts for backend |
| `backend.crt`, `backend.key` | Backend's server certificate, for the backend host name | Backend |
| `client-ca.crt` | The CA that signs web's certificate | Backend: the only CA it accepts clients from |
| `web.crt`, `web.key` | Web's client certificate | Web |
| `server-ca.key`, `client-ca.key` | The CA keys | Offline only, never on a server. Needed only to renew |
| `set.txt` | The environment and the backend host the set was made for | Kept with the CA keys |

Keys are ECDSA P-256. The CAs last five years, the certificates thirteen months.

## Make a set

Alex runs this by hand. An assistant never makes, reads or places these keys.

```sh
scripts/internal-tls.sh new staging backend.internal ~/unset-tls/staging
scripts/internal-tls.sh new production backend.internal ~/unset-tls/production
```

The second argument is the host name web uses to reach backend on the private network; backend's certificate is
valid for that name only. The output folder must be new or empty, and outside every git repository: the script
refuses anything else, so the keys cannot be committed by accident.

Then place each file as a secret file for its service, as the table says. The settings that read them come with the
backend and web changes that turn TLS on; their own docs name them.

## Renew the certificates

Once a year, before the end date the script prints:

```sh
scripts/internal-tls.sh renew ~/unset-tls/staging
```

It makes new `backend.*` and `web.*` files from the same CAs and replaces the old ones in the folder. Place the new
files and restart backend, then web. Because the CAs did not change, either order works and nothing else changes.

## Replace a CA

When any key of the set may have leaked, or the CAs near their five-year end. A leaked `web.key` or `backend.key`
needs this too, not a renewal: there is no revocation list, so the CA would keep accepting the old certificate until
it expires.

1. Make a new set in a new folder with `new`.
2. Give backend both client CAs (the old `client-ca.crt` followed by the new one in one file) and give web both
   server CAs the same way. Restart backend, then web.
3. Place the new `backend.*` on backend and restart it, then the new `web.*` on web and restart it.
4. Remove the old CA from both files, restart both, and destroy the old set's keys.

After a leak, skip the overlap: place the whole new set on both services at once and restart them together. Calls
from web fail for the moments between the two restarts, which is better than trusting the leaked key any longer.
