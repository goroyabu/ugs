cmake_minimum_required(VERSION 3.15)

if(NOT DEFINED PROJECT_SOURCE_DIR OR PROJECT_SOURCE_DIR STREQUAL "")
  message(FATAL_ERROR "PROJECT_SOURCE_DIR is required")
endif()

set(_ci_workflow "${PROJECT_SOURCE_DIR}/.github/workflows/ci.yml")
set(_gui_workflow "${PROJECT_SOURCE_DIR}/.github/workflows/gui-smoke.yml")

foreach(_workflow IN ITEMS "${_ci_workflow}" "${_gui_workflow}")
  if(NOT EXISTS "${_workflow}")
    message(FATAL_ERROR "Missing workflow: ${_workflow}")
  endif()
endforeach()

file(READ "${_ci_workflow}" _ci)
file(READ "${_gui_workflow}" _gui)

function(require_workflow_text content description pattern)
  if(NOT "${content}" MATCHES "${pattern}")
    message(FATAL_ERROR "Missing ${description}")
  endif()
endfunction()

foreach(_content IN ITEMS _ci _gui)
  require_workflow_text("${${_content}}" "read-only contents permission"
    "permissions:[\r\n]+  contents: read")
  require_workflow_text("${${_content}}" "concurrency group"
    "concurrency:[\r\n]+  group:")
  require_workflow_text("${${_content}}" "pull-request cancellation policy"
    "cancel-in-progress:.*pull_request")
  require_workflow_text("${${_content}}" "job timeout"
    "timeout-minutes: 30")
  require_workflow_text("${${_content}}" "SHA-pinned checkout action"
    "actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd")
endforeach()

require_workflow_text("${_gui}" "SHA-pinned artifact action"
  "actions/upload-artifact@bbbca2ddaa5d8feaa63e36b76fdaad77386f024f")

require_workflow_text("${_ci}" "display-independent CTest selection"
  "ctest --test-dir build -LE x11")
require_workflow_text("${_ci}" "X11 CTest selection"
  "ctest --test-dir build -L x11")
require_workflow_text("${_ci}" "offline configuration"
  "-DNET_FETCH=OFF")
require_workflow_text("${_ci}" "minimum CMake 3.15.7 verification"
  "3\\.15\\.7")
