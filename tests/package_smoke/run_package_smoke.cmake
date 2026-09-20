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

file(REMOVE_RECURSE "${PACKAGE_PREFIX}" "${PACKAGE_SMOKE_BINARY_DIR}")

execute_process(
  COMMAND "${CMAKE_COMMAND}" --install "${MAIN_BUILD_DIR}" --prefix "${PACKAGE_PREFIX}"
  RESULT_VARIABLE _install_result
)
if(NOT _install_result EQUAL 0)
  message(FATAL_ERROR "Package smoke install step failed: ${_install_result}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}"
    -S "${PACKAGE_SMOKE_SOURCE_DIR}"
    -B "${PACKAGE_SMOKE_BINARY_DIR}"
    "-DCMAKE_PREFIX_PATH=${PACKAGE_PREFIX}"
    "-DUGS_EXPECTED_PREFIX=${PACKAGE_PREFIX}"
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

set(_smoke_output "${PACKAGE_SMOKE_BINARY_DIR}/ugs-example.ps")
file(REMOVE "${_smoke_output}")

execute_process(
  COMMAND "${CMAKE_COMMAND}" -E chdir "${PACKAGE_SMOKE_BINARY_DIR}"
    "${CMAKE_CTEST_COMMAND}"
    --output-on-failure
  RESULT_VARIABLE _run_result
)
if(NOT _run_result EQUAL 0)
  message(FATAL_ERROR "Package smoke test failed: ${_run_result}")
endif()

if(NOT EXISTS "${_smoke_output}")
  message(FATAL_ERROR "Package smoke did not create ${_smoke_output}")
endif()

file(SIZE "${_smoke_output}" _smoke_output_size)
if(_smoke_output_size EQUAL 0)
  message(FATAL_ERROR "Package smoke created an empty PostScript file")
endif()

file(STRINGS "${_smoke_output}" _smoke_first_line LIMIT_COUNT 1)
if(NOT _smoke_first_line MATCHES "^%!PS-Adobe-")
  message(FATAL_ERROR
    "Package smoke created an unexpected PostScript header: ${_smoke_first_line}")
endif()
