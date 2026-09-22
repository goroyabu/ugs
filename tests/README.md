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
| The built-in extended fonts and documented text-layout queries remain usable | `04_font_contract` | SIMPLEX and DUPLEX return finite, nonempty, distinct strokes for the same character; a Greek modifier changes the glyph; `LAST` and `NEXT` return the expected fixed-size positions; insufficient output capacity reports the documented recoverable error |
| The POSTSCR driver honors its requested output name and preserves two requested line paths | `05_postscript_filename` | A fresh PostScript file has one completed page and the expected two move/line/stroke command sequences under explicit device geometry |
| The documented POSTSCR lifecycle exposes stable open and active device state | `06_postscript_lifecycle` | `UGINFO` reports no device before open, the requested identifier and POSTSCR properties while open, and no device after close; each phase has a clear UGS error state |
| An invalid two-point polygon reports a recoverable documented error | `07_invalid_polygon_error` | The process continues and `/UGERRD/` reports level 2, subroutine `UGPFIL`, and index 1 |
| Drawing-space and window state round-trip through their public interfaces | `08_view_state` | `UGDSPC` and `UGWDOW` return the non-square drawing space, affinity, distinct view port, and world window that were set, within 16 scaled single-precision epsilons |
| The current window maps and clips line geometry when a segment is written | `09_window_clipping` | Focused PostScript commands show an inside line at its mapped coordinates, a crossing line clipped to both window edges, and no path for an entirely outside line |
| Extended text follows the documented stroke-conversion drawing path | `10_extended_text` | `UGXTXT` and `UGCTOL` followed by `UGPLIN` produce the same nonempty visible PostScript line geometry for a representative extended string |
| Public 3D view and projection state remains usable through a representative line path | `11_3d_projection` | `UG3WRD` and `UG3TRN` round-trip reviewed state; a new picture preserves the 3D world state and resets the transformation state; `UG3PLN` produces the reviewed parallel-projection commands and a distinct visible point projection |
| An installed consumer can discover `ugs::ugs`, link it, and use a representative PostScript path | `package_smoke` | A clean staged install and consumer build succeed, and a fresh, nonempty `ugs-example.ps` has a PostScript header |
| Selected upstream input is authenticated before use | `archive_hash.*` | Local, cached, and downloaded inputs obey the pinned SHA256 policy and the documented experimental exception |
| Prepared upstream sources are incremental and generator-independent | `source_preparation.incremental` | An unchanged rebuild does not rewrite outputs, and a changed preparation input regenerates them with Make or Ninja |
| CI retains its documented security and maintenance controls | `ci.workflow_policy` | Workflow text declares read-only permissions, cancellation policy, timeouts, pinned Actions, display selection, offline verification, and minimum-CMake coverage |

These expectations are based on reviewed public workflows and semantic output,
not on incidental full-file snapshots. The visual harness image is the one
intentional snapshot: its exact-comparison environment and limitations are
documented in the root README and are subject to the separate visual comparison
policy described below.

## Contract Sources and Oracles

Functional cases prefer the pinned upstream programming manual and its routine
contracts, followed by upstream interface descriptions and examples, reviewed
behavior of the pinned source, and independently reproduced observations. The
font selection, text conversion and positioning, POSTSCR lifecycle, device
properties, invalid-polygon error tuple, drawing-space and window state,
write-time clipping, line output, extended-text equivalence, and public 3D view,
transformation, and polyline routines in cases 04 through 11 are based on
`doc/ugpgmdoc.txt` from the pinned upstream archive.
SIMPLEX minimizes the strokes used for each extended character; DUPLEX adds
doubled strokes and serifs. Both are UGS stroke fonts rather than
operating-system fonts. Source review is used to reconcile that historical
manual with the acquired implementation; observed behavior alone does not
create a compatibility promise.

Fixtures are written for this repository rather than copied from upstream
examples. Oracles check the narrowest stable public result available: device
state, numeric text positions, stroke coordinates, and UGS error values for
direct routine contracts, and selected page and drawing commands for
PostScript output. The extended-text case compares only the visible drawing
commands from the two documented construction paths. The 3D case fixes the
parallel-projection command sequence but checks point projection by command
shape and visible divergence, avoiding a broad coordinate snapshot. Complete
internal segment arrays, complete PostScript files, and rendered images are not
snapshots unless a separate reviewed contract requires them.

The state round-trip and text-layout checks reject non-finite values and allow
16 single-precision epsilons scaled to the expected magnitude. This leaves a
small margin for compiler and platform rounding while remaining far below the
deliberate differences among the tested sizes, affinity, coordinates, and
layout positions.

The representative functional domains are lifecycle and error handling, 2D
primitives and coordinate/window behavior, fonts and text, file-driver output,
and selected 3D or higher-level operations. The current baseline covers only a
small part of each: lifecycle and recoverable errors have direct contracts;
line output has focused coordinate mapping and clipping coverage; and font
selection, fixed-size layout queries, one conversion boundary, and a
representative extended-text drawing path have focused coverage. Broader 2D
primitives and segment operations, comprehensive font and text behavior, EPSF,
standalone projection helpers, and higher-level 3D operations remain under
Issue #36.

## Failure and Isolation Rules

UGS reports an error level from 1 (minor) through 4 (terminal). The
representative XWINDOW test requires level zero after each checked operation;
minor errors and warnings therefore fail the test as well. Some terminal UGS
errors stop a Fortran program with a successful process exit status, so CTest
also rejects the standard UGS error diagnostic where applicable.
`04_font_contract` and `07_invalid_polygon_error` deliberately cause documented
level-2 errors and check the full `/UGERRD/` tuple after control returns to the
caller.

File-producing tests remove their prior output before invoking the behavior
under test. Visual, PostScript, package-consumer, archive, and source-preparation
artifacts use build-tree locations so a previous run cannot satisfy a later
test and parallel source trees do not share results.

## Coverage Boundaries

The current baseline deliberately does not guarantee:

- pixel output from the UGS XWINDOW drawing path in `02_tryxw`;
- graphical behavior of every UGS API or historical device driver;
- byte-for-byte PostScript output, page appearance, or printer compatibility;
- POSTSCR primitives other than representative straight lines;
- the historical `UGINFO` `DIMENSION` query or the pinned source's
  `DPHYSIZE` extension, whose mismatch is not treated as a supported contract;
- every glyph, font metric, text-layout option, or malformed-input case;
- `UGTEXT` hardware-character generation, device-specific font substitution,
  exact glyph appearance, or complete `UGXTXT` behavior;
- EPSF behavior, whose available implementation is not described by the
  programming-manual POSTSCR section used for the current contracts;
- shields, broader window/clipping combinations, or segment operations;
- standalone `UGTRAN` and `UGPROJ` behavior, broad 3D clipping, 3D text,
  mesh and contour operations, or other higher-level 3D behavior;
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
consumer build. Cases 04 through 11 are display-independent and therefore run
in the normal supported selection without an X server. Broader functional and
graphics contracts are tracked in
[the layered coverage follow-up](https://github.com/goroyabu/ugs/issues/36);
this execution matrix does not expand their scope by itself.
