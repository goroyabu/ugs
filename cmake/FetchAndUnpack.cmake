# Helper utilities to resolve local/downloaded archives and unpack them.

# fetch_and_unpack_configure_dirs()
#   Ensures ARCHIVE_DIR and DOWNLOAD_CACHE_DIR are set (respecting user overrides) and exist on disk.
function(fetch_and_unpack_configure_dirs)
  if(NOT DEFINED ARCHIVE_DIR OR ARCHIVE_DIR STREQUAL "")
    set(ARCHIVE_DIR "${CMAKE_SOURCE_DIR}/archives" CACHE PATH "Directory for user-provided source archives" FORCE)
  endif()
  file(MAKE_DIRECTORY "${ARCHIVE_DIR}")

  if(NOT DEFINED DOWNLOAD_CACHE_DIR OR DOWNLOAD_CACHE_DIR STREQUAL "")
    set(DOWNLOAD_CACHE_DIR "${CMAKE_SOURCE_DIR}/.cache/downloads" CACHE PATH "Directory for downloaded archives" FORCE)
  endif()
  file(MAKE_DIRECTORY "${DOWNLOAD_CACHE_DIR}")
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
  if(EXISTS "${LOCAL_HINT}")
    set(${OUT_VAR} "${LOCAL_HINT}" PARENT_SCOPE)
    return()
  endif()
  set(_archive_path "${ARCHIVE_DIR}/${_name}")
  if(EXISTS "${_archive_path}")
    set(${OUT_VAR} "${_archive_path}" PARENT_SCOPE)
    return()
  endif()
  if(NET_FETCH)
    file(MAKE_DIRECTORY "${DOWNLOAD_CACHE_DIR}")
    set(_dest "${DOWNLOAD_CACHE_DIR}/${_name}")
    if(NOT EXISTS "${_dest}")
      message(STATUS "Downloading ${URL} -> ${_dest}")
      file(DOWNLOAD "${URL}" "${_dest}" SHOW_PROGRESS EXPECTED_HASH "SHA256=${SHA}")
    else()
      message(STATUS "Using cached download: ${_dest}")
    endif()
    set(${OUT_VAR} "${_dest}" PARENT_SCOPE)
  else()
    message(FATAL_ERROR "Required file not found and NET_FETCH=OFF. Please place it at: ${LOCAL_HINT}")
  endif()
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

# add_unpack_archive(STAMP_FILE DEST_DIR ARCHIVE_PATH COMMAND … [COMMENT …])
#   Arguments: STAMP_FILE, DEST_DIR, ARCHIVE_PATH, COMMENT, COMMAND
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
  set(oneValueArgs COMMENT)
  set(multiValueArgs COMMAND)
  cmake_parse_arguments(UNPACK "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  if(NOT UNPACK_COMMAND)
    message(FATAL_ERROR "add_unpack_archive requires COMMAND arguments (e.g. tar xzf).")
  endif()
  if(NOT UNPACK_COMMENT)
    set(UNPACK_COMMENT "Unpacking ${ARCHIVE_PATH}")
  endif()
  add_custom_command(OUTPUT "${STAMP_FILE}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${DEST_DIR}"
    COMMAND ${CMAKE_COMMAND} -E chdir "${DEST_DIR}" ${UNPACK_COMMAND} "${ARCHIVE_PATH}"
    COMMAND ${CMAKE_COMMAND} -E touch "${STAMP_FILE}"
    DEPENDS "${ARCHIVE_PATH}"
    COMMENT "${UNPACK_COMMENT}"
    VERBATIM)
  set_property(GLOBAL APPEND PROPERTY FETCH_AND_UNPACK_STAMPS "${STAMP_FILE}")
endfunction()

# add_unpack_target(TARGET_NAME)
#   Aggregates all registered unpack stamp files into a single ALL target.
function(add_unpack_target TARGET_NAME)
  get_property(_stamps GLOBAL PROPERTY FETCH_AND_UNPACK_STAMPS)
  if(NOT _stamps)
    message(WARNING "add_unpack_target called but no archives were registered.")
    return()
  endif()
  list(REMOVE_DUPLICATES _stamps)
  add_custom_target(${TARGET_NAME} ALL
    DEPENDS ${_stamps})
endfunction()
