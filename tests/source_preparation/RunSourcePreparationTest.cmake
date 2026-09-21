foreach(required_variable IN ITEMS
    PROJECT_SOURCE_DIR TEST_ROOT TEST_GENERATOR TEST_ARCHIVE)
  if(NOT DEFINED "${required_variable}" OR "${${required_variable}}" STREQUAL "")
    message(FATAL_ERROR "${required_variable} is required")
  endif()
endforeach()

function(run_checked description)
  execute_process(
    COMMAND ${ARGN}
    RESULT_VARIABLE result
    OUTPUT_VARIABLE stdout
    ERROR_VARIABLE stderr)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR
      "${description} failed (${result})\n"
      "stdout:\n${stdout}\n"
      "stderr:\n${stderr}")
  endif()
endfunction()

function(assert_exists path)
  if(NOT EXISTS "${path}")
    message(FATAL_ERROR "Expected path does not exist: ${path}")
  endif()
endfunction()

function(read_state path hash_var timestamp_var)
  assert_exists("${path}")
  file(SHA256 "${path}" hash)
  file(TIMESTAMP "${path}" timestamp "%s")
  set(${hash_var} "${hash}" PARENT_SCOPE)
  set(${timestamp_var} "${timestamp}" PARENT_SCOPE)
endfunction()

function(assert_equal actual expected description)
  if(NOT "${actual}" STREQUAL "${expected}")
    message(FATAL_ERROR
      "${description}\nExpected: ${expected}\nActual:   ${actual}")
  endif()
endfunction()

function(assert_not_equal actual expected description)
  if("${actual}" STREQUAL "${expected}")
    message(FATAL_ERROR "${description}\nBoth values: ${actual}")
  endif()
endfunction()

function(assert_patch_anchor_rejected case_name relative_path anchor)
  set(case_root "${TEST_ROOT}/strict-${case_name}")
  file(REMOVE_RECURSE "${case_root}")
  file(MAKE_DIRECTORY "${case_root}/upstream")
  file(COPY "${build_dir}/vendor/ugs/src.2.10e/"
    DESTINATION "${case_root}/upstream")
  set(input "${case_root}/upstream/${relative_path}")
  file(READ "${input}" content)
  string(REPLACE "${anchor}" "REMOVED_PATCH_ANCHOR" changed_content "${content}")
  if(changed_content STREQUAL content)
    message(FATAL_ERROR
      "Strict-anchor test could not find ${anchor} in ${relative_path}")
  endif()
  file(WRITE "${input}" "${changed_content}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}"
      "-DUGS_SOURCE_TREE=${case_root}/upstream"
      "-DUGS_GEN_DIR=${case_root}/generated"
      "-DUGS_SOURCE_MANIFEST=${source_dir}/cmake/UgsSourceManifest.cmake"
      -P "${source_dir}/cmake/PrepareUgsSources.cmake"
    RESULT_VARIABLE result
    OUTPUT_VARIABLE stdout
    ERROR_VARIABLE stderr)
  if(result EQUAL 0)
    message(FATAL_ERROR
      "Preparation accepted a missing required patch anchor: ${relative_path}")
  endif()
  string(CONCAT combined_output "${stdout}" "${stderr}")
  if(NOT combined_output MATCHES "Required UGS patch anchor not found")
    message(FATAL_ERROR
      "Preparation failed for the wrong reason (${relative_path}):\n"
      "${combined_output}")
  endif()
endfunction()

