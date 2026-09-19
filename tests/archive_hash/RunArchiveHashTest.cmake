foreach(_required_var TEST_CASE FETCH_MODULE TEST_ROOT RESOLVE_SCRIPT)
  if(NOT DEFINED ${_required_var})
    message(FATAL_ERROR "Required test variable is missing: ${_required_var}")
  endif()
endforeach()

string(FIND "${TEST_ROOT}" "/archive-hash-tests/" _safe_test_root_index)
if(_safe_test_root_index EQUAL -1)
  message(FATAL_ERROR
    "Refusing to clean a test path outside archive-hash-tests: ${TEST_ROOT}")
endif()
file(REMOVE_RECURSE "${TEST_ROOT}")
set(_archive_dir "${TEST_ROOT}/custom-archives")
set(_cache_dir "${TEST_ROOT}/custom-cache")
set(_download_source_dir "${TEST_ROOT}/download-source")
file(MAKE_DIRECTORY "${_archive_dir}" "${_cache_dir}" "${_download_source_dir}")

set(_archive_name "ugs.tar.gz")

set(_good_contents "known upstream archive contents\n")
set(_bad_contents "changed archive contents\n")
set(_hash_input "${TEST_ROOT}/expected-hash-input")
file(WRITE "${_hash_input}" "${_good_contents}")
file(SHA256 "${_hash_input}" _expected_sha)
set(_bad_hash_input "${TEST_ROOT}/actual-hash-input")
file(WRITE "${_bad_hash_input}" "${_bad_contents}")
file(SHA256 "${_bad_hash_input}" _bad_sha)

set(_local_hint "${_archive_dir}/${_archive_name}")
set(_cache_path "${_cache_dir}/${_archive_name}")
set(_download_source "${_download_source_dir}/${_archive_name}")
set(_test_url "file://${_download_source}")
set(_net_fetch OFF)
set(_allow_unverified OFF)
set(_expect_success ON)
set(_expect_mismatch_details OFF)
set(_expect_allow_mode_warning OFF)
set(_expect_cache_absent OFF)

if(TEST_CASE STREQUAL "local_valid")
  file(WRITE "${_local_hint}" "${_good_contents}")
  set(_expected_path "${_local_hint}")
elseif(TEST_CASE STREQUAL "local_mismatch_strict")
  file(WRITE "${_local_hint}" "${_bad_contents}")
  set(_expect_success OFF)
  set(_mismatch_path "${_local_hint}")
elseif(TEST_CASE STREQUAL "cache_valid")
  file(WRITE "${_cache_path}" "${_good_contents}")
  set(_net_fetch ON)
  set(_expected_path "${_cache_path}")
elseif(TEST_CASE STREQUAL "cache_mismatch_strict")
  file(WRITE "${_cache_path}" "${_bad_contents}")
  set(_net_fetch ON)
  set(_expect_success OFF)
  set(_mismatch_path "${_cache_path}")
elseif(TEST_CASE STREQUAL "download_valid")
  file(WRITE "${_download_source}" "${_good_contents}")
  set(_net_fetch ON)
  set(_expected_path "${_cache_path}")
elseif(TEST_CASE STREQUAL "download_mismatch_strict")
  file(WRITE "${_download_source}" "${_bad_contents}")
  set(_net_fetch ON)
  set(_expect_success OFF)
  set(_mismatch_path "${_cache_path}")
elseif(TEST_CASE STREQUAL "no_fallback_after_mismatch")
  file(WRITE "${_local_hint}" "${_bad_contents}")
  file(WRITE "${_cache_path}" "${_good_contents}")
  set(_net_fetch ON)
  set(_expect_success OFF)
  set(_expect_mismatch_details ON)
  set(_mismatch_path "${_local_hint}")
elseif(TEST_CASE STREQUAL "local_mismatch_allowed")
  file(WRITE "${_local_hint}" "${_bad_contents}")
  set(_allow_unverified ON)
  set(_expect_mismatch_details ON)
  set(_mismatch_path "${_local_hint}")
  set(_expected_path "${_local_hint}")
elseif(TEST_CASE STREQUAL "cache_mismatch_allowed")
  file(WRITE "${_cache_path}" "${_bad_contents}")
  set(_net_fetch ON)
  set(_allow_unverified ON)
  set(_expect_mismatch_details ON)
  set(_mismatch_path "${_cache_path}")
  set(_expected_path "${_cache_path}")
elseif(TEST_CASE STREQUAL "download_mismatch_allowed")
  file(WRITE "${_download_source}" "${_bad_contents}")
  set(_net_fetch ON)
  set(_allow_unverified ON)
  set(_expect_mismatch_details ON)
  set(_mismatch_path "${_cache_path}")
  set(_expected_path "${_cache_path}")
