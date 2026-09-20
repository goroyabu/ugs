# Test Contracts

The maintenance suite checks a small set of repository and UGS behaviors that
are important to supported build, package, and representative graphics paths.
It is not an exhaustive UGS API, driver, rendering, or platform conformance
suite.

## Coverage Map

| Contract | Evidence | Stable result |
| --- | --- | --- |
| The repository-owned Xlib harness can open a viewable window | `01_smoke` | The process succeeds and prints the reviewed viewable-window message |
| A representative UGS XWINDOW lifecycle and line-drawing path completes without a reported UGS error | `02_tryxw` | Initialization, device open and selection, line construction, write, and close complete with error level zero |
| The X11 harness produces the reviewed reference frame in the controlled GUI smoke environment | `03_visual_smoke` | A fresh capture exactly matches `cases/03_visual_smoke/expected.ppm` |
| The DUPLEX font supplies usable, distinct strokes for representative alphabetic and numeric characters | `04_duplex_glyph` | `A` and `2` both produce strokes and do not produce identical coordinates |
| The POSTSCR driver honors its requested output name and writes recognizable PostScript | `05_postscript_filename` | A fresh, nonempty `postscript-output.ps` begins with `%!PS-Adobe-` |
| An installed consumer can discover `ugs::ugs`, link it, and use a representative PostScript path | `package_smoke` | A clean staged install and consumer build succeed, and a fresh, nonempty `ugs-example.ps` has a PostScript header |
| Selected upstream input is authenticated before use | `archive_hash.*` | Local, cached, and downloaded inputs obey the pinned SHA256 policy and the documented experimental exception |
| Prepared upstream sources are incremental and generator-independent | `source_preparation.incremental` | An unchanged rebuild does not rewrite outputs, and a changed preparation input regenerates them with Make or Ninja |
| CI retains its documented security and maintenance controls | `ci.workflow_policy` | Workflow text declares read-only permissions, cancellation policy, timeouts, pinned Actions, display selection, offline verification, and minimum-CMake coverage |

These expectations are based on reviewed public workflows and semantic output,
not on incidental full-file snapshots. The visual harness image is the one
intentional snapshot: its exact-comparison environment and limitations are
documented in the root README and are subject to the separate visual comparison
policy described below.

## Failure and Isolation Rules

UGS reports an error level from 1 (minor) through 4 (terminal). The
representative XWINDOW test requires level zero after each checked operation;
minor errors and warnings therefore fail the test as well. Some terminal UGS
errors stop a Fortran program with a successful process exit status, so CTest
also rejects the standard UGS error diagnostic.

File-producing tests remove their prior output before invoking the behavior
under test. Visual, PostScript, package-consumer, archive, and source-preparation
artifacts use build-tree locations so a previous run cannot satisfy a later
test and parallel source trees do not share results.

## Coverage Boundaries

The current baseline deliberately does not guarantee:

- pixel output from the UGS XWINDOW drawing path in `02_tryxw`;
- graphical behavior of every UGS API or historical device driver;
- byte-for-byte PostScript output, page appearance, or printer compatibility;
- every glyph, font metric, text layout, or malformed-input case;
- Windows, cross-compilation, non-GNU Fortran compilers, or shared libraries;
- X11 behavior on macOS CI, where display-dependent tests are not run; or
- F2C language conformance or F2C's project-specific test matrix.

`01_smoke` and `03_visual_smoke` exercise the repository's small, independent
Xlib harness. The harness uses fixed black-and-white primitives and does not
compile upstream UGS sources. These tests do not call the UGS drawing API and
must not be presented as full UGS rendering coverage. `02_tryxw` calls the
actual UGS XWINDOW path, but currently asserts lifecycle and error-free
execution rather than captured pixels.

Image comparison strictness, environment control, and golden-image maintenance
belong to [the visual comparison follow-up](https://github.com/goroyabu/ugs/issues/7).
Expected, actual, and difference artifact presentation belongs to
[the artifact review follow-up](https://github.com/goroyabu/ugs/issues/6).
CI platform selection and scheduling consume this contract but are maintained
separately from the test behavior itself.

## CI Execution

The required Linux and macOS jobs run all tests except those labelled `x11`.
Linux then runs the registered `x11` subset under Xvfb. Normal CI configures
with `UGS_ENABLE_GUI_SMOKE=OFF`, so `01_smoke` and `03_visual_smoke` remain in
the separate diagnostic GUI workflow while `02_tryxw` exercises the actual UGS
XWINDOW path in required Linux CI.

Dedicated Linux jobs repeat the display-independent suite through the
`NET_FETCH=OFF` local-archive path and with CMake 3.15.7. The package test in
each applicable job performs a clean staged installation and downstream
consumer build. Broader functional and graphics contracts are tracked in
[the layered coverage follow-up](https://github.com/goroyabu/ugs/issues/36);
this execution matrix does not expand their scope by itself.
