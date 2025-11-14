cmake_minimum_required(VERSION 3.20)
project(ugs VERSION 0.0.0 LANGUAGES C Fortran)

include(GNUInstallDirs)
option(BUILD_TESTING "Enable building and running tests" ON)
include(CTest)

# ------------------------------------------------------------
# Options
# ------------------------------------------------------------
option(NET_FETCH              "Allow downloading upstream archives when local tarballs are missing (Mode B fallback)" ON)
option(UGS_BUILD_XWTEST       "Build the legacy xwtest sample program" OFF)
option(UGS_F77_COMPAT "Enable legacy F77 calling convention compatibility (e.g., allow argument mismatch for %VAL-style calls)" ON)
set(XWTEST_SMOKE_DISPLAY "0" CACHE STRING "Override DISPLAY when running the xwtest_smoke ctest (empty = inherit from environment)")

set(UGS_SRC_SHA256 "27bc46e975917bdf149e9ff6997885ffa24b0b1416bdf82ffaea5246b36e1f83"
    CACHE STRING "Pinned SHA256 for the upstream ugs.tar.gz archive")
set(UGS_SRC_ARCHIVE "" CACHE FILEPATH "Optional override path to a pre-downloaded ugs.tar.gz archive")

# Prepare compiler-specific flags for legacy calling conventions
set(_f77_compat_flags "")
if(UGS_F77_COMPAT AND CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
  list(APPEND _f77_compat_flags -fallow-argument-mismatch -std=legacy)
endif()

# ------------------------------------------------------------
# Layout (out-of-source only)
# ------------------------------------------------------------
set(UGS_URL            "http://ftp.riken.jp/iris/ugs/ugs.tar.gz")
set(UGS_ARCHIVE_NAME   "ugs.tar.gz")
set(UGS_TARBALL_DIR    "${CMAKE_CURRENT_SOURCE_DIR}/third_party/tarballs")
set(UGS_DOWNLOAD_DIR   "${CMAKE_BINARY_DIR}/downloads")
set(UGS_VENDOR_ROOT    "${CMAKE_BINARY_DIR}/vendor")
set(UGS_SRC_DIR        "${UGS_VENDOR_ROOT}/ugs")
set(UGS_GEN_DIR        "${CMAKE_BINARY_DIR}/generated")

file(MAKE_DIRECTORY "${UGS_TARBALL_DIR}" "${UGS_DOWNLOAD_DIR}" "${UGS_VENDOR_ROOT}" "${UGS_GEN_DIR}")

# ------------------------------------------------------------
# Source acquisition (Mode B)
# ------------------------------------------------------------
set(_third_party_archive "${UGS_TARBALL_DIR}/${UGS_ARCHIVE_NAME}")
set(_archive_candidates)
if(UGS_SRC_ARCHIVE)
  list(APPEND _archive_candidates "${UGS_SRC_ARCHIVE}")
endif()
list(APPEND _archive_candidates "${_third_party_archive}")

set(_resolved_archive "")
foreach(candidate IN LISTS _archive_candidates)
  if(candidate AND EXISTS "${candidate}")
    set(_resolved_archive "${candidate}")
    break()
  endif()
endforeach()

if(NOT _resolved_archive AND NET_FETCH)
  set(_resolved_archive "${_third_party_archive}")
  if(NOT EXISTS "${_resolved_archive}")
    if(NOT UGS_SRC_SHA256)
      message(FATAL_ERROR "UGS_SRC_SHA256 must be set before downloading (required for hash pinning).")
    endif()
    set(_download_temp "${UGS_TARBALL_DIR}/${UGS_ARCHIVE_NAME}.download")
    message(STATUS "Downloading ${UGS_URL} (NET_FETCH=ON → ${_resolved_archive})")
    file(DOWNLOAD "${UGS_URL}" "${_download_temp}"
         EXPECTED_HASH "SHA256=${UGS_SRC_SHA256}"
         STATUS _dl_status
         SHOW_PROGRESS)
    list(GET _dl_status 0 _dl_status_code)
    if(NOT _dl_status_code EQUAL 0)
      file(REMOVE "${_download_temp}")
      list(GET _dl_status 1 _dl_status_msg)
      message(FATAL_ERROR "Failed to download ${UGS_URL}: ${_dl_status_msg}")
    endif()
    if(EXISTS "${_resolved_archive}")
      file(REMOVE "${_resolved_archive}")
    endif()
    file(RENAME "${_download_temp}" "${_resolved_archive}")
  endif()
endif()

if(NOT _resolved_archive)
  message(FATAL_ERROR
    "UGS archive not available.\n"
    "Place ${UGS_ARCHIVE_NAME} under ${UGS_TARBALL_DIR}, set UGS_SRC_ARCHIVE, or configure with -DNET_FETCH=ON.")
endif()

if(NOT UGS_SRC_SHA256)
  message(FATAL_ERROR "UGS_SRC_SHA256 must be defined to verify the upstream archive.")
endif()

file(SHA256 "${_resolved_archive}" _resolved_sha)
if(NOT _resolved_sha STREQUAL UGS_SRC_SHA256)
  message(FATAL_ERROR "SHA256 mismatch for ${_resolved_archive}\n  expected: ${UGS_SRC_SHA256}\n  actual  : ${_resolved_sha}")
endif()

if(NOT EXISTS "${UGS_SRC_DIR}")
  file(ARCHIVE_EXTRACT INPUT "${_resolved_archive}" DESTINATION "${UGS_VENDOR_ROOT}")
  if(EXISTS "${UGS_VENDOR_ROOT}/ugs" AND NOT EXISTS "${UGS_SRC_DIR}")
    file(RENAME "${UGS_VENDOR_ROOT}/ugs" "${UGS_SRC_DIR}")
  elseif(EXISTS "${UGS_VENDOR_ROOT}/ugs_source" AND NOT EXISTS "${UGS_SRC_DIR}")
    file(RENAME "${UGS_VENDOR_ROOT}/ugs_source" "${UGS_SRC_DIR}")
  endif()
endif()

if(NOT EXISTS "${UGS_SRC_DIR}")
  message(FATAL_ERROR "The extracted UGS sources (${UGS_SRC_DIR}) are missing after archive extraction.")
endif()

set(UGS_SOURCE_TREE "${UGS_SRC_DIR}/src.2.10e")
if(NOT EXISTS "${UGS_SOURCE_TREE}")
  message(FATAL_ERROR "Expected directory ${UGS_SOURCE_TREE} was not found inside the extracted archive.")
endif()

# ------------------------------------------------------------
# Patch helpers
# ------------------------------------------------------------
function(_copy_and_patch input abs_out)
  file(READ "${input}" _content)
  string(REPLACE "UGSYSTEM:" "UGSYSTEM_" _content "${_content}")
  string(REGEX REPLACE "INTEGER\\*2[ ]+CHC" "CHARACTER*2     CHC" _content "${_content}")
  get_filename_component(_name "${input}" NAME)
  if(_name STREQUAL "aux.c")
    if(NOT _content MATCHES "#include <string.h>")
      set(_content "#include <string.h>\n${_content}")
    endif()
  elseif(_name STREQUAL "rotated.c")
    if(NOT _content MATCHES "#include <stdlib.h>")
      set(_content "#include <stdlib.h>\n${_content}")
    endif()
    if(NOT _content MATCHES "#include <string.h>")
      string(REPLACE "#include <stdlib.h>\n" "#include <stdlib.h>\n#include <string.h>\n" _content "${_content}")
    endif()
  endif()
  get_filename_component(_outdir "${abs_out}" DIRECTORY)
  file(MAKE_DIRECTORY "${_outdir}")
  file(WRITE "${abs_out}" "${_content}")
endfunction()

function(_copy_if_exists relpath)
  set(in "${UGS_SOURCE_TREE}/${relpath}")
  set(out "${UGS_GEN_DIR}/${relpath}")
  if(EXISTS "${in}")
    _copy_and_patch("${in}" "${out}")
  else()
    message(STATUS "(skip) missing in upstream: ${relpath}")
  endif()
endfunction()

function(_copy_ugsystem_files base_subdir)
  foreach(oldfile
    UGC00CBK.FOR UGD00CBK.FOR UGDDACBK.FOR UGE00CBK.FOR UGEMSCBK.FOR UGERRCBK.FOR
    UGF00CBK.FOR UGG00CBK.FOR UGMCACBK.FOR UGPOTCBK.FOR UGPOTCBK.org UGPOTDCL.FOR
  )
    set(src "${UGS_SOURCE_TREE}/${base_subdir}/UGSYSTEM:${oldfile}")
    if(EXISTS "${src}")
      set(dst "${UGS_GEN_DIR}/${base_subdir}/UGSYSTEM_${oldfile}")
      _copy_and_patch("${src}" "${dst}")
    endif()
  endforeach()

  foreach(oldfile
    UGDDACBK.FOR UGDDXEPS.FOR UGDDXGIN.FOR UGDDXGRN.FOR UGDDXGSD.FOR UGDDXGSQ.FOR
    UGDDXIM3.FOR UGDDXIMX.FOR UGDDXMET.FOR UGDDXPDI.FOR UGDDXPDL.FOR UGDDXPDS.FOR
    UGDDXPDU.FOR UGDDXPRX.FOR UGDDXPSC.FOR UGDDXQMS.FOR UGDDXSKB.FOR UGDDXSKC.FOR
    UGDDXSKD.FOR UGDDXSKE.FOR UGDDXSSS.FOR UGDDXTAL.FOR UGDDXTIN.FOR UGDDXTIZ.FOR
    UGDDXTKA.FOR UGDDXTKB.FOR UGDDXTKC.FOR UGDDXTKD.FOR UGDDXTKE.FOR UGDDXTKZ.FOR
    UGDDXTSD.FOR UGDDXTSQ.FOR UGDDXTXA.FOR UGDDXTXB.FOR UGDDXTXC.FOR UGDDXUIN.FOR
    UGDDXUSD.FOR UGDDXUSQ.FOR UGDDXVI2.FOR UGDDXVPF.FOR UGDDXVS2.FOR UGDDXXWI.FOR
    UGDDXXWS.FOR UGIOPARM.FOR
  )
    set(src "${UGS_SOURCE_TREE}/${base_subdir}/UGSYSTEM:${oldfile}")
    if(EXISTS "${src}")
      set(dst "${UGS_GEN_DIR}/${base_subdir}/UGSYSTEM_${oldfile}")
      _copy_and_patch("${src}" "${dst}")
    endif()
  endforeach()
endfunction()

function(_copy_asset_if_exists relpath)
  set(in "${UGS_SOURCE_TREE}/${relpath}")
  set(out "${UGS_GEN_DIR}/${relpath}")
  if(EXISTS "${in}")
    get_filename_component(_outdir "${out}" DIRECTORY)
    file(MAKE_DIRECTORY "${_outdir}")
    file(COPY "${in}" DESTINATION "${_outdir}")
  else()
    message(STATUS "(skip) missing asset in upstream: ${relpath}")
  endif()
endfunction()

# ------------------------------------------------------------
# Enumerate sources
# ------------------------------------------------------------
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
  drivers/tek4010.f drivers/xwindow.f drivers/xwindowc.c
  dummies/postscr.f dummies/tek4010.f dummies/ugcw01.f dummies/uggd01.f dummies/uggi01.f
  dummies/uggks_dummy.f dummies/uggr01.f dummies/uggs01.f dummies/ugin01.f dummies/ugix01.f
  dummies/ugmt01.f dummies/ugpi01.f dummies/ugpl01.f dummies/ugpm01.f dummies/ugps01.f
  dummies/ugpu01.f dummies/ugpx01.f dummies/ugqm01.f dummies/ugsa01.f dummies/ugsb01.f
  dummies/ugsc01.f dummies/ugsd01.f dummies/ugse01.f dummies/ugsixel_dummy.f dummies/ugsx01.f
  dummies/ugta01.f dummies/ugtd01.f dummies/ugts01.f dummies/ugtx01.f dummies/ugud01.f
  dummies/uguis_dummy.f dummies/ugus01.f dummies/ugux01.f dummies/ugvf01.f dummies/ugvi01.f
  dummies/ugvs01.f dummies/ugwa01.f dummies/ugwb01.f dummies/ugwc01.f dummies/ugwd01.f
  dummies/ugwe01.f dummies/ugwz01.f dummies/ugxa01.f dummies/ugxb01.f dummies/ugxc01.f
  dummies/ugxs01.f dummies/ugzz01.f dummies/x-window.f
)