function(assert_global_patch_anchor_rejected case_name pattern replacement)
  set(case_root "${TEST_ROOT}/strict-${case_name}")
  file(REMOVE_RECURSE "${case_root}")
  file(MAKE_DIRECTORY "${case_root}/upstream")
  file(COPY "${build_dir}/vendor/ugs/src.2.10e/"
    DESTINATION "${case_root}/upstream")
  file(GLOB_RECURSE upstream_files LIST_DIRECTORIES FALSE
    "${case_root}/upstream/*.c"
    "${case_root}/upstream/*.f"
    "${case_root}/upstream/*.F"
    "${case_root}/upstream/*.for"
    "${case_root}/upstream/*.FOR"
    "${case_root}/upstream/*.org")
  set(replacement_count 0)
  foreach(input IN LISTS upstream_files)
    file(READ "${input}" content)
    string(REGEX REPLACE "${pattern}" "${replacement}" changed_content "${content}")
    if(NOT changed_content STREQUAL content)
      math(EXPR replacement_count "${replacement_count} + 1")
      file(WRITE "${input}" "${changed_content}")
    endif()
  endforeach()
  if(replacement_count EQUAL 0)
    message(FATAL_ERROR
      "Global strict-anchor test did not alter any inputs: ${case_name}")
  endif()
  execute_process(
    COMMAND "${CMAKE_COMMAND}"
      "-DUGS_SOURCE_TREE=${case_root}/upstream"
      "-DUGS_GEN_DIR=${case_root}/generated"
      "-DUGS_SOURCE_MANIFEST=${source_dir}/cmake/UgsSourceManifest.cmake"
      -P "${source_dir}/cmake/PrepareUgsSources.cmake"
    RESULT_VARIABLE result
    OUTPUT_VARIABLE stdout
    ERROR_VARIABLE stderr)
  if(result EQUAL 0)
    message(FATAL_ERROR
      "Preparation accepted a missing global patch anchor: ${case_name}")
  endif()
  string(CONCAT combined_output "${stdout}" "${stderr}")
  if(NOT combined_output MATCHES "Required UGS patch anchor not found")
    message(FATAL_ERROR
      "Preparation failed for the wrong reason (${case_name}):\n"
      "${combined_output}")
  endif()
endfunction()

file(REMOVE_RECURSE "${TEST_ROOT}")
file(MAKE_DIRECTORY "${TEST_ROOT}/source" "${TEST_ROOT}/archives")
file(COPY "${PROJECT_SOURCE_DIR}/"
  DESTINATION "${TEST_ROOT}/source"
  PATTERN ".git" EXCLUDE
  PATTERN ".cache" EXCLUDE
  PATTERN "archives" EXCLUDE
  PATTERN "build" EXCLUDE
  PATTERN "build-*" EXCLUDE)
configure_file("${TEST_ARCHIVE}" "${TEST_ROOT}/archives/ugs.tar.gz" COPYONLY)

set(source_dir "${TEST_ROOT}/source")
set(build_dir "${TEST_ROOT}/build")
set(configure_command
  "${CMAKE_COMMAND}" -S "${source_dir}" -B "${build_dir}"
  -G "${TEST_GENERATOR}"
  "-DARCHIVE_DIR=${TEST_ROOT}/archives"
  "-DDOWNLOAD_CACHE_DIR=${TEST_ROOT}/download-cache"
  -DNET_FETCH=OFF
  -DBUILD_TESTING=OFF
  -DUGS_ENABLE_GUI_SMOKE=OFF)
if(DEFINED TEST_MAKE_PROGRAM AND NOT TEST_MAKE_PROGRAM STREQUAL "")
  list(APPEND configure_command "-DCMAKE_MAKE_PROGRAM=${TEST_MAKE_PROGRAM}")
endif()

run_checked("Nested configure" ${configure_command})
run_checked("Initial nested build"
  "${CMAKE_COMMAND}" --build "${build_dir}" --parallel)

set(aux "${build_dir}/generated/aux.c")
set(postscr "${build_dir}/generated/drivers/postscr.f")
set(ugfont "${build_dir}/generated/ugfont.f")
set(ugsimp "${build_dir}/generated/ugsimp.f")
set(ugdupl "${build_dir}/generated/ugdupl.f")
set(header "${build_dir}/generated/drivers/rotated.h")
set(asset "${build_dir}/generated/drivers/cursor1.bmp")
set(library "${build_dir}/libugs.a")
foreach(path IN ITEMS
    "${aux}" "${postscr}" "${ugfont}" "${ugsimp}" "${ugdupl}"
    "${header}" "${asset}" "${library}")
  assert_exists("${path}")
endforeach()

assert_patch_anchor_rejected(
  endian uge002.F
  "#if  ( defined(__LINUX_AOUT) || defined(__LINUX_ELF) || defined(__OSF1) ||\\\n       defined(__Darwin) )")
assert_patch_anchor_rejected(
  postscript drivers/postscr.f "      CHARACTER*256 EXNM\n")
assert_patch_anchor_rejected(
  font-link-calls ugfont.f "C  SCAN THE OPTIONS LIST.\n      EXCG=0")
assert_patch_anchor_rejected(
  simplex-link-anchor ugsimp.f "      END\n")
assert_patch_anchor_rejected(
  duplex-link-anchor ugdupl.f "      END\n")
assert_patch_anchor_rejected(
  x11-selftest drivers/xwindowc.c "main ()")
assert_global_patch_anchor_rejected(
  ugsystem-token "UGSYSTEM:" "UGSYSTEM_REMOVED")
