# Source Regeneration and Incremental Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make maintained UGS source preparation recover missing outputs, react to preparation-rule changes, preserve unchanged output timestamps, and recover after documented cleanup in existing Makefiles and Ninja build trees.

**Architecture:** Define the maintained upstream file inventory once in a CMake manifest shared by configuration and script mode. Treat every prepared source, renamed include, generated header, and copied asset as a declared output of one preparation command whose inputs include the unpack stamp, preparation script, and manifest. Use content-aware writes so rerunning preparation changes only files whose content changed, and exercise the incremental contract from isolated nested build trees.

**Tech Stack:** CMake 3.15+, CTest script mode, Unix Makefiles, Ninja, C and Fortran toolchains, pinned `ugs.tar.gz`

---

## File map

- Create `cmake/UgsSourceManifest.cmake`: canonical lists of compiled upstream sources, renamed `UGSYSTEM:` files, copied assets, generated headers, and test-only prepared sources.
- Modify `CMakeLists.txt`: include the manifest, derive absolute prepared outputs, and declare the preparation script and manifest as dependencies.
- Modify `cmake/FetchAndUnpack.cmake`: reset only the project-specific extracted tree before re-extraction and avoid competing default unpack paths.
- Modify `cmake/PrepareUgsSources.cmake`: consume the manifest, validate mandatory patch anchors, and update files only when content changes.
- Create `tests/source_preparation/RunSourcePreparationTest.cmake`: isolated configure/build/rebuild/cleanup test driver.
- Modify `tests/CMakeLists.txt`: register the focused incremental tests for the active generator.
- Modify `.github/workflows/ci.yml`: exercise the focused contract with Unix Makefiles and Ninja without duplicating the complete platform matrix.
- Modify `README.md`: replace the current unverified-cleanup limitation with the tested contract and state the generator coverage.

## Task 1: Add a failing isolated incremental test

**Files:**
- Create: `tests/source_preparation/RunSourcePreparationTest.cmake`
- Modify: `tests/CMakeLists.txt`

- [ ] **Step 1: Add one CTest entry that forwards the active generator and archive**

Add this registration to `tests/CMakeLists.txt`:

```cmake
add_test(
  NAME source_preparation.incremental
  COMMAND "${CMAKE_COMMAND}"
    "-DPROJECT_SOURCE_DIR=${PROJECT_SOURCE_DIR}"
    "-DTEST_ROOT=${CMAKE_CURRENT_BINARY_DIR}/source-preparation/incremental"
    "-DTEST_GENERATOR=${CMAKE_GENERATOR}"
    "-DTEST_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
    "-DTEST_ARCHIVE=${UGS_SRC_TGZ}"
    -P "${CMAKE_CURRENT_SOURCE_DIR}/source_preparation/RunSourcePreparationTest.cmake")
set_tests_properties(source_preparation.incremental PROPERTIES
  LABELS "build;incremental"
  TIMEOUT 180)
```

- [ ] **Step 2: Write the test driver with reusable command and timestamp assertions**

The driver must:

1. Copy the tracked project into `${TEST_ROOT}/source`, excluding `.git`, ignored build trees, `.cache`, and `archives`.
2. Configure `${TEST_ROOT}/build` with `${TEST_GENERATOR}`, `NET_FETCH=OFF`, `ARCHIVE_DIR=${TEST_ROOT}/archives`, `BUILD_TESTING=OFF`, and `UGS_ENABLE_GUI_SMOKE=OFF`.
3. Copy `${TEST_ARCHIVE}` to `${TEST_ROOT}/archives/ugs.tar.gz` before configuration.
4. Build `ugs` once and require these paths to exist:
   - `generated/aux.c`
   - `generated/uge002.F`
   - `generated/drivers/postscr.f`
   - `generated/drivers/rotated.h`
   - `generated/drivers/cursor1.bmp`
   - `libugs.a` (allow the platform-specific library directory returned by `cmake --build`; locate it recursively rather than assuming one layout)
