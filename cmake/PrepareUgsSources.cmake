# Prepare and patch UGS sources into a generated tree.
#
# Expected variables (passed via -D):
#   UGS_SOURCE_TREE  - path to upstream source tree (e.g. vendor/ugs/src.2.10e)
#   UGS_GEN_DIR      - output directory for generated sources/assets

if(NOT DEFINED UGS_SOURCE_TREE OR UGS_SOURCE_TREE STREQUAL "")
  message(FATAL_ERROR "UGS_SOURCE_TREE is not set for PrepareUgsSources.cmake")
endif()

if(NOT DEFINED UGS_GEN_DIR OR UGS_GEN_DIR STREQUAL "")
  message(FATAL_ERROR "UGS_GEN_DIR is not set for PrepareUgsSources.cmake")
endif()

if(NOT DEFINED UGS_SOURCE_MANIFEST OR
   NOT EXISTS "${UGS_SOURCE_MANIFEST}")
  message(FATAL_ERROR
    "UGS_SOURCE_MANIFEST is missing: ${UGS_SOURCE_MANIFEST}")
endif()
include("${UGS_SOURCE_MANIFEST}")

if(NOT IS_DIRECTORY "${UGS_SOURCE_TREE}")
  message(FATAL_ERROR "UGS_SOURCE_TREE does not exist or is not a directory: ${UGS_SOURCE_TREE}")
endif()

file(MAKE_DIRECTORY "${UGS_GEN_DIR}")
set_property(GLOBAL PROPERTY UGS_FOUND_SYSTEM_TOKEN FALSE)
set_property(GLOBAL PROPERTY UGS_FOUND_CHARACTER_PATCH FALSE)

function(_write_if_different path content)
  if(EXISTS "${path}")
    file(READ "${path}" current_content)
    if(current_content STREQUAL content)
      return()
    endif()
  endif()
  get_filename_component(output_dir "${path}" DIRECTORY)
  file(MAKE_DIRECTORY "${output_dir}")
  set(temporary_path "${path}.tmp")
  file(WRITE "${temporary_path}" "${content}")
  file(RENAME "${temporary_path}" "${path}")
endfunction()

function(_replace_required content_var input description old_text new_text)
  set(content "${${content_var}}")
  string(FIND "${content}" "${old_text}" match_index)
  if(match_index EQUAL -1)
    message(FATAL_ERROR
      "Required UGS patch anchor not found (${description}): ${input}")
  endif()
  string(REPLACE "${old_text}" "${new_text}" content "${content}")
  set(${content_var} "${content}" PARENT_SCOPE)
endfunction()

function(_append_after_final_end_required content_var input description suffix)
  set(content "${${content_var}}")
  if(NOT content MATCHES "      END[\r\n]*$")
    message(FATAL_ERROR
      "Required UGS patch anchor not found (${description}): ${input}")
  endif()
  string(REGEX REPLACE "      END([\r\n]*)$" "      END\\1${suffix}"
    content "${content}")
  set(${content_var} "${content}" PARENT_SCOPE)
endfunction()

function(_copy_and_patch input abs_out)
  file(READ "${input}" _content)
  string(FIND "${_content}" "UGSYSTEM:" system_token_index)
  if(NOT system_token_index EQUAL -1)
    set_property(GLOBAL PROPERTY UGS_FOUND_SYSTEM_TOKEN TRUE)
  endif()
  if(_content MATCHES "INTEGER\\*2[ ]+CHC")
    set_property(GLOBAL PROPERTY UGS_FOUND_CHARACTER_PATCH TRUE)
  endif()
  string(REPLACE "UGSYSTEM:" "UGSYSTEM_" _content "${_content}")
  string(REGEX REPLACE "INTEGER\\*2[ ]+CHC" "CHARACTER*2     CHC" _content "${_content}")
  get_filename_component(_name "${input}" NAME)
  if(_name STREQUAL "uge002.F")
    _replace_required(
      _content "${input}" "little-endian detection"
      "#if  ( defined(__LINUX_AOUT) || defined(__LINUX_ELF) || defined(__OSF1) ||\\\n       defined(__Darwin) )"
      "#if defined(__LINUX_AOUT) || defined(__LINUX_ELF) || defined(__OSF1) || defined(__Darwin) || defined(__LITTLE_ENDIAN__) || (defined(__BYTE_ORDER__) && defined(__ORDER_LITTLE_ENDIAN__) && (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__))")
  endif()
  if(_name STREQUAL "aux.c")
    if(NOT _content MATCHES "#include <string.h>")
      set(_content "#include <string.h>\n${_content}")
    endif()
  elseif(_name STREQUAL "rotated.c")
    if(NOT _content MATCHES "#include <stdlib.h>")
      set(_content "#include <stdlib.h>\n${_content}")
    endif()
    if(NOT _content MATCHES "#include <string.h>")
      string(REPLACE "#include <stdlib.h>\n" "#include <stdlib.h>\n#include <string.h>\n" _content "${_content}")
    endif()
  elseif(_name STREQUAL "postscr.f")
    _replace_required(
      _content "${input}" "PostScript filename persistence"
      "      CHARACTER*256 EXNM\n"
      "      CHARACTER*256 EXNM\n      SAVE          EXNM\n")
  elseif(_name STREQUAL "ugfont.f")
    _replace_required(
      _content "${input}" "font block-data link calls"
      "C  SCAN THE OPTIONS LIST.\n      EXCG=0"
      "C  FORCE THE FONT BLOCK DATA OBJECTS INTO STATIC-LIBRARY LINKS.\n      CALL UGSLNKS\n      CALL UGSLNKD\nC\nC  SCAN THE OPTIONS LIST.\n      EXCG=0")
  elseif(_name STREQUAL "ugsimp.f")
    _append_after_final_end_required(
      _content "${input}" "SIMPLEX font link anchor"
      "\n      SUBROUTINE UGSLNKS\n      RETURN\n      END\n")
  elseif(_name STREQUAL "ugdupl.f")
    _append_after_final_end_required(
      _content "${input}" "DUPLEX font link anchor"
      "\n      SUBROUTINE UGSLNKD\n      RETURN\n      END\n")
  endif()
  _write_if_different("${abs_out}" "${_content}")
