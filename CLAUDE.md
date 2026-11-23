# CLAUDE.md: unset-sh/deployment

## Where this repository fits

This is `unset-sh/deployment`: environment definitions, selected releases and stack rollout orchestration.

- **Belongs here:** topology, networks, volumes, immutable artifact selection, runtime configuration references,
  rollout order, readiness, recovery and the execution of producer-owned migration procedures.
- **Does not belong here:** application code, image builds or migration definitions (`unset-sh/backend` and
  `unset-sh/web`); PDS image customization (`unset-sh/pds`); reusable automation implementation (`unset-sh/tooling`).
- **Uses:** planned released backend/web/PDS images and upstream services such as Tap when adopted, through
  reviewed immutable versions; `unset-sh/tooling` for the branch policy check and `unset-sh/agent-kit` as the copy
  under `.claude/`, both at full commits. **Used by:** operators and environments.
- **Licence:** AGPL-3.0-only first-party work; no outside code contributions for now. Third-party licences remain.

Read the [organisation map](https://github.com/unset-sh/.github/blob/main/MAP.md) before moving responsibility.
When responsibility, dependencies or outputs change, update `unset-sh/.github`'s `repos.json`, regenerate its
map with `npm run map`, and update this section in the same piece of work.

## Rules

- This is a foundation: no environment, image selection, credential or deployment mechanism exists here yet.
  The original `Undefined6799/unset` remains read-only for this work; no production migration is implied.
- Consume producer-built immutable artifacts. Never invent a digest, build application images on a server or
  substitute a mutable tag for a verified release. Preserve existing release approvals and verification gates.
- Own runtime topology and version selection. Backend owns AppView/indexer code and migrations; PDS owns its
  maintained image/customization. Tap is optional future runtime scope, not an implemented dependency here.
- Keep credentials, sessions, device keys, privileged processes and database roles in their intended trust
  boundaries. Configuration includes secret references only, never secret values. Follow agent-kit's key rules.
- Execute migrations only through the producer's documented compatibility and recovery contract. Do not assume
  rolling back an image reverses a data change. Separate rebuildable indexes from authoritative decisions.
- Use tooling's shared mechanisms through reviewed pins when adopted; retain environment policy and small
  callers here. Do not claim automatic adoption, release gates or deployment checks without verified evidence.
- Maintained guides and runbooks belong under `docs/` when needed and export through the documentation pipeline
  once adopted. AI task notes and review artifacts belong in agent-kit, not in this repository.

## Commands

```sh
bun .claude/agent-kit/sync.mjs --check
```

No validation, preview or deployment command exists yet. Add real commands and meaningful checks with the first
environment definition; this repository does not yet operate any environment.