5. Record SHA-256 and `%s` timestamps for `generated/aux.c`, `generated/drivers/postscr.f`, and the library.
6. Sleep for one second, rebuild without changes, and require hashes and timestamps to remain identical.
7. Delete `generated/aux.c`, rebuild, require it to be restored, and require its hash to match the initial hash.
8. Change the copied `PrepareUgsSources.cmake` patch for `postscr.f` from `SAVE          EXNM` to `SAVE          EXNM ! incremental-test`, rebuild, require only `postscr.f` to change among the two sampled generated sources, and require the library timestamp to advance.
9. Run `clean`, rebuild, and require all sampled outputs to exist.
10. Run `clean_downloads`, require copied `${TEST_ROOT}/archives/ugs.tar.gz` to remain, rebuild with `NET_FETCH=OFF`, and require all sampled outputs to exist.

Use `execute_process(COMMAND ... RESULT_VARIABLE ... OUTPUT_VARIABLE ... ERROR_VARIABLE ...)` for every subprocess and issue `message(FATAL_ERROR ...)` containing the command output on failure. Implement timestamp reads with `file(TIMESTAMP path value "%s")` and content checks with `file(SHA256 ...)`.

- [ ] **Step 3: Run the test against the current implementation and confirm the expected failure**

Run:

```bash
cmake -S . -B build-issue20-red \
  -DNET_FETCH=OFF \
  -DBUILD_TESTING=ON \
  -DUGS_ENABLE_GUI_SMOKE=OFF
cmake --build build-issue20-red --parallel
ctest --test-dir build-issue20-red \
  -R '^source_preparation\.incremental$' \
  --output-on-failure
```

Expected: the test fails when `generated/aux.c` is deleted or when the copied preparation script changes, demonstrating the missing dependency contract.

## Task 2: Establish one canonical source manifest

**Files:**
- Create: `cmake/UgsSourceManifest.cmake`
- Modify: `CMakeLists.txt`
- Modify: `cmake/PrepareUgsSources.cmake`

- [ ] **Step 1: Move the existing 161-entry `UGS_SOURCE_NAMES` list unchanged into the manifest**

Start the manifest with:

