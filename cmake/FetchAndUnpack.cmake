# Helper utilities to resolve local/downloaded archives and unpack them.

# fetch_and_unpack_configure_dirs()
#   Ensures ARCHIVE_DIR and DOWNLOAD_CACHE_DIR are set (respecting user overrides) and exist on disk.
function(fetch_and_unpack_configure_dirs)
  if(UGS_ALLOW_UNVERIFIED_ARCHIVES)
    message(WARNING
      "UGS_ALLOW_UNVERIFIED_ARCHIVES=ON permits SHA256-mismatched upstream "
      "archives. This mode is outside standard support and is not suitable "
      "for CI or release builds.")
  endif()

  if(NOT DEFINED ARCHIVE_DIR OR ARCHIVE_DIR STREQUAL "")
    set(ARCHIVE_DIR "${CMAKE_SOURCE_DIR}/archives" CACHE PATH "Directory for user-provided source archives" FORCE)
  endif()
  file(MAKE_DIRECTORY "${ARCHIVE_DIR}")

  if(NOT DEFINED DOWNLOAD_CACHE_DIR OR DOWNLOAD_CACHE_DIR STREQUAL "")
    set(DOWNLOAD_CACHE_DIR "${CMAKE_SOURCE_DIR}/.cache/downloads" CACHE PATH "Directory for downloaded archives" FORCE)
  endif()
  file(MAKE_DIRECTORY "${DOWNLOAD_CACHE_DIR}")
endfunction()

# verify_input_file(FILE_PATH EXPECTED_SHA)
#   Verifies an upstream input before it is returned for use by the build.
function(verify_input_file FILE_PATH EXPECTED_SHA)
  file(SHA256 "${FILE_PATH}" _actual_sha)
  string(TOLOWER "${EXPECTED_SHA}" _expected_sha)
  if(NOT _actual_sha STREQUAL _expected_sha)
    string(CONCAT _mismatch_message
      "SHA256 mismatch for upstream archive.\n"
      "  Path: ${FILE_PATH}\n"
      "  Expected SHA256: ${_expected_sha}\n"
      "  Actual SHA256: ${_actual_sha}\n"
      "Replace the file with an archive matching the pinned SHA256 value, "
      "or review and update the pin as part of an upstream refresh.")
    if(UGS_ALLOW_UNVERIFIED_ARCHIVES)
      message(WARNING
        "${_mismatch_message}\n"
        "Proceeding because UGS_ALLOW_UNVERIFIED_ARCHIVES=ON. "
        "This mode is outside standard support and is not suitable for CI "
        "or release builds.")
    else()
      message(FATAL_ERROR "${_mismatch_message}")
    endif()
  endif()
endfunction()

# resolve_input_file(OUT_VAR URL SHA LOCAL_HINT)
#   Arguments: OUT_VAR, URL, SHA, LOCAL_HINT
#   Example:
#     resolve_input_file(DemoApp_SRC_TGZ
#       "${DemoApp_SRC_URL}"
#       "${DemoApp_SRC_SHA256}"
#       "${DemoApp_SRC_LOCAL}"
#     )
#     # where:
#     #   DemoApp_SRC_URL     = "https://example.com/demoapp/demoapp-src.tgz"
#     #   DemoApp_SRC_SHA256  = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
#     #   DemoApp_SRC_LOCAL   = "/opt/demoapp/demoapp-src.tgz"
function(resolve_input_file OUT_VAR URL SHA LOCAL_HINT)
  get_filename_component(_name "${URL}" NAME)
  set_property(GLOBAL APPEND PROPERTY FETCH_AND_UNPACK_CACHE_DIRS "${DOWNLOAD_CACHE_DIR}")
  set(_archive_path "${ARCHIVE_DIR}/${_name}")
  if(EXISTS "${LOCAL_HINT}")
    set(_selected_path "${LOCAL_HINT}")
  elseif(EXISTS "${_archive_path}")
    set(_selected_path "${_archive_path}")
  elseif(NET_FETCH)
    file(MAKE_DIRECTORY "${DOWNLOAD_CACHE_DIR}")
    set(_dest "${DOWNLOAD_CACHE_DIR}/${_name}")
    if(NOT EXISTS "${_dest}")
      message(STATUS "Downloading ${URL} -> ${_dest}")
      file(DOWNLOAD "${URL}" "${_dest}" SHOW_PROGRESS STATUS _download_status)
      list(GET _download_status 0 _download_code)
      list(GET _download_status 1 _download_message)
      if(NOT _download_code EQUAL 0)
        file(REMOVE "${_dest}")
        message(FATAL_ERROR
          "Failed to download upstream archive.\n"
          "  URL: ${URL}\n"
          "  Path: ${_dest}\n"
          "  Reason: ${_download_message}")
      endif()
    else()
      message(STATUS "Using cached download: ${_dest}")
    endif()
    set(_selected_path "${_dest}")
  else()
    message(FATAL_ERROR "Required file not found and NET_FETCH=OFF. Please place it at: ${LOCAL_HINT}")
  endif()
  verify_input_file("${_selected_path}" "${SHA}")
  set(${OUT_VAR} "${_selected_path}" PARENT_SCOPE)