endfunction()

function(_copy_if_exists relpath)
  set(in "${UGS_SOURCE_TREE}/${relpath}")
  set(out "${UGS_GEN_DIR}/${relpath}")
  if(EXISTS "${in}")
    _copy_and_patch("${in}" "${out}")
  else()
    message(FATAL_ERROR "Required upstream source is missing: ${relpath}")
  endif()
endfunction()

function(_generate_xwtest_source)
  set(in "${UGS_SOURCE_TREE}/drivers/xwindowc.c")
  set(out "${UGS_GEN_DIR}/drivers/xwindowc_selftest.c")
  if(NOT EXISTS "${in}")
    message(FATAL_ERROR
      "Required upstream source is missing: drivers/xwindowc.c")
  endif()

  file(READ "${in}" _content)
  string(FIND "${_content}" "UGSYSTEM:" system_token_index)
  if(NOT system_token_index EQUAL -1)
    set_property(GLOBAL PROPERTY UGS_FOUND_SYSTEM_TOKEN TRUE)
  endif()
  if(_content MATCHES "INTEGER\\*2[ ]+CHC")
    set_property(GLOBAL PROPERTY UGS_FOUND_CHARACTER_PATCH TRUE)
  endif()
  string(REPLACE "UGSYSTEM:" "UGSYSTEM_" _content "${_content}")
  string(REGEX REPLACE "INTEGER\\*2[ ]+CHC" "CHARACTER*2     CHC" _content "${_content}")
  _replace_required(
    _content "${in}" "X11 self-test entry point"
    "main ()" "void main ()")

  _write_if_different("${out}" "${_content}")
endfunction()

function(_copy_ugsystem_files base_subdir file_list_var)
  foreach(oldfile IN LISTS ${file_list_var})
    set(src "${UGS_SOURCE_TREE}/${base_subdir}/UGSYSTEM:${oldfile}")
    if(NOT EXISTS "${src}")
      message(FATAL_ERROR "Required upstream UGSYSTEM file is missing: ${src}")
    endif()
    set(dst "${UGS_GEN_DIR}/${base_subdir}/UGSYSTEM_${oldfile}")
    _copy_and_patch("${src}" "${dst}")
  endforeach()
endfunction()

function(_copy_asset_if_exists relpath)
  set(in "${UGS_SOURCE_TREE}/${relpath}")
  set(out "${UGS_GEN_DIR}/${relpath}")
  if(EXISTS "${in}")
    get_filename_component(_outdir "${out}" DIRECTORY)
    file(MAKE_DIRECTORY "${_outdir}")
    configure_file("${in}" "${out}" COPYONLY)
  else()
    message(FATAL_ERROR "Required upstream asset is missing: ${relpath}")
  endif()
endfunction()

foreach(src_name IN LISTS UGS_SOURCE_NAMES)
  _copy_if_exists(${src_name})
endforeach()

_copy_ugsystem_files("" UGS_SYSTEM_ROOT_FILES)
_copy_ugsystem_files("drivers" UGS_SYSTEM_DRIVER_FILES)
_generate_xwtest_source()

_copy_asset_if_exists(drivers/cursor1.bmp)
_copy_asset_if_exists(drivers/cursor2.bmp)
_copy_asset_if_exists(drivers/icon.bmp)

get_property(found_system_token GLOBAL PROPERTY UGS_FOUND_SYSTEM_TOKEN)
if(NOT found_system_token)
  message(FATAL_ERROR
    "Required UGS patch anchor not found (UGSYSTEM token normalization)")
endif()
get_property(found_character_patch GLOBAL PROPERTY UGS_FOUND_CHARACTER_PATCH)
if(NOT found_character_patch)
  message(FATAL_ERROR
    "Required UGS patch anchor not found (CHARACTER*2 declaration repair)")
endif()

set(_rot_in  "${UGS_SOURCE_TREE}/drivers/rotated.h")
set(_rot_out "${UGS_GEN_DIR}/drivers/rotated.h")
if(NOT EXISTS "${_rot_out}")
  if(EXISTS "${_rot_in}")
    _copy_if_exists(drivers/rotated.h)
  else()
    file(MAKE_DIRECTORY "${UGS_GEN_DIR}/drivers")
    _write_if_different("${_rot_out}" "/* Auto-generated fallback: rotated.h */\n#ifndef UGS_ROTATED_H\n#define UGS_ROTATED_H\n#endif\n")
  endif()
endif()

set(_def_in  "${UGS_SOURCE_TREE}/drivers/defaults.h")
set(_def_out "${UGS_GEN_DIR}/drivers/defaults.h")
if(NOT EXISTS "${_def_out}")
  if(EXISTS "${_def_in}")
    _copy_if_exists(drivers/defaults.h)
  else()
    file(MAKE_DIRECTORY "${UGS_GEN_DIR}/drivers")
    _write_if_different("${_def_out}" "/* Auto-generated fallback: defaults.h */\n#ifndef UGS_DEFAULTS_H\n#define UGS_DEFAULTS_H\n#endif\n")
  endif()
endif()
