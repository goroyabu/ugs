function(run_postscript_program executable output_file)
  if(NOT EXISTS "${executable}")
    message(FATAL_ERROR "PostScript contract executable is missing: ${executable}")
  endif()
  if(output_file STREQUAL "")
    message(FATAL_ERROR "PostScript contract output path is required")
  endif()

  file(REMOVE "${output_file}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E env LC_ALL=C TZ=UTC "${executable}"
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

  if(NOT EXISTS "${output_file}")
    message(FATAL_ERROR "PostScript output was not created: ${output_file}")
  endif()
endfunction()

function(read_postscript_drawing_commands output_file result_variable)
  file(READ "${output_file}" postscript_content)
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

  file(STRINGS "${output_file}" postscript_lines)
  set(drawing_commands)
  foreach(line IN LISTS postscript_lines)
    if(line STREQUAL "N" OR line STREQUAL "S" OR
       line MATCHES "^[0-9-]+ [0-9-]+ [MD]$")
      list(APPEND drawing_commands "${line}")
    endif()
  endforeach()

  set(${result_variable} "${drawing_commands}" PARENT_SCOPE)
endfunction()