foreach(src_name IN LISTS UGS_SOURCE_NAMES)
  _copy_if_exists(${src_name})
endforeach()

_copy_ugsystem_files("")
_copy_ugsystem_files("drivers")

_copy_asset_if_exists(drivers/cursor1.bmp)
_copy_asset_if_exists(drivers/cursor2.bmp)
_copy_asset_if_exists(drivers/icon.bmp)

set(_rot_in  "${UGS_SOURCE_TREE}/drivers/rotated.h")
set(_rot_out "${UGS_GEN_DIR}/drivers/rotated.h")
if(NOT EXISTS "${_rot_out}")
  if(EXISTS "${_rot_in}")
    _copy_if_exists(drivers/rotated.h)
  else()
    file(MAKE_DIRECTORY "${UGS_GEN_DIR}/drivers")
    file(WRITE "${_rot_out}" "/* Auto-generated fallback: rotated.h */\n#ifndef UGS_ROTATED_H\n#define UGS_ROTATED_H\n#endif\n")
  endif()
endif()

set(_def_in  "${UGS_SOURCE_TREE}/drivers/defaults.h")
set(_def_out "${UGS_GEN_DIR}/drivers/defaults.h")
if(NOT EXISTS "${_def_out}")
  if(EXISTS "${_def_in}")
    _copy_if_exists(drivers/defaults.h)
  else()
    file(MAKE_DIRECTORY "${UGS_GEN_DIR}/drivers")
    file(WRITE "${_def_out}" "/* Auto-generated fallback: defaults.h */\n#ifndef UGS_DEFAULTS_H\n#define UGS_DEFAULTS_H\n#endif\n")
  endif()
