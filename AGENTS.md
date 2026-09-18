# Repository Agent Guidance

## Scope

This repository maintains a reproducible CMake-based build, install, package,
and test workflow for upstream UGS. Focus changes on maintenance, portability,
packaging, documentation, and verification. Do not add new upstream graphics
features.

## Canonical Guidance

- Read `README.md` for supported user workflows and current limitations,
  including test selection and X11 requirements.
- Follow `CONTRIBUTING.md` for development, verification, pull request,
  versioning, and release policy.
- Follow `SECURITY.md` for vulnerability-reporting scope and procedure.
- Use repository templates for Issues and pull requests.

Do not duplicate detailed procedures here. Update the canonical document when
behavior or policy changes. Personal and environment-specific instructions
belong outside tracked repository guidance.

## Repository Boundaries

- Keep tracked shared documentation, code comments, commits, Issues, and pull
  requests in English.
- Treat downloaded archives, extracted sources under `build/vendor`, generated
  files under `build/generated`, build trees, and staging prefixes as untracked
  artifacts unless a reviewed change explicitly says otherwise.
- Make upstream compatibility changes reproducible through repository-owned
  preparation/build logic, especially `cmake/PrepareUgsSources.cmake`, rather
  than editing generated or extracted copies.
- Preserve public package interfaces where practical, especially `ugs`,
  `ugs::ugs`, and their transitive usage requirements.
- Keep long-lived documentation self-contained; Issues and pull requests hold
  discussion and history, not substitutes for the current contract.

## Change and Verification Discipline

- Keep changes narrow and do not revert unrelated user work.
- Run checks proportional to the affected behavior and report actual results
  and limitations. Display-independent tests do not verify X11 behavior.
- Update documentation and relevant executable verification when user-facing
  workflows, installed interfaces, source acquisition, or layout change.
- Do not describe an unverified platform or workflow as supported.
- Recording follow-up work is good practice, but this guidance does not itself
  authorize an agent to create external Issues or perform other external writes.