```cmake
set(UGS_SOURCE_NAMES
  aux.c ran.f ug2dhg.f ug2dhp.f ug3lin.f ug3mrk.f ug3pln.f ug3pmk.f
  ug3trn.f ug3txt.f ug3wrd.f ugb001.f ugb002.f ugb003.f ugb004.f ugb005.f
  ugb006.f ugb007.f ugb008.f ugb009.f ugb010.f ugb011.f ugb012.f ugb013.f
  ugb014.f ugb015.f ugc001.f ugc002.f ugc003.f ugc004.f ugc005.f ugc006.f
  ugc007.f ugclos.f ugcnt1.f ugcnt2.f ugcnt3.f ugcnt4.f ugcntr.f ugcnvf.f
  ugctol.f ugd001.f ugd002.f ugd003.f ugddat.f ugdefl.f ugdsab.f ugdspc.f
  ugdupl.f uge001.f uge003.f ugectl.f ugenab.f ugevnt.f ugf001.f ugf002.f
  ugf003.f ugf004.f ugfont.f ugg001.f ugg002.f ugg003.f ugg004.f ugg005.f
  uginfo.f uginit.f uglgax.f uglgdx.f ugline.f uglnax.f uglndx.f ugmark.f
  ugmctl.f  ugmesh.f ugnucl.f ugoption.f ugpfil.f ugpict.f ugplin.f ugpmrk.f
  ugproj.f ugqctr.f ugrerr.f ugscin.f ugshld.f ugsimp.f ugslct.f ugtext.f
  ugtran.f ugwdow.f ugwrit.f ugxerr.f ugxhch.f ugxsym.f ugxtxt.f ugz001.f
  ugz002.f ugz003.f ugz006.f uge002.F ugfrev.F uggetv.F ugopen.F ugz005.F
  bit/btest.c bit/iand.c bit/ibclr.c bit/ibset.c bit/ior.c bit/ishft.c bit/ishftc.c
  drivers/epsf.f drivers/postscr.f drivers/rotated.c
  drivers/xwindow.f drivers/xwindowc.c
  dummies/ugcw01.f dummies/uggd01.f dummies/uggi01.f
  dummies/uggks_dummy.f dummies/uggr01.f dummies/uggs01.f dummies/ugin01.f dummies/ugix01.f
  dummies/ugmt01.f dummies/ugpi01.f dummies/ugpl01.f dummies/ugpm01.f dummies/ugps01.f
  dummies/ugpu01.f dummies/ugpx01.f dummies/ugqm01.f dummies/ugsa01.f dummies/ugsb01.f
  dummies/ugsc01.f dummies/ugsd01.f dummies/ugse01.f dummies/ugsixel_dummy.f dummies/ugsx01.f
  dummies/ugta01.f dummies/ugtd01.f dummies/ugts01.f dummies/ugtx01.f dummies/ugud01.f
  dummies/uguis_dummy.f dummies/ugus01.f dummies/ugux01.f dummies/ugvf01.f dummies/ugvi01.f
  dummies/ugvs01.f dummies/ugwa01.f dummies/ugwb01.f dummies/ugwc01.f dummies/ugwd01.f
  dummies/ugwe01.f dummies/ugwz01.f dummies/ugxa01.f dummies/ugxb01.f dummies/ugxc01.f
  dummies/ugxs01.f dummies/ugzz01.f
)
```

During execution, the list body must be copied verbatim from the current `CMakeLists.txt`; verify equality before removing either old copy with a temporary CMake script that compares both lists and fails on any difference.

- [ ] **Step 2: Add named lists for the non-compiled prepared files**

Append:

```cmake
set(UGS_SYSTEM_BASE_DIRS "" drivers)

set(UGS_SYSTEM_COMMON_FILES
  UGC00CBK.FOR UGD00CBK.FOR UGDDACBK.FOR UGE00CBK.FOR UGEMSCBK.FOR
  UGERRCBK.FOR UGF00CBK.FOR UGG00CBK.FOR UGMCACBK.FOR UGPOTCBK.FOR
  UGPOTCBK.org UGPOTDCL.FOR)

set(UGS_SYSTEM_DRIVER_FILES
  UGDDACBK.FOR UGDDXEPS.FOR UGDDXGIN.FOR UGDDXGRN.FOR UGDDXGSD.FOR
  UGDDXGSQ.FOR UGDDXIM3.FOR UGDDXIMX.FOR UGDDXMET.FOR UGDDXPDI.FOR
  UGDDXPDL.FOR UGDDXPDS.FOR UGDDXPDU.FOR UGDDXPRX.FOR UGDDXPSC.FOR
  UGDDXQMS.FOR UGDDXSKB.FOR UGDDXSKC.FOR UGDDXSKD.FOR UGDDXSKE.FOR
  UGDDXSSS.FOR UGDDXTAL.FOR UGDDXTIN.FOR UGDDXTIZ.FOR UGDDXTKA.FOR
  UGDDXTKB.FOR UGDDXTKC.FOR UGDDXTKD.FOR UGDDXTKE.FOR UGDDXTKZ.FOR
  UGDDXTSD.FOR UGDDXTSQ.FOR UGDDXTXA.FOR UGDDXTXB.FOR UGDDXTXC.FOR
  UGDDXUIN.FOR UGDDXUSD.FOR UGDDXUSQ.FOR UGDDXVI2.FOR UGDDXVPF.FOR
  UGDDXVS2.FOR UGDDXXWI.FOR UGDDXXWS.FOR UGIOPARM.FOR)

set(UGS_COPIED_ASSETS
  drivers/cursor1.bmp
  drivers/cursor2.bmp
  drivers/icon.bmp)

set(UGS_GENERATED_HEADERS
  drivers/rotated.h
  drivers/defaults.h)

set(UGS_TEST_ONLY_PREPARED_SOURCES
  drivers/xwindowc_selftest.c)
```