endif()

# ------------------------------------------------------------
# Targets
# ------------------------------------------------------------
find_package(X11 REQUIRED)

set(UGS_SOURCE_PATHS)
foreach(src_name IN LISTS UGS_SOURCE_NAMES)
  list(APPEND UGS_SOURCE_PATHS "${UGS_GEN_DIR}/${src_name}")
endforeach()

add_library(${PROJECT_NAME} STATIC ${UGS_SOURCE_PATHS})

if(APPLE)
  target_compile_options(${PROJECT_NAME} PRIVATE
    $<$<COMPILE_LANGUAGE:Fortran>:-O2 -fno-automatic -finit-local-zero -fno-backslash -funroll-loops -fomit-frame-pointer -ftree-vectorize -flat_namespace>
    $<$<COMPILE_LANGUAGE:C>:-O2 -DIUCLC=0001000 -ftree-vectorize>
  )
else()
  target_compile_options(${PROJECT_NAME} PRIVATE
    $<$<COMPILE_LANGUAGE:Fortran>:-O2>
    $<$<COMPILE_LANGUAGE:C>:-O2>
  )
endif()

if(_f77_compat_flags)
  target_compile_options(${PROJECT_NAME} PRIVATE $<$<COMPILE_LANGUAGE:Fortran>:${_f77_compat_flags}>)
