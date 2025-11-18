cmake_minimum_required(VERSION 3.15)
project(ugs VERSION 0.1 LANGUAGES C Fortran)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(FetchAndUnpack)
fetch_and_unpack_configure_dirs()

# ------------------------------------------------------------
# Options
# ------------------------------------------------------------
option(NET_FETCH              "Allow downloading upstream archives when local tarballs are missing (Mode B fallback)" ON)
option(BUILD_TESTING "Enable building and running tests" ON)

option(UGS_BUILD_XWTEST       "Build the legacy xwtest sample program" OFF)
option(UGS_F77_COMPAT "Enable legacy F77 calling convention compatibility (e.g., allow argument mismatch for %VAL-style calls)" ON)

set(PACKAGE_CONFIG_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")
set(XWTEST_SMOKE_DISPLAY "0" CACHE STRING "Override DISPLAY when running the xwtest_smoke ctest (empty = inherit from environment)")
string(TOUPPER "${PROJECT_NAME}" PROJECT_NAME_UPPER)

# ------------------------------------------------------------
# Layout / Source acquisition (using helper)
# ------------------------------------------------------------
set(UGS_URL          "http://ftp.riken.jp/iris/ugs/ugs.tar.gz")
set(UGS_ARCHIVE_NAME "ugs.tar.gz")
set(UGS_SRC_SHA256 "27bc46e975917bdf149e9ff6997885ffa24b0b1416bdf82ffaea5246b36e1f83"
    CACHE STRING "Pinned SHA256 for the upstream ugs.tar.gz archive")
set(UGS_SRC_ARCHIVE "" CACHE FILEPATH "Optional override path to a pre-downloaded ugs.tar.gz archive")
set(UGS_VENDOR_ROOT "${CMAKE_BINARY_DIR}/vendor")
set(UGS_SRC_DIR     "${UGS_VENDOR_ROOT}/ugs")
set(UGS_GEN_DIR     "${CMAKE_BINARY_DIR}/generated")

resolve_input_file(UGS_ARCHIVE_PATH "${UGS_URL}" "${UGS_SRC_SHA256}" "${UGS_SRC_ARCHIVE}")
add_unpack_archive("${UGS_SRC_DIR}.stamp" "${UGS_VENDOR_ROOT}" "${UGS_ARCHIVE_PATH}"
  COMMENT "Unpacking UGS sources"
  COMMAND ${CMAKE_COMMAND} -E tar xzf)
add_unpack_target(unpack)

set(UGS_SOURCE_TREE "${UGS_SRC_DIR}/src.2.10e")

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
  # sources will be generated into UGS_GEN_DIR at build time
endforeach()

# ------------------------------------------------------------
# Targets
# ------------------------------------------------------------
find_package(X11 REQUIRED)

set(UGS_SOURCE_PATHS)
foreach(src_name IN LISTS UGS_SOURCE_NAMES)
  list(APPEND UGS_SOURCE_PATHS "${UGS_GEN_DIR}/${src_name}")
endforeach()

set(UGS_GENERATED_EXTRA
  ${UGS_GEN_DIR}/drivers/cursor1.bmp
  ${UGS_GEN_DIR}/drivers/cursor2.bmp
  ${UGS_GEN_DIR}/drivers/icon.bmp
  ${UGS_GEN_DIR}/drivers/rotated.c
)

set_source_files_properties(${UGS_SOURCE_PATHS} ${UGS_GENERATED_EXTRA}
  PROPERTIES GENERATED TRUE
)

add_custom_command(
  OUTPUT "${UGS_GEN_DIR}/prepare_sources.stamp"
  COMMAND ${CMAKE_COMMAND}
    -DUGS_SOURCE_TREE="${UGS_SOURCE_TREE}"
    -DUGS_GEN_DIR="${UGS_GEN_DIR}"
    -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/PrepareUgsSources.cmake"
  COMMAND ${CMAKE_COMMAND} -E touch "${UGS_GEN_DIR}/prepare_sources.stamp"
  DEPENDS "${UGS_SOURCE_TREE}"
  COMMENT "Preparing patched/generated UGS sources"
)

add_custom_target(prepare_sources
  DEPENDS "${UGS_GEN_DIR}/prepare_sources.stamp"
)

add_library(${PROJECT_NAME} STATIC ${UGS_SOURCE_PATHS})
add_dependencies(${PROJECT_NAME} prepare_sources)

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

# Prepare compiler-specific flags for legacy calling conventions
set(_f77_compat_flags "")
if(UGS_F77_COMPAT AND CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
  list(APPEND _f77_compat_flags -fallow-argument-mismatch -std=legacy)
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
  add_dependencies(xwtest prepare_sources)
  target_compile_options(xwtest PRIVATE -DSELFTEST)
  target_include_directories(xwtest PRIVATE ${UGS_GEN_DIR}/drivers ${X11_INCLUDE_DIR})
  target_link_libraries(xwtest PRIVATE ${X11_LIBRARIES} ${X11_Xaw_LIB} ${X11_Xmu_LIB} ${X11_Xt_LIB})
  install(TARGETS xwtest RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()

# ---------------------------------------------------------------------------
# Package config generation
# ---------------------------------------------------------------------------
set(_PKG_CONFIG_IN "${CMAKE_SOURCE_DIR}/ProjectConfig.cmake.in")
if(NOT EXISTS "${_PKG_CONFIG_IN}")
  set(_PKG_CONFIG_IN "${CMAKE_SOURCE_DIR}/cmake/ProjectConfig.cmake.in")
endif()
if(NOT EXISTS "${_PKG_CONFIG_IN}")
  message(FATAL_ERROR "ProjectConfig.cmake.in not found; please add it to the source tree.")
endif()

configure_package_config_file(
  "${_PKG_CONFIG_IN}"
  "${CMAKE_CURRENT_BINARY_DIR}/ugsConfig.cmake"
  INSTALL_DESTINATION "${PACKAGE_CONFIG_INSTALL_DIR}"
)

write_basic_package_version_file(
  "${CMAKE_CURRENT_BINARY_DIR}/ugsConfigVersion.cmake"
  VERSION "${PROJECT_VERSION}"
  COMPATIBILITY SameMajorVersion
)

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
install(TARGETS ${PROJECT_NAME}
  EXPORT ugsTargets
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/ugs
)

install(EXPORT ugsTargets NAMESPACE ugs:: DESTINATION ${PACKAGE_CONFIG_INSTALL_DIR})
install(FILES
  "${CMAKE_CURRENT_BINARY_DIR}/ugsConfig.cmake"
  "${CMAKE_CURRENT_BINARY_DIR}/ugsConfigVersion.cmake"
  DESTINATION "${PACKAGE_CONFIG_INSTALL_DIR}"
)

# ---------------------------------------------------------------------------
# Uninstall target
# ---------------------------------------------------------------------------
set(_UNINSTALL_IN "${CMAKE_SOURCE_DIR}/cmake/Uninstall.cmake.in")
if(EXISTS "${_UNINSTALL_IN}")
  configure_file("${_UNINSTALL_IN}" "${CMAKE_BINARY_DIR}/cmake_uninstall.cmake" IMMEDIATE @ONLY)
  add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P "${CMAKE_BINARY_DIR}/cmake_uninstall.cmake"
    COMMENT "Uninstall previously installed files")
else()
  message(WARNING "cmake/Uninstall.cmake.in not found; 'uninstall' target is disabled.")
endif()

# ---------------------------------------------------------------------------
# Cleaning policy
# - Default `clean` removes build artefacts only. It DOES NOT remove:
#   * source archives in ${ARCHIVE_DIR} (user-provided)
#   * downloaded archives in ${DOWNLOAD_CACHE_DIR}
# Optional: remove download cache (use with care)
add_download_cleanup_target(clean_downloads)

# --- Enable tests ---
include(CTest)
if(BUILD_TESTING)
  add_subdirectory(tests)
endif()
