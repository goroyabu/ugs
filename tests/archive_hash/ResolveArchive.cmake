foreach(_required_var
    FETCH_MODULE
    ARCHIVE_DIR
    DOWNLOAD_CACHE_DIR
    TEST_URL
    EXPECTED_SHA
    LOCAL_HINT
    NET_FETCH
    ALLOW_UNVERIFIED
    RESULT_FILE)
  if(NOT DEFINED ${_required_var})
    message(FATAL_ERROR "Required test variable is missing: ${_required_var}")
  endif()
endforeach()

set(UGS_ALLOW_UNVERIFIED_ARCHIVES "${ALLOW_UNVERIFIED}")

include("${FETCH_MODULE}")
fetch_and_unpack_configure_dirs()
resolve_input_file(_resolved "${TEST_URL}" "${EXPECTED_SHA}" "${LOCAL_HINT}")
file(WRITE "${RESULT_FILE}" "${_resolved}")
