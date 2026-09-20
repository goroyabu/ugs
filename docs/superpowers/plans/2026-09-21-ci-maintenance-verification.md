# CI Maintenance Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete Issue #22 with explicit, supported CI paths for display-independent, X11, offline, minimum-CMake, and installed-package verification.

**Architecture:** Keep existing CTest registration compatible and use labels to select environment-dependent tests. Extend the existing CI workflow with focused jobs and shared command shapes, then update documentation to match only the checks that the workflow actually performs.

**Tech Stack:** CMake 3.15+, CTest, GitHub Actions YAML, GNU Fortran, X11/Xvfb, shell

---

### Task 1: Record workflow policy expectations

**Files:**
- Create: `tests/ci/verify_workflows.cmake`
- Modify: `tests/CMakeLists.txt`

- [ ] **Step 1: Add a failing workflow-policy test**

Create a CMake script that reads `.github/workflows/ci.yml` and
`.github/workflows/gui-smoke.yml` and fails unless both declare read-only
contents permission, concurrency, job timeouts, and commit-SHA-pinned Actions.
It must additionally require the main CI text to contain `NET_FETCH=OFF`,
`-LE x11`, `-L x11`, and `3.15.7`.

- [ ] **Step 2: Register and run the test**

Register `ci.workflow_policy` with labels `ci;policy`, configure a fresh test
tree, and run `ctest --test-dir <tree> -R '^ci.workflow_policy$'`. Expect failure
because the workflow policy is not yet present.

- [ ] **Step 3: Commit the failing contract test**

Commit as `tests: define CI workflow policy contract`.

### Task 2: Implement CI policy and verification paths

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `.github/workflows/gui-smoke.yml`
- Modify: `CMakeLists.txt`
- Modify: `tests/package_smoke/run_package_smoke.cmake`

- [ ] **Step 1: Add top-level permissions and concurrency**

Declare `permissions: contents: read` and a workflow/event concurrency group
that cancels only superseded pull-request runs.

- [ ] **Step 2: Pin Actions and add timeouts**

Pin checkout v6.0.2 to
`de0fac2e4500dabe0009e67214ff5f5447ce83dd` and upload-artifact v7.0.0 to
`bbbca2ddaa5d8feaa63e36b76fdaad77386f024f`. Set every job timeout to 30
minutes.

- [ ] **Step 3: Expand the supported-platform matrix**

Keep the required display names unchanged, run `ctest -LE x11` on both OSes,
and run `xvfb-run --auto-servernum ctest -L x11` only on Linux. Preserve the
clean staged install and installed-package example.

- [ ] **Step 4: Add offline verification**

Download `ugs.tar.gz` to a runner-temporary archive directory, verify
`27bc46e975917bdf149e9ff6997885ffa24b0b1416bdf82ffaea5246b36e1f83`, configure
with `NET_FETCH=OFF` and explicit `ARCHIVE_DIR`, then build, run display-
independent tests, install, and run the downstream example.

- [ ] **Step 5: Add minimum-CMake verification**

Install official CMake 3.15.7 for Linux with SHA256
`8456a10ac2fd0dc97d13aa4753431a232cf32aecb0976541f7bf867a3f90ec57`, then
configure, build, test, install, and run the downstream example.

- [ ] **Step 6: Preserve CMake 3.15 compatibility**

Replace nested package-smoke use of `ctest --test-dir` with
`cmake -E chdir <binary-dir> <ctest> --output-on-failure`, and update the
`UGS_ENABLE_GUI_SMOKE` help text to name `01_smoke` and `03_visual_smoke`.

- [ ] **Step 7: Run the policy test and local build tests**

Run the focused policy test, a clean configure/build, `ctest -LE x11`, and the
package test. Expect all checks to pass.

- [ ] **Step 8: Commit the implementation**

Commit as `ci: align maintenance verification`.

### Task 3: Synchronize public documentation

**Files:**
- Modify: `README.md`
- Modify: `CONTRIBUTING.md`
- Modify: `tests/README.md`

- [ ] **Step 1: Update supported-environment descriptions**

Document fixed Linux/macOS runner coverage, display-independent execution on
both, Linux X11 execution, the offline job, and the tested CMake 3.15.7
baseline.

- [ ] **Step 2: Clarify controls and boundaries**

State that `UGS_ENABLE_GUI_SMOKE` controls only `01_smoke` and
`03_visual_smoke`, while CTest's `x11` label selects all X11-dependent tests.
Keep broader functional expansion assigned to Issue #36 and graphical policy
assigned to Issues #5 through #7.

- [ ] **Step 3: Run documentation and workflow policy checks**

Search for obsolete statements that macOS runs package verification only or
that minimum CMake is untested. Run `ci.workflow_policy` again.

- [ ] **Step 4: Commit documentation**

Commit as `docs: describe expanded CI coverage`.

### Task 4: Complete local and remote verification

**Files:**
- Verify only

- [ ] **Step 1: Run a fresh online build and display-independent suite**

Configure outside the source tree with testing enabled, build, and run
`ctest -LE x11 --output-on-failure`.

- [ ] **Step 2: Run a fresh local offline path**

Configure a separate tree with `NET_FETCH=OFF` and the known local archive,
build, run display-independent CTest, and confirm package acceptance.

- [ ] **Step 3: Validate repository state**

Run YAML parsing, `git diff --check`, inspect the complete diff, and confirm no
generated artifacts are tracked.

- [ ] **Step 4: Push and open the pull request**

Use the repository PR template, link Issue #22 with a closing keyword, apply
`ci` and `tests` labels, and report the exact local verification.

- [ ] **Step 5: Inspect GitHub checks and required-check rules**

Confirm every new CI job passes. Verify the default-branch ruleset still names
the unchanged required checks `Build and test (ubuntu-latest)` and
`Build and test (macos-latest)`; update it only if GitHub reports different
final job contexts.