endif()

target_include_directories(${PROJECT_NAME} PRIVATE ${UGS_GEN_DIR}/drivers ${X11_INCLUDE_DIR})
target_link_libraries(${PROJECT_NAME}
  PRIVATE ${X11_LIBRARIES} ${X11_Xaw_LIB} ${X11_Xmu_LIB} ${X11_Xt_LIB}
)

if(UGS_BUILD_XWTEST)
  set(_in_xwin "${UGS_SOURCE_TREE}/drivers/xwindowc.c")
  set(_out_dir "${CMAKE_BINARY_DIR}/xwtest_src")
  set(_out_xwin "${_out_dir}/xwindowc.c")
  file(MAKE_DIRECTORY "${_out_dir}")
  if(EXISTS "${_in_xwin}")
    file(READ "${_in_xwin}" _xw)
    string(REPLACE "main" "void main" _xw "${_xw}")
    file(WRITE "${_out_xwin}" "${_xw}")
  else()
    message(FATAL_ERROR "Missing driver source: ${_in_xwin}")
  endif()

  add_executable(xwtest
    "${_out_xwin}"
    ${UGS_GEN_DIR}/drivers/cursor1.bmp
    ${UGS_GEN_DIR}/drivers/cursor2.bmp
    ${UGS_GEN_DIR}/drivers/icon.bmp
    ${UGS_GEN_DIR}/drivers/rotated.c
  )
  target_compile_options(xwtest PRIVATE -DSELFTEST)
  target_include_directories(xwtest PRIVATE ${UGS_GEN_DIR}/drivers ${X11_INCLUDE_DIR})
  target_link_libraries(xwtest PRIVATE ${X11_LIBRARIES} ${X11_Xaw_LIB} ${X11_Xmu_LIB} ${X11_Xt_LIB})
  install(TARGETS xwtest RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()

set(XWTEST_SMOKE_SUPPORT FALSE)
if(BUILD_TESTING)
  set(_wrap_src "${CMAKE_CURRENT_SOURCE_DIR}/tests/cases/01_smoke/xwindowc_smoke.c")
  if(NOT EXISTS "${_wrap_src}")
    message(FATAL_ERROR "Missing xwtest smoke source: ${_wrap_src}")
  endif()
  add_executable(xwtest_smoke
    "${_wrap_src}"
    ${UGS_GEN_DIR}/drivers/cursor1.bmp
    ${UGS_GEN_DIR}/drivers/cursor2.bmp
    ${UGS_GEN_DIR}/drivers/icon.bmp
    ${UGS_GEN_DIR}/drivers/rotated.c
  )
  target_compile_definitions(xwtest_smoke PRIVATE SELFTEST)
  target_include_directories(xwtest_smoke PRIVATE ${UGS_GEN_DIR}/drivers ${X11_INCLUDE_DIR})
  target_link_libraries(xwtest_smoke PRIVATE ${X11_LIBRARIES} ${X11_Xaw_LIB} ${X11_Xmu_LIB} ${X11_Xt_LIB})
  set(XWTEST_SMOKE_SUPPORT TRUE)
  add_subdirectory(tests)
endif()

install(TARGETS ${PROJECT_NAME}
  EXPORT ugs-targets
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/ugs
)

install(EXPORT ugs-targets
  NAMESPACE ugs::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/ugs
)

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/ugsConfig.cmake" "include(\"\${CMAKE_CURRENT_LIST_DIR}/ugs-targets.cmake\")\n")
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/ugsConfig.cmake"
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/ugs)

