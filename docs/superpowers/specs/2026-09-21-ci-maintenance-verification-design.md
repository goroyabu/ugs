# CI Maintenance Verification Design

## Goal

Complete Issue #22 by making CI exercise the repository's documented Linux,
macOS, offline, minimum-CMake, package-consumer, and X11 verification promises
with explicit operational policy.

## Scope boundary

This change improves how existing tests are selected and executed. It does not
add the broader UGS functional contracts tracked in Issue #36, expand the OS
matrix to match F2C, add sanitizers, or promote the diagnostic GUI workflow to
a required check.

## Test selection

`BUILD_TESTING` remains the switch that builds and registers tests.
`UGS_ENABLE_GUI_SMOKE` remains compatible and controls only the repository-owned
`01_smoke` and `03_visual_smoke` tests. Its help text will name those tests
explicitly. The actual UGS XWINDOW test, `02_tryxw`, remains registered and is
selected through its `x11` label.

CI will use `ctest -LE x11` for display-independent execution on Linux and
macOS. Linux will separately use Xvfb with `ctest -L x11`; because the normal CI
configuration disables the repository-owned GUI harness, this runs the actual
UGS XWINDOW path without duplicating the exact visual comparison maintained by
the GUI Smoke workflow.

## CI jobs

The existing required job names, `Build and test (ubuntu-latest)` and
`Build and test (macos-latest)`, remain stable to avoid unnecessary ruleset
changes. Their runner values become explicit fixed images while their display
names remain unchanged.

The main build matrix will:

1. configure and build with network acquisition enabled;
2. run all display-independent tests on both platforms;
3. run X11-labelled tests under Xvfb on Linux;
4. install to a clean staging prefix; and
5. configure, build, and execute the installed-package example.

A Linux offline job will download the pinned archive into an isolated input
directory, verify its SHA256, then configure with `NET_FETCH=OFF` and the
explicit `ARCHIVE_DIR`. Configuration, build, display-independent CTest,
installation, and downstream package use will all occur through the offline
selection path. Network use before configuration supplies the required local
input; the build itself must not fall back to a cache or download.

A Linux minimum-version job will install the official CMake 3.15.7 binary,
verify its published SHA256, show the active version, and exercise configure,
build, display-independent tests, installation, and downstream use. Any CMake
invocation that currently relies on newer command-line syntax will be adjusted
to a 3.15-compatible form while preserving behavior.

The existing Make/Ninja incremental-preparation matrix remains separate.

## Workflow policy

Both CI workflows will declare read-only repository contents permission, a
30-minute job timeout, and concurrency groups that cancel superseded pull
request runs while retaining push and scheduled runs. Third-party Actions will
be pinned to the exact commits behind their currently selected release tags,
with comments recording the readable versions.

## Documentation

The README and CONTRIBUTING guide will describe actual CI coverage after the
change: display-independent tests on Linux and macOS, the Linux X11 split,
the explicit offline job, and verified CMake 3.15.7 baseline. They will retain
the distinction between required CI and diagnostic GUI Smoke.

## Verification

Local checks will cover YAML parsing, configure/build, display-independent
CTest, package acceptance, and workflow-policy assertions. GitHub PR checks
will provide the authoritative Linux, macOS, offline, minimum-CMake, and Xvfb
evidence. Required-check rules will be inspected after final job names are
known; because the two required names remain stable, no ruleset mutation is
expected.
