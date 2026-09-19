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
  exercised in CI.
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

The [`examples/cmake`](examples/cmake) project demonstrates package discovery,
linking through `ugs::ugs`, and running a small Fortran program against the
installed package:

```bash
cmake -S examples/cmake -B build/package-example \
  -DCMAKE_PREFIX_PATH="$HOME/.local"
cmake --build build/package-example --parallel
ctest --test-dir build/package-example --output-on-failure
```

The example calls UGS through the installed target, creates `ugs-example.ps`,
and checks that the result is a nonempty PostScript file. It does not require an
X server. This is a focused installed-package example rather than comprehensive
graphics, API, or platform coverage.

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
| `package_smoke` | Clean staged installation, installed-target discovery, example build and execution, and PostScript output validation | No |

The X11 harness checks are not comprehensive UGS rendering tests.
`02_tryxw` prints UGS error state but does not explicitly assert those values.
The PostScript regression checks the file and header, not full rendering
correctness. The repository does not currently publish a more detailed test-
contract map or claim comprehensive API coverage.

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
fail in a different rendering environment. For local X11 checks without that
comparison, add `-E '^03_visual_smoke$'` to the CTest command. No normalized or
tolerance-based comparison is currently provided.

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
files, so strict verification across every acquisition path is not currently
provided.

To inspect an existing archive's hash on macOS or Linux, run
`shasum -a 256 archives/ugs.tar.gz` and compare it with the pin in
[`CMakeLists.txt`](CMakeLists.txt). Do not change the expected hash merely to
accept an unexplained mismatch. Treat a reviewed upstream refresh and a
deliberate local experiment as different operations. The repository does not
currently provide a supported unverified-archive override.

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
that scheduled execution is currently active; GitHub may disable scheduled
workflows after repository inactivity. Check
[Actions](https://github.com/goroyabu/ugs/actions) for current status and use
manual dispatch when needed. The current CI does not verify the declared
minimum CMake version or a complete offline workflow, and macOS does not run
the smoke-labeled font, PostScript, or X11 tests.

## Known Limitations

- Windows, cross-compilation, other Fortran compilers, and all historical UGS
  drivers are not currently covered by the verification promise.
- Only a static library is provided; this build always requires X11 libraries.
- XWINDOW, selected font behavior, and PostScript filename handling have
  targeted checks, not comprehensive API or rendering coverage.
- Installed-package testing exercises one PostScript path, not the full UGS API
  or X11-backed graphics behavior.
- Legacy C and Fortran compiler warnings remain and are not treated as errors.

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
generated copies. Changes to source-preparation logic and incremental rebuilds
are not currently covered by a dedicated regeneration test.

```bash
cmake --build build --target clean_downloads
```

Despite its name, `clean_downloads` removes the current build's `vendor` and
`generated` trees **as well as** the configured download cache. It preserves
user-provided archives. Other build directories may share that cache. Cleanup
and recovery are not currently covered by a dedicated test; a fresh build
directory is the clearest way to start a new configuration.

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

## Contributing and Security

See [CONTRIBUTING.md](CONTRIBUTING.md) for development, verification, pull request,
and release procedures. [AGENTS.md](AGENTS.md) points coding agents to the same
canonical guidance. Report suspected vulnerabilities privately as described in
[SECURITY.md](SECURITY.md), rather than opening a public Issue.

The test descriptions above state the current verification boundaries; a more
detailed contract map is not yet provided. Repository-owned and upstream-
derived license notices are still being investigated, and this README does not
assign a license to upstream code.
