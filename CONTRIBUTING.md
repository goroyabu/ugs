# Contributing

This repository maintains a CMake-based build, install, package, and test
workflow for the upstream UGS C/Fortran graphics library.

## Project Scope

Appropriate contributions include build and installation improvements,
compiler compatibility, portability, downstream integration, source integrity,
CI, focused regression tests, documentation, and reviewed upstream refreshes.
The project does not develop new upstream graphics features.

Windows, shared-library builds, cross-compilation, other Fortran compilers,
and every historical UGS driver are not part of the current verification
promise. Proposals to expand support must include a maintainable verification
strategy. See [README.md](README.md) for current requirements and coverage.

## Before Making a Change

Review open Issues before substantial work. Reuse an existing Issue when it
covers the change; discuss new public interfaces, support commitments, and
design decisions before implementation. A separate Issue is not required for
every small documentation correction or narrow maintenance fix.

Use short imperative Issue and pull request titles in the form
`<area>: <summary>`. Stable areas are `build`, `docs`, `tests`, `ci`, `release`,
and `meta`. Bug reports should include the environment, reproduction steps,
expected and actual results, and relevant output. Maintenance proposals should
state the problem, scope, non-goals, and observable completion criteria.

Record meaningful follow-up work and link related Issues when practical. Do
not close an Issue if a pull request addresses only part of it. This practice
does not independently authorize coding agents to create external Issues;
external actions remain subject to the user's authorization.

## Development Workflow

1. Start from an up-to-date `main` and create a topic branch.
2. Make the smallest complete change addressing one maintenance outcome.
3. Run checks relevant to the affected behavior and open a focused pull request.
4. Confirm required GitHub checks pass before merging.
5. Merge with a merge commit, then delete the merged branch when no longer needed.

Do not commit normal development changes directly to `main`, or squash or
rebase pull requests into it. Merge commits preserve PR boundaries and the
individual commits; keep those commits understandable.

Use English for tracked shared documentation, code comments, commits, Issues,
and pull requests. Follow existing code style, prefer readable narrow changes,
avoid unnecessary dependencies, and do not revert unrelated user changes.

## Build and Test

The build needs a C compiler, GNU Fortran, and X11/Xaw/Xmu/Xt development
libraries even for display-independent tests. GNU Fortran compatibility flags
are enabled by default through `UGS_F77_COMPAT`; the build also has
platform-specific flags. Do not assume other compilers are supported.
Dependency installation and configuration options are documented in the README.

A display-independent baseline is:

```bash
cmake -S . -B build -DBUILD_TESTING=ON
cmake --build build --parallel
ctest --test-dir build -LE x11 --output-on-failure
```

For X11 changes, also test with an accessible X server. On headless Linux:

```bash
xvfb-run --auto-servernum ctest --test-dir build --output-on-failure
```

With an existing display, run CTest without the Xvfb wrapper. The visual golden
image comes from Ubuntu/Xvfb and exact comparison is environment-sensitive.
Record that limitation rather than silently updating the golden image to make
a failure pass. `UGS_ENABLE_GUI_SMOKE=OFF` excludes only `01_smoke` and
`03_visual_smoke`; `02_tryxw` still needs X11.

For offline verification, provide `archives/ugs.tar.gz` and use a separate tree:

```bash
cmake -S . -B build-offline -DNET_FETCH=OFF -DBUILD_TESTING=ON
cmake --build build-offline --parallel
ctest --test-dir build-offline -LE x11 --output-on-failure
```

Select additional checks according to the change:

- source acquisition: local input, cache, fresh download, failure cases, and
  explicit offline configuration;
- compatibility patches: relevant regressions and source regeneration;
- font/PostScript changes: relevant display-independent output checks;
- X11 changes: the UGS drawing test and relevant harness/visual checks;
- packaging: staged installation and downstream package verification below;
- CI/platform changes: the closest local equivalent and remaining GitHub checks.

Run regression tests for behavior changes. Keep expectations tied to the
intended behavior, use isolated test output, and avoid exhaustive upstream
coverage claims. The README describes current tests and their limitations.
Linux CI runs smoke tests under Xvfb; macOS CI currently builds but executes
only package verification, not the smoke-labeled font, PostScript, or X11 tests.
Report checks actually run, results, and relevant checks that could not run.
Do not report a full GUI pass based on display-independent checks alone.

## Upstream Sources and Generated Files

Do not commit downloaded archives, extracted sources, build trees, staging
prefixes, or generated files unless a reviewed change explicitly requires it.
Keep extracted sources under `build/vendor` and generated/patched sources,
internal headers, and assets under `build/generated`.

