if(NOT DEFINED CONTRACT_PROGRAM OR NOT EXISTS "${CONTRACT_PROGRAM}")
  message(FATAL_ERROR "Contract program is missing: ${CONTRACT_PROGRAM}")
endif()

if(DEFINED CONTRACT_OUTPUT AND NOT CONTRACT_OUTPUT STREQUAL "")
  file(REMOVE "${CONTRACT_OUTPUT}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" -E env LC_ALL=C TZ=UTC "${CONTRACT_PROGRAM}"
  WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
  RESULT_VARIABLE contract_result
  OUTPUT_VARIABLE contract_stdout
  ERROR_VARIABLE contract_stderr)
if(NOT contract_result EQUAL 0)
  message(FATAL_ERROR
    "Contract program failed (${contract_result}).\n"
    "stdout:\n${contract_stdout}\n"
    "stderr:\n${contract_stderr}")
endif()

if(DEFINED CONTRACT_OUTPUT AND NOT CONTRACT_OUTPUT STREQUAL "" AND
   NOT EXISTS "${CONTRACT_OUTPUT}")
  message(FATAL_ERROR
    "Contract program did not create its expected output: ${CONTRACT_OUTPUT}")
endif()
