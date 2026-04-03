# UGS (Unified Graphics System) Modernized Build

This repository wraps the legacy UGS Fortran/C sources in a modern CMake workflow with reproducible source acquisition (local archives first, but able to fall back to remote downloads), out-of-source builds, and a minimal smoke test for the X11 sample.

## Directory Layout

```
.
├─ CMakeLists.txt              # root build definition
├─ archives/                   # place ugs.tar.gz here (preferred local archive)
├─ .cache/downloads/           # download cache when NET_FETCH=ON
├─ build/                      # out-of-source build tree (generated)
├─ build/vendor/               # extracted upstream sources, never committed
├─ build/generated/            # patched/generated sources and assets
├─ tests/
│  ├─ CMakeLists.txt           # registers ctest entries
│  └─ cases/
│     ├─ 01_smoke/
│     │  ├─ xwindowc_smoke.c   # GUI smoke harness, compiled when enabled
│     │  └─ expected.txt       # regex checked against xwtest_smoke output
│     └─ 02_tryxw/
│        └─ tryxw.f            # Fortran smoke input used by the 02_tryxw test
└─ README.md
```

All build artifacts stay under `build/` to keep the source tree clean.

## Archive Acquisition (local + remote fallback)

1. Obtain the upstream archive `ugs.tar.gz` and place it under `archives/`.
2. When using remote downloads (`NET_FETCH=ON`), hash pinning is required: `UGS_SRC_SHA256` must be set (it defaults to the known SHA) and is used to verify downloaded archives.
3. To allow remote downloads (used only when no local archive is found), configure with `-DNET_FETCH=ON`. The downloaded file is verified against `UGS_SRC_SHA256` and stored under `.cache/downloads/` as a cache.
4. If neither a local archive nor NET_FETCH is available, configuration fails with guidance.

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
- `XWTEST_SMOKE_DISPLAY`: override the DISPLAY used by the smoke test. When unset, the tests inherit the runtime environment as-is.

> **Note:** X11 headers and libraries must be available on the host. CMake will fail early if it cannot find them—this is expected because UGS relies on X11.

## Tests

Tests are managed with CTest. `01_smoke` builds and runs `xwtest_smoke`, which opens an X11 window and waits until it becomes viewable. Its output must match `tests/cases/01_smoke/expected.txt`. `02_tryxw` builds the Fortran smoke input from `tests/cases/02_tryxw/tryxw.f` and exercises the UGS API through the XWINDOW driver. `package_smoke` installs the project into a temporary prefix and verifies that a downstream CMake project can consume it via `find_package(ugs)`.

The default pull-request CI keeps `UGS_ENABLE_GUI_SMOKE=OFF`, so the standard matrix runs `02_tryxw` and `package_smoke` but does not require `01_smoke`. The GUI case remains available locally and through `.github/workflows/gui-smoke.yml`, which is intended as a non-blocking diagnostic workflow rather than a required PR gate.

Run tests:
```bash
cmake --build build --target test
# or
ctest --test-dir build -L smoke --output-on-failure
ctest --test-dir build -R '^01_smoke$' --output-on-failure
ctest --test-dir build -R '^02_tryxw$' --output-on-failure
ctest --test-dir build -L package --output-on-failure

# Skip GUI smoke registration when you only need the default CI-equivalent set
cmake -S . -B build -DBUILD_TESTING=ON -DUGS_ENABLE_GUI_SMOKE=OFF
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