add_custom_target(help_targets
  COMMAND ${CMAKE_COMMAND} -E echo "Available helper targets:"
  COMMAND ${CMAKE_COMMAND} -E echo "  help_targets  - Show this message."
  COMMAND ${CMAKE_COMMAND} -E echo "  clean         - Generator clean."
  COMMAND ${CMAKE_COMMAND} -E echo "  distclean     - Remove build/generated and build/vendor."
  COMMAND ${CMAKE_COMMAND} -E echo "  purge         - distclean + remove download cache (${UGS_DOWNLOAD_DIR})."
  COMMAND ${CMAKE_COMMAND} -E echo ""
  COMMAND ${CMAKE_COMMAND} -E echo "Mode B: place/download ${UGS_ARCHIVE_NAME} under ${UGS_TARBALL_DIR}."
  COMMAND ${CMAKE_COMMAND} -E echo "        NET_FETCH=${NET_FETCH} downloads to ${UGS_TARBALL_DIR} (SHA256=${UGS_SRC_SHA256})."
  USES_TERMINAL
)

add_custom_target(distclean
  COMMAND ${CMAKE_COMMAND} -E rm -rf "${UGS_GEN_DIR}" "${UGS_VENDOR_ROOT}"
  COMMENT "Remove generated sources and vendor tree."
)

add_custom_target(purge
  COMMAND ${CMAKE_COMMAND} -E rm -rf "${UGS_GEN_DIR}" "${UGS_VENDOR_ROOT}" "${UGS_DOWNLOAD_DIR}"
  COMMENT "Remove generated sources, vendor tree, and download cache (archives stay in third_party/tarballs)."
)

if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in)
  configure_file(cmake_uninstall.cmake.in cmake_uninstall.cmake IMMEDIATE @ONLY)
  add_custom_target(uninstall COMMAND "${CMAKE_COMMAND}" -P cmake_uninstall.cmake)
endif()
