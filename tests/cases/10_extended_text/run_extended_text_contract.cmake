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
  "UGXTXT"
  "extended-text-ugxtxt.ps")
run_postscript_program(
  "${EXTENDED_TEXT_CONTRACT_BIN}"
  "${UGPLIN_OUTPUT}"
  "UGCTOL+UGPLIN"
  "extended-text-ugplin.ps")
read_postscript_drawing_commands("${UGXTXT_OUTPUT}" ugxtxt_commands)
read_postscript_drawing_commands("${UGPLIN_OUTPUT}" ugplin_commands)

function(require_visible_lines commands_variable label)
  set(commands "${${commands_variable}}")
  set(line_count 0)
  foreach(command IN LISTS commands)
    if(command MATCHES "^[0-9-]+ [0-9-]+ D$")
      math(EXPR line_count "${line_count} + 1")
    endif()
  endforeach()

  list(FIND commands "S" stroke_index)
  if(line_count EQUAL 0 OR stroke_index EQUAL -1)
    message(FATAL_ERROR
      "${label} did not contain visible line and stroke commands: ${commands}")
  endif()
endfunction()

require_visible_lines(ugxtxt_commands "UGXTXT output")
require_visible_lines(ugplin_commands "UGCTOL+UGPLIN output")

if(NOT ugxtxt_commands STREQUAL ugplin_commands)
  message(FATAL_ERROR
    "UGXTXT and UGCTOL+UGPLIN produced different visible line geometry.\n"
    "UGXTXT:       ${ugxtxt_commands}\n"
    "UGCTOL+UGPLIN: ${ugplin_commands}")
endif()

message(STATUS "Extended text drawing equivalence contract passed")