- [ ] **Step 3: Include the manifest from configuration and script mode**

In `CMakeLists.txt`, add:

```cmake
set(UGS_SOURCE_MANIFEST
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake/UgsSourceManifest.cmake")
include("${UGS_SOURCE_MANIFEST}")
```

Pass `UGS_SOURCE_MANIFEST` to script mode and replace the list in `PrepareUgsSources.cmake` with:

```cmake
if(NOT DEFINED UGS_SOURCE_MANIFEST OR
   NOT EXISTS "${UGS_SOURCE_MANIFEST}")
  message(FATAL_ERROR
    "UGS_SOURCE_MANIFEST is missing: ${UGS_SOURCE_MANIFEST}")
endif()
include("${UGS_SOURCE_MANIFEST}")
```

- [ ] **Step 4: Verify the manifest preserves the configured library inputs**

Run configure and compare the source count reported by a temporary `message(STATUS ...)` before and after the move. Expected: 161 compiled source paths in both cases. Remove the temporary message before continuing.

## Task 3: Make preparation deterministic and validate patch anchors

**Files:**
- Modify: `cmake/PrepareUgsSources.cmake`

- [ ] **Step 1: Replace unconditional writes with content-aware writes**

Add:

```cmake
function(_write_if_different path content)
  if(EXISTS "${path}")
    file(READ "${path}" current_content)
    if(current_content STREQUAL content)
      return()
    endif()
  endif()
  get_filename_component(output_dir "${path}" DIRECTORY)
  file(MAKE_DIRECTORY "${output_dir}")
  set(temporary_path "${path}.tmp")
  file(WRITE "${temporary_path}" "${content}")
  file(RENAME "${temporary_path}" "${path}")
endfunction()
```

Use `_write_if_different()` from `_copy_and_patch()`, `_generate_xwtest_source()`, and fallback-header generation. Replace `file(COPY ...)` for assets with `cmake -E copy_if_different` via `execute_process`, failing if the command returns nonzero.

- [ ] **Step 2: Add an exact replacement helper**

Add:

```cmake
function(_replace_required content_var input_path description old_text new_text)
  set(content "${${content_var}}")
  string(FIND "${content}" "${old_text}" match_index)
  if(match_index EQUAL -1)
    message(FATAL_ERROR
      "Required UGS patch anchor not found (${description}): ${input_path}")
  endif()
  string(REPLACE "${old_text}" "${new_text}" content "${content}")
  set(${content_var} "${content}" PARENT_SCOPE)
endfunction()
```

- [ ] **Step 3: Apply strict checks only to mandatory, uniquely located patches**

Use `_replace_required()` for:

- the endian conditional in `uge002.F`;
- `CHARACTER*256 EXNM` in `drivers/postscr.f`, replacing it with the declaration plus `SAVE          EXNM`;
- `main ()` in the test-only `drivers/xwindowc_selftest.c` generation.

Keep these transformations idempotent:

- add `<string.h>` to `aux.c` only when absent;
- add `<stdlib.h>` and `<string.h>` to `drivers/rotated.c` only when absent;
- replace any present `UGSYSTEM:` references;
- replace any present `INTEGER*2 ... CHC` declarations.

Before writing each strict output, accept the already-patched text as valid so rerunning preparation over an existing generated file cannot produce a false failure. The upstream input remains the primary source, so the normal path still validates the unpatched anchor.

- [ ] **Step 4: Add focused failure cases to the test driver**

