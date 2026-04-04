if(NOT DEFINED XWTEST_SMOKE_BIN)
  message(FATAL_ERROR "XWTEST_SMOKE_BIN is required")
endif()

if(NOT DEFINED EXPECTED_PPM)
  message(FATAL_ERROR "EXPECTED_PPM is required")
endif()

if(NOT DEFINED ACTUAL_PPM)
  message(FATAL_ERROR "ACTUAL_PPM is required")
endif()

get_filename_component(_actual_dir "${ACTUAL_PPM}" DIRECTORY)
file(MAKE_DIRECTORY "${_actual_dir}")
file(REMOVE "${ACTUAL_PPM}")

set(_cmd ${CMAKE_COMMAND} -E env LC_ALL=C TZ=UTC)
if(DEFINED XWTEST_SMOKE_DISPLAY AND NOT XWTEST_SMOKE_DISPLAY STREQUAL "")
  list(APPEND _cmd DISPLAY=${XWTEST_SMOKE_DISPLAY})
endif()
list(APPEND _cmd "${XWTEST_SMOKE_BIN}" --capture "${ACTUAL_PPM}")

execute_process(
  COMMAND ${_cmd}
  RESULT_VARIABLE _run_result
  COMMAND_ECHO STDOUT
)
if(NOT _run_result EQUAL 0)
  message(FATAL_ERROR "visual smoke harness failed with exit code ${_run_result}")
endif()

execute_process(
  COMMAND ${CMAKE_COMMAND} -E compare_files "${ACTUAL_PPM}" "${EXPECTED_PPM}"
  RESULT_VARIABLE _compare_result
)
if(NOT _compare_result EQUAL 0)
  message(FATAL_ERROR
    "visual smoke image mismatch\n"
    "expected: ${EXPECTED_PPM}\n"
    "actual:   ${ACTUAL_PPM}")
endif()
