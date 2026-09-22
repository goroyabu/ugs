include("${CMAKE_CURRENT_LIST_DIR}/../../contracts/PostScriptContract.cmake")

if(NOT DEFINED EXTENDED_TEXT_CONTRACT_BIN)
  message(FATAL_ERROR "EXTENDED_TEXT_CONTRACT_BIN is required")
endif()
if(NOT DEFINED UGXTXT_OUTPUT OR UGXTXT_OUTPUT STREQUAL "")
  message(FATAL_ERROR "UGXTXT_OUTPUT is required")
endif()
if(NOT DEFINED UGPLIN_OUTPUT OR UGPLIN_OUTPUT STREQUAL "")
  message(FATAL_ERROR "UGPLIN_OUTPUT is required")
endif()

run_postscript_program(
  "${EXTENDED_TEXT_CONTRACT_BIN}"
  "${UGXTXT_OUTPUT}"
  "${UGPLIN_OUTPUT}")
read_postscript_drawing_commands("${UGXTXT_OUTPUT}" ugxtxt_commands)
read_postscript_drawing_commands("${UGPLIN_OUTPUT}" ugplin_commands)

require_visible_postscript_lines(ugxtxt_commands "UGXTXT output")
require_visible_postscript_lines(ugplin_commands "UGCTOL+UGPLIN output")

if(NOT ugxtxt_commands STREQUAL ugplin_commands)
  message(FATAL_ERROR
    "UGXTXT and UGCTOL+UGPLIN produced different visible line geometry.\n"
    "UGXTXT:       ${ugxtxt_commands}\n"
    "UGCTOL+UGPLIN: ${ugplin_commands}")
endif()

message(STATUS "Extended text drawing equivalence contract passed")
