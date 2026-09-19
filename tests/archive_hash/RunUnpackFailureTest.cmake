foreach(_required_var FETCH_MODULE TEST_ROOT)
  if(NOT DEFINED ${_required_var})
    message(FATAL_ERROR "Required test variable is missing: ${_required_var}")
  endif()
endforeach()

file(REMOVE_RECURSE "${TEST_ROOT}")
set(_source_dir "${TEST_ROOT}/source")
set(_build_dir "${TEST_ROOT}/build")
set(_archive_dir "${TEST_ROOT}/archives")
file(MAKE_DIRECTORY "${_source_dir}" "${_archive_dir}")
file(WRITE "${_archive_dir}/ugs.tar.gz" "not a valid archive\n")
file(SHA256 "${_archive_dir}/ugs.tar.gz" _actual_sha)

file(WRITE "${_source_dir}/CMakeLists.txt" [=[
cmake_minimum_required(VERSION 3.15)
project(archive_unpack_failure NONE)
set(NET_FETCH OFF)
set(UGS_ALLOW_UNVERIFIED_ARCHIVES ON)
include("${FETCH_MODULE}")
fetch_and_unpack_configure_dirs()
resolve_input_file(_archive
  "file:///unused/ugs.tar.gz"
  "0000000000000000000000000000000000000000000000000000000000000000"
  "${ARCHIVE_DIR}/ugs.tar.gz")
add_unpack_archive("${CMAKE_BINARY_DIR}/vendor/ugs.stamp"
  "${CMAKE_BINARY_DIR}/vendor"
  "${_archive}"
  COMMENT "Unpacking intentionally invalid archive"
  COMMAND ${CMAKE_COMMAND} -E tar xzf)
add_unpack_target(unpack)
]=])

execute_process(
  COMMAND "${CMAKE_COMMAND}"
    -S "${_source_dir}"
    -B "${_build_dir}"
    "-DFETCH_MODULE=${FETCH_MODULE}"
    "-DARCHIVE_DIR=${_archive_dir}"
    "-DDOWNLOAD_CACHE_DIR=${TEST_ROOT}/cache"
  RESULT_VARIABLE _configure_result
  OUTPUT_VARIABLE _configure_stdout
  ERROR_VARIABLE _configure_stderr)
if(NOT _configure_result EQUAL 0)
  message(FATAL_ERROR
    "Unsupported-mode configure should accept the mismatch:\n"
    "${_configure_stdout}${_configure_stderr}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" --build "${_build_dir}" --target unpack
  RESULT_VARIABLE _build_result
  OUTPUT_VARIABLE _build_stdout
  ERROR_VARIABLE _build_stderr)
if(_build_result EQUAL 0)
  message(FATAL_ERROR "Invalid archive unexpectedly unpacked successfully")
endif()
string(CONCAT _build_log "${_build_stdout}" "${_build_stderr}")
string(FIND "${_build_log}" "Unpacking intentionally invalid archive"
  _unpack_message_index)
if(_unpack_message_index EQUAL -1)
  message(FATAL_ERROR "Unpack failure log lacked target context:\n${_build_log}")
endif()
