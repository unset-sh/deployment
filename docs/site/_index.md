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

**Status: repository foundation only.** No infrastructure definitions, live environment, image selections or
deployment workflows exist here yet. Nothing is deployable from this repository.

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
