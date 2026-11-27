---
title: "Deployment"
description: "How unset.sh environments are assembled from released components and rolled out."
type: docs
cascade:
  type: docs
menus:
  main:
    weight: 120
params:
  doc_kind: overview
---

`unset-sh/deployment` assembles released components into environments. It owns how the stack runs: environment
topology, networks, volumes and service wiring, the selected immutable images, runtime configuration references,
rollout order, readiness checks and recovery procedures.

**Status: a local stack only.** [The local stack](local-stack.md) runs the staging images of web and backend with
Postgres and RustFS on one machine. No live environment or deployment workflow exists here yet.

## Boundaries

- Each producer builds and releases its own image: [backend](https://github.com/unset-sh/backend),
  [web](https://github.com/unset-sh/web) and [PDS](https://github.com/unset-sh/pds). Deployment selects released
  artifacts by digest and never builds application images on a server.
- Deployment records secret references and provisioning requirements, never secret values.
- For S3-compatible storage, deployment owns buckets, access policies, lifecycle settings and wiring; backend owns
  the storage port, the adapter and the data-access rules.
- Backend owns migration definitions. Deployment runs the documented sequence and records what was deployed. An
  older image is not automatically a safe rollback after a data migration.

The [repository README](https://github.com/unset-sh/deployment#readme) has the full ownership notes. This section is
exported from `docs/site/` in `unset-sh/deployment`; edit it there.