elseif(TEST_CASE STREQUAL "valid_archive_allowed_mode_warning")
  file(WRITE "${_local_hint}" "${_good_contents}")
  set(_allow_unverified ON)
  set(_expect_allow_mode_warning ON)
  set(_expected_path "${_local_hint}")
elseif(TEST_CASE STREQUAL "no_fallback_after_mismatch_allowed")
  file(WRITE "${_local_hint}" "${_bad_contents}")
  file(WRITE "${_cache_path}" "${_good_contents}")
  set(_net_fetch ON)
  set(_allow_unverified ON)
  set(_expect_mismatch_details ON)
  set(_mismatch_path "${_local_hint}")
  set(_expected_path "${_local_hint}")
elseif(TEST_CASE STREQUAL "missing_input_allowed")
  file(WRITE "${_cache_path}" "${_good_contents}")
  set(_allow_unverified ON)
  set(_expect_success OFF)
  set(_expected_failure_text "Required file not found")
elseif(TEST_CASE STREQUAL "download_failure_allowed")
  set(_net_fetch ON)
  set(_allow_unverified ON)
  set(_expect_success OFF)
  set(_expect_cache_absent ON)
  set(_expected_failure_text
    "Failed to download upstream archive"
    "${_test_url}"
    "${_cache_path}"
    "Reason:")
else()
  message(FATAL_ERROR "Unknown archive-hash test case: ${TEST_CASE}")
endif()

set(_result_file "${TEST_ROOT}/resolved-path")
execute_process(
  COMMAND "${CMAKE_COMMAND}"
    "-DFETCH_MODULE=${FETCH_MODULE}"
    "-DARCHIVE_DIR=${_archive_dir}"
    "-DDOWNLOAD_CACHE_DIR=${_cache_dir}"
    "-DTEST_URL=${_test_url}"
    "-DEXPECTED_SHA=${_expected_sha}"
    "-DLOCAL_HINT=${_local_hint}"
    "-DNET_FETCH=${_net_fetch}"
    "-DALLOW_UNVERIFIED=${_allow_unverified}"
    "-DRESULT_FILE=${_result_file}"
    -P "${RESOLVE_SCRIPT}"
  RESULT_VARIABLE _child_result
  OUTPUT_VARIABLE _child_stdout
  ERROR_VARIABLE _child_stderr)
string(CONCAT _child_log "${_child_stdout}" "${_child_stderr}")

if(_expect_success)
  if(NOT _child_result EQUAL 0)
    message(FATAL_ERROR
      "Expected ${TEST_CASE} to succeed, but it failed:\n${_child_log}")
  endif()
  if(NOT EXISTS "${_result_file}")
    message(FATAL_ERROR "Successful case did not record the selected path")
  endif()
  file(READ "${_result_file}" _actual_path)
  if(NOT _actual_path STREQUAL _expected_path)
    message(FATAL_ERROR
      "Selected path mismatch. Expected '${_expected_path}', got '${_actual_path}'")
  endif()
  if(_expect_mismatch_details)
    foreach(_expected_text
        "SHA256 mismatch"
        "${_mismatch_path}"
        "${_expected_sha}"
        "${_bad_sha}"
        "UGS_ALLOW_UNVERIFIED_ARCHIVES=ON"
        "outside standard support"
        "release builds")
      string(FIND "${_child_log}" "${_expected_text}" _match_index)
      if(_match_index EQUAL -1)
        message(FATAL_ERROR
          "Warning output did not contain '${_expected_text}':\n${_child_log}")
      endif()
    endforeach()
  endif()
  if(_expect_allow_mode_warning)
    foreach(_expected_text
        "UGS_ALLOW_UNVERIFIED_ARCHIVES=ON"
        "outside standard support"
        "release builds")
      string(FIND "${_child_log}" "${_expected_text}" _match_index)
      if(_match_index EQUAL -1)
        message(FATAL_ERROR
          "Mode warning did not contain '${_expected_text}':\n${_child_log}")
      endif()
    endforeach()
  endif()
else()
  if(_child_result EQUAL 0)
    message(FATAL_ERROR
      "Expected ${TEST_CASE} to fail, but it succeeded")
  endif()
  if(DEFINED _expected_failure_text)
    set(_expected_failure_output "${_expected_failure_text}")
  else()
    set(_expected_failure_output
      "SHA256 mismatch"
      "${_mismatch_path}"
      "${_expected_sha}"
      "${_bad_sha}")
  endif()
  foreach(_expected_text IN LISTS _expected_failure_output)
    string(FIND "${_child_log}" "${_expected_text}" _match_index)
    if(_match_index EQUAL -1)
      message(FATAL_ERROR
        "Failure output did not contain '${_expected_text}':\n${_child_log}")
    endif()
  endforeach()
  if(_expect_cache_absent AND EXISTS "${_cache_path}")
    message(FATAL_ERROR
      "Failed download left an incomplete cache file: ${_cache_path}")
  endif()
endif()