In a copied source tree, alter each strict anchor once and run `PrepareUgsSources.cmake` directly. Require a nonzero result and require stderr to contain `Required UGS patch anchor not found` plus the affected relative path.

- [ ] **Step 5: Run the focused failure cases**

Run:

```bash
ctest --test-dir build-issue20-red \
  -R '^source_preparation\.' \
  --output-on-failure
```

Expected: strict-anchor cases pass because the deliberately incompatible inputs are rejected.

## Task 4: Declare complete preparation dependencies and outputs

**Files:**
- Modify: `CMakeLists.txt`

- [ ] **Step 1: Derive all prepared output paths from the manifest**

Build `UGS_PREPARED_OUTPUTS` from:

- every `UGS_SOURCE_NAMES` entry;
- renamed `UGSYSTEM_...` files for the root and `drivers` directories;
- `UGS_COPIED_ASSETS`;
- `UGS_GENERATED_HEADERS`;
- `UGS_TEST_ONLY_PREPARED_SOURCES`.

Remove duplicates and prefix every relative path with `${GEN_DIR}`. Keep `UGS_SOURCE_PATHS` as the compiled subset derived only from `UGS_SOURCE_NAMES`.

- [ ] **Step 2: Replace the stamp-only rule with one content-aware preparation target**

Use this structure:

```cmake
add_custom_target(prepare_sources
  COMMAND "${CMAKE_COMMAND}"
    "-DUGS_SOURCE_TREE=${UGS_SOURCE_TREE}"
    "-DUGS_GEN_DIR=${GEN_DIR}"
    "-DUGS_SOURCE_MANIFEST=${UGS_SOURCE_MANIFEST}"
    -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/PrepareUgsSources.cmake"
  BYPRODUCTS ${UGS_PREPARED_OUTPUTS}
  DEPENDS
    "${UGS_SRC_ROOT}.stamp"
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/PrepareUgsSources.cmake"
    "${UGS_SOURCE_MANIFEST}"
  COMMENT "Preparing patched/generated UGS sources"
  VERBATIM)
```

Remove `prepare_sources.stamp`. The target runs one content comparison pass on
each build, restores missing outputs, and leaves unchanged output timestamps
intact. Keep the existing target-level dependencies from `ugs`, `xwtest`, and
`xwtest_smoke` to `prepare_sources`.

- [ ] **Step 3: Make archive re-extraction safe after generated stamps are cleaned**

Extend `add_unpack_archive()` with an optional `RESET_PATH` argument, remove
that project-specific extracted root immediately before extraction, and pass
`${UGS_SRC_ROOT}` from the UGS call. Keep the user archive and download cache
outside the reset path. Make `unpack` an explicit target instead of an `ALL`
target so parallel default builds have one dependency path to the unpack stamp.

- [ ] **Step 4: Run the original failing incremental test**

Run:

```bash
cmake --build build-issue20-red --parallel
ctest --test-dir build-issue20-red \
  -R '^source_preparation\.incremental$' \
  --output-on-failure
```

Expected: PASS. The deleted output is restored, the altered preparation rule changes only its affected generated file among the samples, cleanup recovers, and a no-op build preserves timestamps.

## Task 5: Verify Makefiles and Ninja explicitly

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `tests/source_preparation/RunSourcePreparationTest.cmake` only if a verified generator-specific path needs normalization

- [ ] **Step 1: Run the focused contract with Unix Makefiles**

```bash
cmake -S . -B build-issue20-make \
  -G "Unix Makefiles" \
  -DNET_FETCH=OFF \
  -DBUILD_TESTING=ON \
  -DUGS_ENABLE_GUI_SMOKE=OFF
cmake --build build-issue20-make --parallel
ctest --test-dir build-issue20-make \
  -R '^source_preparation\.' \
  --output-on-failure
```

Expected: all `source_preparation.*` tests pass.

- [ ] **Step 2: Run the same contract with Ninja**

