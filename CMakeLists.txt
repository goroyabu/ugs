cmake_minimum_required(VERSION 3.15)
project(ugs VERSION 0.2.0 LANGUAGES C Fortran)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(FetchAndUnpack)

# ------------------------------------------------------------
# Options
# ------------------------------------------------------------
option(NET_FETCH              "Allow downloading upstream archives when local archives are missing" ON)
option(BUILD_TESTING "Enable building and running tests" ON)
option(UGS_ALLOW_UNVERIFIED_ARCHIVES
  "Allow SHA256-mismatched upstream archives for unsupported local experiments" OFF)

option(UGS_BUILD_XWTEST       "Build the legacy xwtest sample program" OFF)
option(UGS_F77_COMPAT "Enable legacy F77 calling convention compatibility (e.g., allow argument mismatch for %VAL-style calls)" ON)
option(UGS_ENABLE_GUI_SMOKE "Register the GUI/X11 smoke test case 01_smoke" ON)

fetch_and_unpack_configure_dirs()

set(PACKAGE_CONFIG_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")
set(XWTEST_SMOKE_DISPLAY "" CACHE STRING "Override DISPLAY when running the xwtest_smoke ctest (empty = inherit from environment)")
string(TOUPPER "${PROJECT_NAME}" PROJECT_NAME_UPPER)

# ------------------------------------------------------------
# Layout / Source acquisition (using helper)
# ------------------------------------------------------------
set(VENDOR_ROOT "${CMAKE_BINARY_DIR}/vendor")
set(GEN_DIR     "${CMAKE_BINARY_DIR}/generated")

set(UGS_SRC_ROOT "${VENDOR_ROOT}/ugs")
set(UGS_SRC_URL  "http://ftp.riken.jp/iris/ugs/ugs.tar.gz")
get_property(_legacy_ugs_hash_override CACHE UGS_SRC_SHA256 PROPERTY TYPE SET)
if(_legacy_ugs_hash_override)
  message(WARNING
    "The UGS_SRC_SHA256 cache override is no longer supported and will be "
    "removed. Use UGS_ALLOW_UNVERIFIED_ARCHIVES=ON only for an unsupported "
    "local experiment with a known archive.")
endif()
unset(UGS_SRC_SHA256 CACHE)
set(_UGS_SRC_SHA256 "27bc46e975917bdf149e9ff6997885ffa24b0b1416bdf82ffaea5246b36e1f83")
set(UGS_SRC_LOCAL   "${ARCHIVE_DIR}/ugs.tar.gz")

resolve_input_file(UGS_SRC_TGZ "${UGS_SRC_URL}" "${_UGS_SRC_SHA256}" "${UGS_SRC_LOCAL}")
add_unpack_archive("${UGS_SRC_ROOT}.stamp" "${VENDOR_ROOT}" "${UGS_SRC_TGZ}"
  COMMENT "Unpacking UGS sources"
  RESET_PATH "${UGS_SRC_ROOT}"
  COMMAND ${CMAKE_COMMAND} -E tar xzf)
add_unpack_target(unpack)

set(UGS_SOURCE_TREE "${UGS_SRC_ROOT}/src.2.10e")

# ------------------------------------------------------------
# Enumerate sources
# ------------------------------------------------------------
set(UGS_SOURCE_MANIFEST
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake/UgsSourceManifest.cmake")
include("${UGS_SOURCE_MANIFEST}")

# ------------------------------------------------------------
# Targets
# ------------------------------------------------------------
find_package(X11 REQUIRED)

set(UGS_SOURCE_PATHS)
foreach(src_name IN LISTS UGS_SOURCE_NAMES)
  list(APPEND UGS_SOURCE_PATHS "${GEN_DIR}/${src_name}")
endforeach()

set(UGS_PREPARED_OUTPUTS ${UGS_SOURCE_PATHS})
foreach(system_name IN LISTS UGS_SYSTEM_ROOT_FILES)
  list(APPEND UGS_PREPARED_OUTPUTS "${GEN_DIR}/UGSYSTEM_${system_name}")
endforeach()
foreach(system_name IN LISTS UGS_SYSTEM_DRIVER_FILES)
  list(APPEND UGS_PREPARED_OUTPUTS
    "${GEN_DIR}/drivers/UGSYSTEM_${system_name}")
endforeach()
foreach(relative_path IN LISTS
    UGS_COPIED_ASSETS UGS_GENERATED_HEADERS UGS_TEST_ONLY_PREPARED_SOURCES)
  list(APPEND UGS_PREPARED_OUTPUTS "${GEN_DIR}/${relative_path}")
endforeach()
list(REMOVE_DUPLICATES UGS_PREPARED_OUTPUTS)

set(_ugs_fixed_form_sources)
foreach(src_path IN LISTS UGS_SOURCE_PATHS)
  if(src_path MATCHES "\\.f$")
    list(APPEND _ugs_fixed_form_sources "${src_path}")
  endif()
endforeach()

set_source_files_properties(${UGS_PREPARED_OUTPUTS}
  PROPERTIES GENERATED TRUE
)
if(_ugs_fixed_form_sources)
  set_source_files_properties(${_ugs_fixed_form_sources}
    PROPERTIES Fortran_PREPROCESS OFF
  )
endif()

add_custom_target(prepare_sources
  COMMAND ${CMAKE_COMMAND}
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
  VERBATIM
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

target_include_directories(${PROJECT_NAME} PRIVATE ${GEN_DIR}/drivers ${X11_INCLUDE_DIR})
target_link_libraries(${PROJECT_NAME}
  PRIVATE ${X11_LIBRARIES} ${X11_Xaw_LIB} ${X11_Xmu_LIB} ${X11_Xt_LIB}
)
if(UNIX AND NOT APPLE)
  target_link_libraries(${PROJECT_NAME} PRIVATE m)
endif()

if(UGS_BUILD_XWTEST)
  set(_out_xwin "${GEN_DIR}/drivers/xwindowc_selftest.c")

  add_executable(xwtest
    "${_out_xwin}"
    ${GEN_DIR}/drivers/cursor1.bmp
    ${GEN_DIR}/drivers/cursor2.bmp
    ${GEN_DIR}/drivers/icon.bmp
    ${GEN_DIR}/drivers/rotated.c
  )
  add_dependencies(xwtest prepare_sources)
  target_compile_options(xwtest PRIVATE -DSELFTEST)
  target_include_directories(xwtest PRIVATE ${GEN_DIR}/drivers ${X11_INCLUDE_DIR})
  target_link_libraries(xwtest PRIVATE ${X11_LIBRARIES} ${X11_Xaw_LIB} ${X11_Xmu_LIB} ${X11_Xt_LIB})
  if(UNIX AND NOT APPLE)
    target_link_libraries(xwtest PRIVATE m)
  endif()
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