assert_global_patch_anchor_rejected(
  character-declaration "INTEGER\\*2[ ]+CHC" "INTEGER_REMOVED CHC")

read_state("${aux}" initial_aux_hash initial_aux_timestamp)
read_state("${postscr}" initial_postscr_hash initial_postscr_timestamp)
read_state("${library}" initial_library_hash initial_library_timestamp)

execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep 1)
run_checked("No-op nested rebuild"
  "${CMAKE_COMMAND}" --build "${build_dir}" --parallel)
read_state("${aux}" noop_aux_hash noop_aux_timestamp)
read_state("${postscr}" noop_postscr_hash noop_postscr_timestamp)
read_state("${library}" noop_library_hash noop_library_timestamp)
assert_equal("${noop_aux_hash}" "${initial_aux_hash}"
  "No-op rebuild changed aux.c content")
assert_equal("${noop_aux_timestamp}" "${initial_aux_timestamp}"
  "No-op rebuild changed aux.c timestamp")
assert_equal("${noop_postscr_hash}" "${initial_postscr_hash}"
  "No-op rebuild changed postscr.f content")
assert_equal("${noop_postscr_timestamp}" "${initial_postscr_timestamp}"
  "No-op rebuild changed postscr.f timestamp")
assert_equal("${noop_library_hash}" "${initial_library_hash}"
  "No-op rebuild changed library content")
assert_equal("${noop_library_timestamp}" "${initial_library_timestamp}"
  "No-op rebuild changed library timestamp")

file(REMOVE "${aux}")
run_checked("Rebuild after deleting a prepared source"
  "${CMAKE_COMMAND}" --build "${build_dir}" --parallel)
read_state("${aux}" restored_aux_hash restored_aux_timestamp)
assert_equal("${restored_aux_hash}" "${initial_aux_hash}"
  "Restored aux.c differs from its initial content")

set(prepare_script "${source_dir}/cmake/PrepareUgsSources.cmake")
file(READ "${prepare_script}" prepare_content)
set(original_patch "SAVE          EXNM")
set(changed_patch "SAVE          EXNM ! incremental-test")
string(REPLACE "${original_patch}" "${changed_patch}"
  changed_prepare_content "${prepare_content}")
if(changed_prepare_content STREQUAL prepare_content)
  message(FATAL_ERROR "Could not locate the PostScript SAVE patch in copied source")
endif()
execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep 1)
file(WRITE "${prepare_script}" "${changed_prepare_content}")
run_checked("Rebuild after changing source preparation logic"
  "${CMAKE_COMMAND}" --build "${build_dir}" --parallel)
read_state("${aux}" changed_aux_hash changed_aux_timestamp)
read_state("${postscr}" changed_postscr_hash changed_postscr_timestamp)
read_state("${library}" changed_library_hash changed_library_timestamp)
assert_equal("${changed_aux_hash}" "${initial_aux_hash}"
  "Unrelated aux.c content changed after a PostScript-only patch change")
assert_equal("${changed_aux_timestamp}" "${restored_aux_timestamp}"
  "Unrelated aux.c was rewritten after a PostScript-only patch change")
assert_not_equal("${changed_postscr_hash}" "${initial_postscr_hash}"
  "postscr.f did not change after changing its preparation rule")
assert_not_equal("${changed_library_timestamp}" "${initial_library_timestamp}"
  "Library was not rebuilt after a prepared source changed")

run_checked("Nested clean"
  "${CMAKE_COMMAND}" --build "${build_dir}" --target clean)
run_checked("Rebuild after clean"
  "${CMAKE_COMMAND}" --build "${build_dir}" --parallel)
foreach(path IN ITEMS
    "${aux}" "${postscr}" "${ugfont}" "${ugsimp}" "${ugdupl}"
    "${header}" "${asset}" "${library}")
  assert_exists("${path}")
endforeach()

run_checked("Nested clean_downloads"
  "${CMAKE_COMMAND}" --build "${build_dir}" --target clean_downloads)
assert_exists("${TEST_ROOT}/archives/ugs.tar.gz")
run_checked("Rebuild after clean_downloads"
  "${CMAKE_COMMAND}" --build "${build_dir}" --parallel)
foreach(path IN ITEMS
    "${aux}" "${postscr}" "${ugfont}" "${ugsimp}" "${ugdupl}"
    "${header}" "${asset}" "${library}")
  assert_exists("${path}")
endforeach()
