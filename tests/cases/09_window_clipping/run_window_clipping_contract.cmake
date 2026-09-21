include("${CMAKE_CURRENT_LIST_DIR}/../../contracts/PostScriptContract.cmake")

if(NOT DEFINED WINDOW_CONTRACT_BIN)
  message(FATAL_ERROR "WINDOW_CONTRACT_BIN is required")
endif()
if(NOT DEFINED POSTSCRIPT_OUTPUT OR POSTSCRIPT_OUTPUT STREQUAL "")
  message(FATAL_ERROR "POSTSCRIPT_OUTPUT is required")
endif()

run_postscript_program("${WINDOW_CONTRACT_BIN}" "${POSTSCRIPT_OUTPUT}")
read_postscript_drawing_commands("${POSTSCRIPT_OUTPUT}" drawing_commands)

set(expected_drawing_commands
  N
  "870 2055 M"
  "1680 1245 D"
  S
  N
  "1275 2325 M"
  "1275 975 D"
  S)
if(NOT drawing_commands STREQUAL expected_drawing_commands)
  message(FATAL_ERROR
    "Mapped and clipped drawing commands differ from the contract.\n"
    "Expected: ${expected_drawing_commands}\n"
    "Actual:   ${drawing_commands}")
endif()

message(STATUS "Window mapping and clipping contract passed")
