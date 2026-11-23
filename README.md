# deployment

Unset's environment topology, selected releases and stack rollout orchestration.

**Status: repository foundation only.** No infrastructure definitions, live environment, credentials,
image selections or deployment workflows have been added. Nothing is deployable from this repository yet.
Deployment migration from [Undefined6799/unset](https://github.com/Undefined6799/unset) is pending; the source
repository remains read-only during this foundation work.

## Responsibility

Deployment assembles released components into environments. It owns how the stack runs, while each producer
owns its application code, build and runtime contract.

| Belongs here | Boundary |
| --- | --- |
| Environment topology, networks, volumes and service wiring | Reviewed environment definitions |
| Selected immutable images and other released artifacts | Real producer versions and verified digests |
| Runtime configuration references and secret provisioning requirements | References and procedures, never secret values |
| Rollout order, readiness checks and recovery procedures | Compatible deployment of independently built components |
| Execution of documented migration procedures | Producer-owned definitions and supported version combinations |
| Stack-level operational documentation | Maintained guides and runbooks under `docs/` when needed |

For S3-compatible storage, this repository owns bucket provisioning, IAM policies, lifecycle settings and
environment wiring. Backend owns the storage capability port, S3 adapter and product data-access rules.

Do not build application images on the deployment server. Backend, web and PDS producers build and release
their own artifacts; deployment selects them. Do not add invented image digests or mutable `latest` pins as
stand-ins for a release. Define each environment only when its real artifacts and runtime contracts exist.

## Components and ownership

- [backend](https://github.com/unset-sh/backend) owns product service APIs, AppView query/indexing code,
  migrations, workers, server integrations and their image builds. Preserve distinct processes and database
  roles when their privileges differ. Deployment runs the released artifacts; it does not own their logic.
- [web](https://github.com/unset-sh/web) owns the complete SvelteKit app, messaging screens, device adapters
  and web image builds. Repository colocation does not remove required messaging origin or key isolation.
- [pds](https://github.com/unset-sh/pds) owns maintained PDS packaging, customization and image builds.
  Deployment consumes its released image and configures runtime storage, networking and secret references.
- Tap, when adopted, is a separately operated upstream synchronization service. Backend owns its consumer;
  deployment owns its selected artifact and runtime connections. This foundation does not enable Tap.
- [tooling](https://github.com/unset-sh/tooling) owns reusable deployment/CI workflow implementations;
  this repository owns environment-specific policy, inputs and small callers when they are introduced.

The AppView is backend functionality, not another upstream product to copy here. Its materialized views
live in the chosen data store and are maintained by backend indexers. Separate a rebuildable projection
from authoritative application decisions. A distinct process does not automatically need another database.

Existing source behavior is not a promise of migrated behavior: the first indexer slice uses `@atproto/sync`
against the own PDS; Tap is later scope. Preserve this distinction when selecting the first deployed stack.
[Source decision](https://github.com/Undefined6799/unset/blob/9817f1e7ed51fdd5989d6bad6261a9e167d97b80/docs/human/decisions/0052-ingest-our-pds-with-atproto-sync.md)

## Release and recovery boundaries

Backend owns migration definitions and the compatibility of stored data with supported software versions.
Deployment executes the documented sequence, checks readiness and records the actual deployed versions.
An older image is not automatically a safe rollback after a data migration; require an applicable rollback
or forward-recovery procedure. Keep privileged services and credentials isolated throughout rollout.

Shared [brand](https://github.com/unset-sh/brand), [lexicons](https://github.com/unset-sh/lexicons) and
[rendering](https://github.com/unset-sh/rendering) artifacts enter their consumers' builds. Deployment
selects those resulting releases rather than modifying bundled files at runtime. Automatic updates,
approval gates and rollout monitoring need explicit implementation; none is enabled by this foundation.

## Working here

Read [CLAUDE.md](CLAUDE.md), [AGENTS.md](AGENTS.md) and the
[organisation map](https://github.com/unset-sh/.github/blob/main/MAP.md) before changing ownership.
No validation, preview or deploy command exists yet. Add those commands, environment-specific checks and
recovery documentation with the first real deployment definition. Do not add placeholder workflows.
[Agent-kit](https://github.com/unset-sh/agent-kit) owns shared instructions and AI working artifacts;
[docs](https://github.com/unset-sh/docs) publishes maintained guides authored here. Kit installation and
documentation export are pending.

## Licence

Copyright (c) 2026 Alex (Undefined6799). First-party work is [AGPL-3.0-only](LICENSE).
No outside code has been added, and outside code contributions are not accepted for now.
Third-party work, if introduced under an approved dependency decision, retains its own licence.
