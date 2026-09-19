foreach(_required_var PROJECT_SOURCE_DIR ARCHIVE_DIR TEST_ROOT)
  if(NOT DEFINED ${_required_var})
    message(FATAL_ERROR "Required test variable is missing: ${_required_var}")
  endif()
endforeach()

file(REMOVE_RECURSE "${TEST_ROOT}")
execute_process(
  COMMAND "${CMAKE_COMMAND}"
    -S "${PROJECT_SOURCE_DIR}"
    -B "${TEST_ROOT}"
    -DNET_FETCH=OFF
    "-DARCHIVE_DIR=${ARCHIVE_DIR}"
    "-DDOWNLOAD_CACHE_DIR=${TEST_ROOT}/cache"
    -DUGS_SRC_SHA256=legacy-user-override
    -DBUILD_TESTING=OFF
    -DUGS_ENABLE_GUI_SMOKE=OFF
  RESULT_VARIABLE _configure_result
  OUTPUT_VARIABLE _configure_stdout
  ERROR_VARIABLE _configure_stderr)
if(NOT _configure_result EQUAL 0)
  message(FATAL_ERROR
    "Migration configure failed:\n${_configure_stdout}${_configure_stderr}")
endif()

file(STRINGS "${TEST_ROOT}/CMakeCache.txt" _legacy_cache_entries
  REGEX "^UGS_SRC_SHA256:")
if(_legacy_cache_entries)
  message(FATAL_ERROR
    "Legacy UGS_SRC_SHA256 cache entry was not removed: ${_legacy_cache_entries}")
endif()
