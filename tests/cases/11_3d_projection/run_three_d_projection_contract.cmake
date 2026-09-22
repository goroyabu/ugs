include("${CMAKE_CURRENT_LIST_DIR}/../../contracts/PostScriptContract.cmake")

if(NOT DEFINED THREE_D_CONTRACT_BIN)
  message(FATAL_ERROR "THREE_D_CONTRACT_BIN is required")
endif()
foreach(required_output IN ITEMS STATE_OUTPUT PARALLEL_OUTPUT POINT_OUTPUT)
  if(NOT DEFINED ${required_output} OR "${${required_output}}" STREQUAL "")
    message(FATAL_ERROR "${required_output} is required")
  endif()
endforeach()

run_postscript_program(
  "${THREE_D_CONTRACT_BIN}"
  "${STATE_OUTPUT}"
  "${PARALLEL_OUTPUT}"
  "${POINT_OUTPUT}")
read_postscript_drawing_commands("${PARALLEL_OUTPUT}" parallel_commands)
read_postscript_drawing_commands("${POINT_OUTPUT}" point_commands)

set(expected_parallel_commands
  N
  "963 1962 M"
  "963 1338 D"
  "1587 1338 D"
  S)
if(NOT parallel_commands STREQUAL expected_parallel_commands)
  message(FATAL_ERROR
    "Parallel 3D projection commands differ from the contract.\n"
    "Expected: ${expected_parallel_commands}\n"
    "Actual:   ${parallel_commands}")
endif()

require_visible_postscript_lines(point_commands "Point-projection output")
list(LENGTH point_commands point_command_count)
if(NOT point_command_count EQUAL 5)
  message(FATAL_ERROR
    "Point projection must contain one move, two lines, and one stroke: "
    "${point_commands}")
endif()
list(GET point_commands 0 point_begin)
list(GET point_commands 1 point_move)
list(GET point_commands 2 point_line_one)
list(GET point_commands 3 point_line_two)
list(GET point_commands 4 point_stroke)
if(NOT point_begin STREQUAL "N" OR
   NOT point_move MATCHES "^[0-9-]+ [0-9-]+ M$" OR
   NOT point_line_one MATCHES "^[0-9-]+ [0-9-]+ D$" OR
   NOT point_line_two MATCHES "^[0-9-]+ [0-9-]+ D$" OR
   NOT point_stroke STREQUAL "S")
  message(FATAL_ERROR
    "Point projection has an unexpected drawing-command shape: "
    "${point_commands}")
endif()
if(point_commands STREQUAL parallel_commands)
  message(FATAL_ERROR
    "Depth-varying point projection unexpectedly matches parallel geometry")
endif()

message(STATUS "Three-dimensional view and projection contract passed")
