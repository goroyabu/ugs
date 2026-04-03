if(NOT DEFINED MAIN_BUILD_DIR OR MAIN_BUILD_DIR STREQUAL "")
  message(FATAL_ERROR "MAIN_BUILD_DIR is required")
endif()

if(NOT DEFINED PACKAGE_PREFIX OR PACKAGE_PREFIX STREQUAL "")
  message(FATAL_ERROR "PACKAGE_PREFIX is required")
endif()

if(NOT DEFINED PACKAGE_SMOKE_SOURCE_DIR OR PACKAGE_SMOKE_SOURCE_DIR STREQUAL "")
  message(FATAL_ERROR "PACKAGE_SMOKE_SOURCE_DIR is required")
endif()

if(NOT DEFINED PACKAGE_SMOKE_BINARY_DIR OR PACKAGE_SMOKE_BINARY_DIR STREQUAL "")
  message(FATAL_ERROR "PACKAGE_SMOKE_BINARY_DIR is required")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" --install "${MAIN_BUILD_DIR}" --prefix "${PACKAGE_PREFIX}"
  RESULT_VARIABLE _install_result
)
if(NOT _install_result EQUAL 0)
  message(FATAL_ERROR "Package smoke install step failed: ${_install_result}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" -E rm -rf "${PACKAGE_SMOKE_BINARY_DIR}"
  RESULT_VARIABLE _clean_result
)
if(NOT _clean_result EQUAL 0)
  message(FATAL_ERROR "Package smoke cleanup failed: ${_clean_result}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}"
    -S "${PACKAGE_SMOKE_SOURCE_DIR}"
    -B "${PACKAGE_SMOKE_BINARY_DIR}"
    "-DCMAKE_PREFIX_PATH=${PACKAGE_PREFIX}"
  RESULT_VARIABLE _configure_result
)
if(NOT _configure_result EQUAL 0)
  message(FATAL_ERROR "Package smoke configure failed: ${_configure_result}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" --build "${PACKAGE_SMOKE_BINARY_DIR}" --parallel
  RESULT_VARIABLE _build_result
)
if(NOT _build_result EQUAL 0)
  message(FATAL_ERROR "Package smoke build failed: ${_build_result}")
endif()
