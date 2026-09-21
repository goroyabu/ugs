if(NOT DEFINED POSTSCRIPT_CONTRACT_BIN OR
   NOT EXISTS "${POSTSCRIPT_CONTRACT_BIN}")
  message(FATAL_ERROR
    "PostScript contract executable is missing: ${POSTSCRIPT_CONTRACT_BIN}")
endif()
if(NOT DEFINED POSTSCRIPT_OUTPUT OR POSTSCRIPT_OUTPUT STREQUAL "")
  message(FATAL_ERROR "POSTSCRIPT_OUTPUT is required")
endif()

file(REMOVE "${POSTSCRIPT_OUTPUT}")

execute_process(
  COMMAND "${CMAKE_COMMAND}" -E env LC_ALL=C TZ=UTC
    "${POSTSCRIPT_CONTRACT_BIN}"
  WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
  RESULT_VARIABLE contract_result
  OUTPUT_VARIABLE contract_stdout
  ERROR_VARIABLE contract_stderr)
if(NOT contract_result EQUAL 0)
  message(FATAL_ERROR
    "PostScript contract program failed (${contract_result}).\n"
    "stdout:\n${contract_stdout}\n"
    "stderr:\n${contract_stderr}")
endif()

if(NOT EXISTS "${POSTSCRIPT_OUTPUT}")
  message(FATAL_ERROR "PostScript output was not created: ${POSTSCRIPT_OUTPUT}")
endif()

file(READ "${POSTSCRIPT_OUTPUT}" postscript_content)
if(NOT postscript_content MATCHES "^%!PS-Adobe-")
  message(FATAL_ERROR "PostScript output has an unexpected header")
endif()

string(REGEX MATCHALL "%%Page: 1 1" page_headers "${postscript_content}")
list(LENGTH page_headers page_header_count)
if(NOT page_header_count EQUAL 1)
  message(FATAL_ERROR
    "PostScript output must contain one page header; found ${page_header_count}")
endif()

string(REGEX MATCHALL "showpage" showpage_commands "${postscript_content}")
list(LENGTH showpage_commands showpage_count)
if(NOT showpage_count EQUAL 1)
  message(FATAL_ERROR
    "PostScript output must contain one showpage command; found ${showpage_count}")
endif()

file(STRINGS "${POSTSCRIPT_OUTPUT}" postscript_lines)
set(drawing_commands)
foreach(line IN LISTS postscript_lines)
  if(line STREQUAL "N" OR line STREQUAL "S" OR
     line MATCHES "^[0-9-]+ [0-9-]+ [MD]$")
    list(APPEND drawing_commands "${line}")
  endif()
endforeach()

set(expected_drawing_commands
  N
  "375 2550 M"
  "2175 750 D"
  S
  N
  "2175 2550 M"
  "375 750 D"
  S)
if(NOT drawing_commands STREQUAL expected_drawing_commands)
  message(FATAL_ERROR
    "PostScript drawing commands did not represent the two requested lines.\n"
    "Expected: ${expected_drawing_commands}\n"
    "Actual:   ${drawing_commands}")
endif()

message(STATUS "PostScript filename and line semantics contract passed")
