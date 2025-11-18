# UGS (Unified Graphics System) Modernized Build

This repository wraps the legacy UGS Fortran/C sources in a modern CMake workflow with reproducible source acquisition (local archives first, but able to fall back to remote downloads), out-of-source builds, and a minimal smoke test for the X11 sample.

## Directory Layout

```
.
├─ CMakeLists.txt              # root build definition
├─ archives/                   # place ugs.tar.gz here (preferred local archive)
├─ .cache/downloads/           # download cache when NET_FETCH=ON
├─ build/                      # out-of-source build tree (generated)
├─ vendor/ / generated/        # live under build/, never committed
├─ tests/
│  ├─ CMakeLists.txt           # registers ctest entries
│  └─ cases/01_smoke/
│      ├─ xwindowc_smoke.c     # GUI smoke harness, compiled when enabled
│      └─ expected.txt         # regex checked against xwtest_smoke output
└─ README.md
```

All build artifacts stay under `build/` to keep the source tree clean.

## Archive Acquisition (local + remote fallback)

1. Obtain the upstream archive `ugs.tar.gz` and place it under `archives/`.
2. Alternatively, set `-DUGS_SRC_ARCHIVE=/absolute/path/to/ugs.tar.gz` when running CMake (useful for archives stored elsewhere on the machine).
3. When using remote downloads (`NET_FETCH=ON`), hash pinning is required: `UGS_SRC_SHA256` must be set (it defaults to the known SHA) and is used to verify downloaded archives. For purely local archives, hash pinning is optional.
4. To allow remote downloads (used only when no local archive is found), configure with `-DNET_FETCH=ON`. The downloaded file is verified against `UGS_SRC_SHA256` and stored under `.cache/downloads/` as a cache.
5. If neither a local archive nor NET_FETCH is available, configuration fails with guidance.

## Configure, Build, Install

```bash
cmake -S . -B build
cmake --build build --parallel
cmake --install build --prefix "${HOME}/.local"
```

Key options:
- `UGS_BUILD_XWTEST` (default OFF): build the legacy interactive `xwtest` sample in addition to the smoke harness.
- `BUILD_TESTING` (default ON): always builds the `xwtest_smoke` harness and registers CTest targets; disable with `-DBUILD_TESTING=OFF` only if you want to skip tests entirely.
- `UGS_F77_COMPAT`: enable Fortran 77 compatibility flags (`-fallow-argument-mismatch`).
- `XWTEST_SMOKE_DISPLAY`: override the DISPLAY used by the smoke test (defaults to `$DISPLAY` or `:0`).

> **Note:** X11 headers and libraries must be available on the host. CMake will fail early if it cannot find them—this is expected because UGS relies on X11.

## Tests

Tests are managed with CTest. The main smoke test builds and runs `xwtest_smoke`, which opens an X11 window and waits until it becomes viewable. Its output must match `tests/cases/01_smoke/expected.txt`.

Run tests:
```bash
cmake --build build --target test
# or
ctest --test-dir build -L smoke --output-on-failure
```

Display handling:
- Ensure an accessible X11 server. Locally you can export `DISPLAY=:0` if XQuartz/Xorg is running.
- Headless/CI usage: wrap tests with `xvfb-run --auto-servernum ctest --test-dir build -L smoke`.
- To force a specific display, configure with `-DXWTEST_SMOKE_DISPLAY=:99` (for example) or export `DISPLAY` before running tests.

## Helper Targets

The following helper targets are available:

```
cmake --build build --target clean_downloads  # remove download cache(s) under .cache/downloads/
cmake --build build --target uninstall        # run cmake_uninstall.cmake
```

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|--------------|------------|
| `UGS source not available` | Archive missing and NET_FETCH=OFF | Place `ugs.tar.gz` under `archives/` or reconfigure with `-DNET_FETCH=ON`. |
| `SHA256 mismatch` | Archive corrupted / wrong version | Re-download the archive, verify via `shasum -a 256`, update `UGS_SRC_SHA256` only if the upstream checksum changes. |
| `xwtest_smoke` reports `Cannot open display` | DISPLAY unset or inaccessible | Export a valid DISPLAY, use `-DXWTEST_SMOKE_DISPLAY`, or run tests under `xvfb-run`. |
| Missing X11 headers/libs | X development packages not installed | Install X11 dev packages (e.g., `xorg-dev`, `libX11-dev`, or XQuartz on macOS). |

With the archive available and DISPLAY configured, `cmake --build build --target test` should pass and `cmake --install build --prefix ...` installs `libugs.a` plus optional `xwtest` binaries.
