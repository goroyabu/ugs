# UGS CMake Build

This repository provides a CMake-based build, test, install, and package
workflow for the upstream **UGS (Unified Graphics System)** Fortran/C library.
It is intended for users who need to build legacy UGS and link it into their
own programs.

The project maintains source acquisition, compatibility patches, portability,
and selected verification. It does not develop new upstream graphics features
or claim to test every UGS API or device driver.

## What This Repository Provides

- The static `libugs` library (`libugs.a` on current Unix platforms)
- An installed CMake package with the `ugs::ugs` library target
- An optional legacy interactive `xwtest` executable
- X11 smoke checks and selected font and PostScript regression tests
- Linux and macOS CI with different execution coverage, described below
- Online source acquisition by default, with an optional offline workflow

The build selects `ugs.tar.gz` from the RIKEN archive URL recorded in
[`CMakeLists.txt`](CMakeLists.txt) and uses its `src.2.10e` source tree.
The CMake project/package version and `vX.Y.Z` release tags identify this
maintenance repository's releases, not the upstream UGS source version.

## Quick Start

### Prerequisites

- CMake: the build declares a minimum of 3.15; that minimum is not currently
  exercised in CI. Verification is tracked in [#22](https://github.com/goroyabu/ugs/issues/22).
- A C compiler and GNU Fortran. Other Fortran compilers are not currently
  verified; the build includes platform-specific compiler flags.
- A build tool supported by CMake, such as Make. Generator coverage is not
  currently comprehensive.
- X11 development headers and libraries, including X11, Xaw, Xmu, and Xt.
- Network access for initial source acquisition unless a local archive is provided.

X11 development libraries are required to build UGS even when only PostScript
output or display-independent tests are needed. An accessible X server is
needed when running XWINDOW programs and X11 tests, not for compilation or
the display-independent tests.

On Ubuntu, the current CI installs:

```bash
sudo apt-get update
sudo apt-get install -y gfortran libx11-dev libxaw7-dev libxmu-dev libxt-dev xvfb
```

On macOS, the current CI uses Homebrew libraries:

```bash
brew install gcc libx11 libxaw libxmu libxt
```

When CMake needs help finding Homebrew dependencies, add
`-DCMAKE_PREFIX_PATH="$(brew --prefix)"` to configuration. If the Fortran
compiler is not found, set `FC` to the installed GNU Fortran executable before
the first configuration. Running X11 programs locally additionally needs an
X server, such as XQuartz, and its actual `DISPLAY` setting.

### Build and Install

Run from the repository root:

```bash
cmake -S . -B build
cmake --build build --parallel
cmake --install build --prefix "$HOME/.local"
```

Network fetching is enabled by default with `NET_FETCH=ON`. A user-provided
archive takes precedence; otherwise the build reuses a downloaded archive or
downloads it during configuration. See [Offline Build](#offline-build) for
acquisition and integrity boundaries.

The default build includes test executables but does not run them. Run the
appropriate checks under [Tests](#tests) after building.

On conventional Unix installations, primary installed files include:

```text
$HOME/.local/lib/libugs.a
$HOME/.local/lib/cmake/ugs/ugsConfig.cmake
$HOME/.local/lib/cmake/ugs/ugsConfigVersion.cmake
$HOME/.local/lib/cmake/ugs/ugsTargets.cmake
```

The library directory follows CMake's GNUInstallDirs settings and may differ.
With `UGS_BUILD_XWTEST=ON`, installation also includes `bin/xwtest`.
Test executables and generated internal include files are not installed as
public interfaces.

## Using the Installed CMake Package

The package is discovered with `find_package(ugs CONFIG REQUIRED)` and exports
`ugs::ugs`. A consumer links its own target using
`target_link_libraries(my_program PRIVATE ugs::ugs)`. Enable the languages
needed by the consumer, including Fortran for Fortran sources.

For a non-system installation, pass `-DCMAKE_PREFIX_PATH="$HOME/.local"`
when configuring the consumer. Do not treat `build/vendor` or `build/generated`
as installed include paths.

The existing [`tests/package_smoke`](tests/package_smoke/CMakeLists.txt)
project demonstrates package discovery and building a trivial C consumer:

```bash
cmake -S tests/package_smoke -B build/package-example \
  -DCMAKE_PREFIX_PATH="$HOME/.local"
cmake --build build/package-example --parallel
```

This consumer does not call UGS functions. It checks basic package discovery
and target linkage, not a complete Fortran application's runtime dependencies
or graphics output. A public executable UGS example and stronger installed-
package acceptance are tracked in [#18](https://github.com/goroyabu/ugs/issues/18).

## Tests

Configure with `BUILD_TESTING=ON` (the default), then build before running
CTest. CTest executes checks; it does not build their executables for you.

| Test | What it checks | X server needed |
| --- | --- | --- |
| `01_smoke` | The X11 harness opens a viewable window and reports the expected message | Yes |
| `02_tryxw` | A Fortran program exercises the UGS XWINDOW drawing path | Yes |
| `03_visual_smoke` | The X11 harness captures a frame and compares it exactly with a golden PPM image | Yes |
| `04_duplex_glyph` | DUPLEX glyph lookup produces nonempty, distinguishable strokes for two characters | No |
| `05_postscript_filename` | Drawing creates the requested nonempty PostScript file with a recognizable header | No |
| `package_smoke` | Installation into a build-tree prefix, package discovery, and a trivial consumer build | No |

The X11 harness checks are not comprehensive UGS rendering tests.
`02_tryxw` prints UGS error state but does not explicitly assert those values.
The PostScript regression checks the file and header, not full rendering
correctness. Coverage and stronger contracts are tracked in
[#21](https://github.com/goroyabu/ugs/issues/21).

### Without an X Server

Exclude tests labeled `x11`:

```bash
cmake --build build --parallel
ctest --test-dir build -LE x11 --output-on-failure
```

This runs the font, PostScript, and package checks. It does not remove the
build-time X11 library requirement.

### With an X Server

With a working `DISPLAY`, run all registered tests:

```bash
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

On headless Linux, use Xvfb:

```bash
xvfb-run --auto-servernum ctest --test-dir build --output-on-failure
```

The visual golden image was created under Ubuntu/Xvfb. Exact comparison can
fail in a different rendering environment; see
[#7](https://github.com/goroyabu/ugs/issues/7). For local X11 checks without
that comparison, add `-E '^03_visual_smoke$'` to the CTest command.

Tests normally inherit `DISPLAY`. Use the display supplied by your X server
rather than assuming `:0`. `XWTEST_SMOKE_DISPLAY` can override it during
configuration; leave this unset when relying on the display chosen by Xvfb.

`UGS_ENABLE_GUI_SMOKE=OFF` skips registration of **only** `01_smoke` and
`03_visual_smoke`. It leaves the X11-dependent `02_tryxw` registered and still
builds the harness when testing is enabled. Use `-LE x11` for display-independent
execution. Package checks alone can be selected with `-L package`.

## Offline Build

Place `ugs.tar.gz` under `archives/`, then explicitly disable network fetching:

```bash
cmake -S . -B build-offline -DNET_FETCH=OFF -DBUILD_TESTING=ON
cmake --build build-offline --parallel
ctest --test-dir build-offline -LE x11 --output-on-failure
```

The last command verifies only the display-independent subset. X11 tests can
also be run using the display setup described above.

`ARCHIVE_DIR` selects the user-provided archive directory; `DOWNLOAD_CACHE_DIR`
selects the downloaded-archive cache. Both default under the repository root.
With `NET_FETCH=ON`, local archives are preferred, then the download cache,
then a new download. With `NET_FETCH=OFF`, only the local archive location is
used: an existing `.cache/downloads/ugs.tar.gz` alone is not sufficient.
Archives and downloaded sources are not tracked in Git.

### Current Integrity Verification

New downloads are checked against the pinned `UGS_SRC_SHA256` value. The current
implementation does **not** recheck local archives or existing download-cache
files. Strict verification across every acquisition path is tracked in
[#19](https://github.com/goroyabu/ugs/issues/19).

To inspect an existing archive's hash on macOS or Linux, run
`shasum -a 256 archives/ugs.tar.gz` and compare it with the pin in
[`CMakeLists.txt`](CMakeLists.txt). Do not change the expected hash merely to
accept an unexplained mismatch. A reviewed upstream refresh and a deliberate
local experiment are different operations; their policy is also tracked in #19.

## Configuration Options

| Setting | Default | Effect and limitations |
| --- | --- | --- |
| `NET_FETCH` | `ON` | Allows download-cache use and network fallback when a local archive is missing |
| `ARCHIVE_DIR` | `<source>/archives` | Directory for user-provided `ugs.tar.gz` |
| `DOWNLOAD_CACHE_DIR` | `<source>/.cache/downloads` | Download cache used with `NET_FETCH=ON` |
| `UGS_SRC_SHA256` | Pin in `CMakeLists.txt` | Expected hash for new downloads; currently user-configurable in the CMake cache |
| `BUILD_TESTING` | `ON` | Builds test executables and registers tests; `OFF` disables both |
| `UGS_ENABLE_GUI_SMOKE` | `ON` | Registers `01_smoke` and `03_visual_smoke`; does not control `02_tryxw` |
| `UGS_BUILD_XWTEST` | `OFF` | Builds and installs the optional interactive legacy `xwtest` sample |
| `UGS_F77_COMPAT` | `ON` | Adds GNU Fortran legacy compatibility flags, including argument-mismatch allowance; applied only to GNU Fortran |
| `XWTEST_SMOKE_DISPLAY` | Empty | Overrides `DISPLAY` for X11 tests; otherwise the runtime environment is inherited |

Pass settings as `-DNAME=value` when configuring. Settings persist in that
build directory's CMake cache; explicitly reset an override or use a fresh
build directory when switching workflows.

## Supported Environments

Workflow definitions are the source of truth for current CI coverage:

| Workflow/platform | Verification |
| --- | --- |
| [CI](.github/workflows/ci.yml), `ubuntu-latest`, C compiler and GNU Fortran | Build, `02_tryxw` under Xvfb, font/PostScript regressions, installation, package smoke |
| [CI](.github/workflows/ci.yml), `macos-latest`, Apple toolchain and GNU Fortran | Build, installation, package smoke; no smoke-labeled tests are executed |
| [GUI Smoke](.github/workflows/gui-smoke.yml), `ubuntu-latest` | Separate manual/scheduled diagnostic checks for `01_smoke` and `03_visual_smoke` |

GUI Smoke is not a required PR gate. Workflow configuration does not guarantee
that scheduled execution is currently active; check
[Actions](https://github.com/goroyabu/ugs/actions) for current status.
Operational recovery/policy is tracked in
[#5](https://github.com/goroyabu/ugs/issues/5). Coverage gaps, minimum CMake
version, and environment selection are tracked in
[#22](https://github.com/goroyabu/ugs/issues/22).

## Known Limitations

- Windows, cross-compilation, other Fortran compilers, and all historical UGS
  drivers are not currently covered by the verification promise.
- Only a static library is provided; this build always requires X11 libraries.
- XWINDOW, selected font behavior, and PostScript filename handling have
  targeted checks, not comprehensive API or rendering coverage.
- Installed-package testing does not yet exercise a real UGS call.
- Legacy compiler warnings remain; see [#8](https://github.com/goroyabu/ugs/issues/8).

## Directory Layout and Cleanup

`build` is the example build directory, not a required name. `build-offline`
and other build directories have their own `vendor` and `generated` trees.

| Path | Purpose |
| --- | --- |
| `archives/` | User-provided upstream archives |
| `.cache/downloads/` | Downloaded-archive cache shared by default across build directories |
| `build/vendor/` | Extracted upstream sources |
| `build/generated/` | Build-generated files, including patched UGS sources, internal headers, and assets |
| `tests/` | Maintained test sources and CTest support |
| `build/test-artifacts/` | Test output such as captured images and PostScript files |

Maintain compatibility changes in
[`cmake/PrepareUgsSources.cmake`](cmake/PrepareUgsSources.cmake), not by editing
generated copies. Regeneration and incremental-build verification are tracked
in [#20](https://github.com/goroyabu/ugs/issues/20).

```bash
cmake --build build --target clean_downloads
```

Despite its name, `clean_downloads` removes the current build's `vendor` and
`generated` trees **as well as** the configured download cache. It preserves
user-provided archives. Other build directories may share that cache.
Cleanup/rebuild recovery is under review in #20; a fresh build directory is
the clearest way to start a new configuration.

```bash
cmake --build build --target uninstall
```

`uninstall` removes files listed in that build directory's `install_manifest.txt`.
Keep the build directory used for installation. A later installation from the
same build tree, including `package_smoke`'s temporary install, replaces the
manifest, so it may no longer describe your earlier installation prefix.

## Troubleshooting

| Symptom | Check or action |
| --- | --- |
| Required archive missing with `NET_FETCH=OFF` | Place `ugs.tar.gz` in `ARCHIVE_DIR`; the download cache alone is not searched in this mode |
| Download/hash failure | Check the source URL, connectivity, and expected pin; replace an invalid archive after investigating the mismatch |
| C or Fortran compiler not found | Install the compilers and select `CC`/`FC` before configuring a fresh build tree |
| X11 dependency not found | Install X11, Xaw, Xmu, and Xt development libraries; on Homebrew add its prefix to `CMAKE_PREFIX_PATH` |
| Cannot open display | Use an accessible X server's actual `DISPLAY`, use Xvfb on Linux, or select `-LE x11` for display-independent tests |
| Visual comparison fails | Inspect `build/test-artifacts/03_visual_smoke.ppm` and the golden image; account for the reference environment before changing expectations |

Maintainer/contribution guidance is being organized in
[#16](https://github.com/goroyabu/ugs/issues/16), detailed test contracts in
[#21](https://github.com/goroyabu/ugs/issues/21), and repository/upstream license
notices in [#23](https://github.com/goroyabu/ugs/issues/23). These links track
unfinished guidance rather than asserting that the documents already exist.