Implement compatibility patches in `cmake/PrepareUgsSources.cmake` or other
appropriate repository-owned build logic. Editing generated copies is not a
reproducible fix. Explain why a patch is needed and verify the affected behavior.

Review source changes, versions, notices, and build/test behavior together when
refreshing upstream inputs. Do not change the pinned hash simply to accept an
unexplained mismatch. Currently only new downloads are hash-checked; local and
cached archives are not rechecked. Review their hashes explicitly when relying
on them as verification inputs. No unverified-archive override is provided.
`NET_FETCH=OFF` requires a local archive; the download cache alone is insufficient.

## Public Package Compatibility

Treat `ugs`, `ugs::ugs`, package version metadata, and transitive link/usage
requirements as public interfaces. Keep names stable where practical.

For changes to installation, exports, target properties, dependencies, or
relocation behavior, install to a clean staging prefix and verify a consumer:

```bash
cmake --install build --prefix "$PWD/build/stage"
cmake -S examples/cmake -B build/package-consumer \
  -DCMAKE_PREFIX_PATH="$PWD/build/stage"
cmake --build build/package-consumer --parallel
ctest --test-dir build/package-consumer --output-on-failure
```

The example discovers `ugs::ugs`, calls UGS through the installed package, and
validates generated PostScript output without requiring an X server. It is a
focused compatibility check, so report any additional platform, dependency, or
graphics verification relevant to the change.

Each installation replaces the build tree's install manifest, including the
install performed by `package_smoke`. Do not assume that a later `uninstall`
still refers to an earlier user-local installation.

## Documentation and Agent Guidance

Update user-facing build, installation, package, and support instructions when
they change. `NET_FETCH` defaults to ON; offline examples explicitly pass
`-DNET_FETCH=OFF`. Update layout and cleanup descriptions together.

Keep long-lived documents self-contained. Issues and PRs record decisions and
history but must not replace an explanation of the current contract. Link to
upstream manuals when appropriate rather than copying them.

The tracked root `AGENTS.md` contains stable scope, boundaries, verification
principles, and pointers to canonical documents. Detailed development/release
procedures belong here, user workflows and current test descriptions in the
README, and security reporting in `SECURITY.md`. Do not duplicate these in agent
instructions. Personal or machine-specific instructions belong outside the
repository. An ignored replacement for the root `AGENTS.md` is not the normal
extension mechanism; it can replace rather than compose with shared guidance.

## CI and Dependency Maintenance

Preserve required checks and least-privilege access when modifying workflows.
Review action/dependency changes and their verification impact. Current UGS CI
uses version-tagged Actions; SHA pinning, explicit permissions, timeouts, and
concurrency improvements are not yet fully implemented. Do not present them as
existing guarantees or copy another project's dependency automation policy.

Required checks are identified by job name. If job names change, update and
verify the default-branch ruleset. Keep release-note categories synchronized
with actual labels in `.github/release.yml`.

## Commits and Pull Requests

Use short imperative commit subjects: `<area>: <summary>`. Choose the stable
area best describing the outcome. An optional body should explain why the
change matters, wrapped at a readable width. Mention version bumps explicitly.

Use the PR template to describe the problem and result, related Issue,
verification actually performed, compatibility/package impact, and documentation
changes. Apply at least one relevant release-note label when practical:
`build`, `ci`, `tests`, `docs`, or `release`. A partial fix should use a related
Issue reference rather than a closing keyword.

Review considers scope, correctness, portability, reproducibility,
maintainability, and verification proportional to the risk.

## Versioning and Releases

Use full semantic repository versions and `vX.Y.Z` tags. Keep root
`project(VERSION ...)`, generated package metadata, and release tag aligned.
These identify this repository's release, not the upstream source version.

Use patch releases for narrow maintenance, documentation, packaging, and
compatibility fixes. Use minor releases for meaningful workflow, CI,
installation/export improvements, or larger maintenance milestones.

1. Prepare a focused release PR containing the version bump and necessary
   version-sensitive documentation changes.
2. Verify relevant builds, tests, and installed-package behavior.
3. Merge after all required checks pass.
4. Confirm CI succeeds on the resulting release commit on `main`.
5. Tag that commit with the matching `vX.Y.Z` tag and create a GitHub Release.

Use GitHub-generated release notes by default and keep categories aligned with
PR labels. Do not duplicate release notes in the README. Related cleanup may
join an unreleased version before tagging; do not retag a published release.