endfunction()

# add_download_cleanup_target(TARGET_NAME)
#   Registers a target that removes build outputs and cached downloads.
function(add_download_cleanup_target TARGET_NAME)
  if(TARGET ${TARGET_NAME})
    return()
  endif()
  get_property(_dirs GLOBAL PROPERTY FETCH_AND_UNPACK_CACHE_DIRS)
  if(NOT _dirs)
    return()
  endif()
  list(REMOVE_DUPLICATES _dirs)
  add_custom_target(${TARGET_NAME}
    COMMAND ${CMAKE_COMMAND} -E rm -rf "${CMAKE_BINARY_DIR}/vendor" "${CMAKE_BINARY_DIR}/generated" ${_dirs}
    COMMENT "Remove build products and download cache(s): ${_dirs}")
endfunction()

# add_unpack_archive(STAMP_FILE DEST_DIR ARCHIVE_PATH COMMAND …
#                    [COMMENT …] [RESET_PATH …])
#   Arguments: STAMP_FILE, DEST_DIR, ARCHIVE_PATH, COMMENT, RESET_PATH, COMMAND
#   Example:
#     add_unpack_archive("${DemoApp_SRC_ROOT}.stamp" "${DemoApp_SRC_ROOT}" "${DemoApp_SRC_TGZ}"
#       COMMENT "Unpacking DemoApp sources"
#       COMMAND ${CMAKE_COMMAND} -E tar xzf
#     )
#     # where:
#     #   DemoApp_SRC_ROOT = "/tmp/demoapp-src"
#     #   DemoApp_SRC_TGZ  = "/opt/demoapp/demoapp-src.tgz"
function(add_unpack_archive STAMP_FILE DEST_DIR ARCHIVE_PATH)
  set(options)
  set(oneValueArgs COMMENT RESET_PATH)
  set(multiValueArgs COMMAND)
  cmake_parse_arguments(UNPACK "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  if(NOT UNPACK_COMMAND)
    message(FATAL_ERROR "add_unpack_archive requires COMMAND arguments (e.g. tar xzf).")
  endif()
  if(NOT UNPACK_COMMENT)
    set(UNPACK_COMMENT "Unpacking ${ARCHIVE_PATH}")
  endif()
  set(_reset_command)
  if(UNPACK_RESET_PATH)
    list(APPEND _reset_command
      COMMAND ${CMAKE_COMMAND} -E rm -rf "${UNPACK_RESET_PATH}")
  endif()
  add_custom_command(OUTPUT "${STAMP_FILE}"
    ${_reset_command}
    COMMAND ${CMAKE_COMMAND} -E make_directory "${DEST_DIR}"
    COMMAND ${CMAKE_COMMAND} -E chdir "${DEST_DIR}" ${UNPACK_COMMAND} "${ARCHIVE_PATH}"
    COMMAND ${CMAKE_COMMAND} -E touch "${STAMP_FILE}"
    DEPENDS "${ARCHIVE_PATH}"
    COMMENT "${UNPACK_COMMENT}"
    VERBATIM)
  set_property(GLOBAL APPEND PROPERTY FETCH_AND_UNPACK_STAMPS "${STAMP_FILE}")
endfunction()

# add_unpack_target(TARGET_NAME)
#   Aggregates all registered unpack stamp files into an explicit target.
function(add_unpack_target TARGET_NAME)
  get_property(_stamps GLOBAL PROPERTY FETCH_AND_UNPACK_STAMPS)
  if(NOT _stamps)
    message(WARNING "add_unpack_target called but no archives were registered.")
    return()
  endif()
  list(REMOVE_DUPLICATES _stamps)
  add_custom_target(${TARGET_NAME}
    DEPENDS ${_stamps})
endfunction()