```bash
cmake -S . -B build-issue20-ninja \
  -G Ninja \
  -DNET_FETCH=OFF \
  -DBUILD_TESTING=ON \
  -DUGS_ENABLE_GUI_SMOKE=OFF
cmake --build build-issue20-ninja --parallel
ctest --test-dir build-issue20-ninja \
  -R '^source_preparation\.' \
  --output-on-failure
```

Expected: all `source_preparation.*` tests pass, followed by `ninja: no work to do.` on another unchanged build.

- [ ] **Step 3: Add a small Linux generator matrix for the focused contract**

Add a CI job with `generator: ["Unix Makefiles", "Ninja"]`. Install `gfortran`, X11 development libraries, and `ninja-build`; configure with the matrix generator; build `ugs`; and run only `ctest -R '^source_preparation\.' --output-on-failure`. Keep the existing Linux/macOS full build-and-test matrix unchanged.

## Task 6: Update the documented contract

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update “Directory Layout and Cleanup”**

Replace the statements that source-preparation changes and cleanup recovery lack dedicated tests. Document that:

- changes to `cmake/PrepareUgsSources.cmake` or `cmake/UgsSourceManifest.cmake` rerun preparation;
- missing prepared outputs are recreated in the same build tree;
- unchanged prepared files retain their timestamps and avoid unrelated recompilation;
- `clean_downloads` removes the current build's `vendor` and `generated` trees and the configured shared download cache;
- user-provided `archives/` contents remain untouched;
- the next build can recover offline when the user-provided archive is still available;
- the incremental contract is tested with Unix Makefiles and Ninja;
- Visual Studio and Xcode generator-specific incremental behavior is not currently verified.

- [ ] **Step 2: Confirm terminology matches F2C**

Use the shared directory roles `archives/`, `.cache/downloads/`, `vendor/`, and `generated/`. Retain the existing `clean_downloads` target name and semantics. Do not imply that UGS and F2C have identical generated contents.

## Task 7: Full verification and review checkpoint

**Files:**
- No additional planned files

- [ ] **Step 1: Run formatting/static configuration checks through both generators**

Reconfigure both `build-issue20-make` and `build-issue20-ninja` from empty directories and confirm there are no new CMake developer warnings.

- [ ] **Step 2: Run all display-independent tests**

```bash
ctest --test-dir build-issue20-make \
  --output-on-failure \
  -LE 'x11|visual'
```

Expected: all selected tests pass. This does not claim X11 runtime coverage.

- [ ] **Step 3: Run the installed-package check**

```bash
cmake --install build-issue20-make \
  --prefix build-issue20-make/stage
ctest --test-dir build-issue20-make \
  -R '^package_smoke$' \
  --output-on-failure
```

Expected: installation and `package_smoke` pass.

- [ ] **Step 4: Inspect repository state and cleanup test build trees**

Verify that `archives/ugs.tar.gz` remains unchanged, no generated or extracted
sources are tracked, and every tracked change is listed in this plan's file
map or is this plan document. Remove `build-issue20-red`,
`build-issue20-make`, and `build-issue20-ninja` after recording results.

- [ ] **Step 5: Commit after verification**

Record the changed files, the reproduced pre-fix failure, Makefiles and Ninja
results, full display-independent test result, package result, and any compiler
warnings. Create the authorized local commit, but do not push or create a pull
request without a later user request.

## Self-review

- The plan covers preparation-script dependency changes, missing outputs, no-op rebuilds, `clean`, `clean_downloads`, archive preservation, safe re-extraction, generator coverage, strict patch validation, the duplicated list, and documentation.
- Public targets and options remain unchanged; `clean_downloads` is not renamed or split.
- Testing uses copied source/archive inputs and isolated build trees, so it cannot remove the repository's `archives/`, `.cache/`, `build/`, or unrelated user files.
- X11 runtime behavior and graphics output are outside this issue; display-independent compilation and package checks remain included.
