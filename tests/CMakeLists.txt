set(XWTEST_SMOKE_SUPPORT FALSE)

set(_wrap_src "${CMAKE_CURRENT_SOURCE_DIR}/cases/01_smoke/xwindowc_smoke.c")
if(NOT EXISTS "${_wrap_src}")
  message(FATAL_ERROR "Missing xwtest smoke source: ${_wrap_src}")
endif()

set(_xwtest_generated
  ${GEN_DIR}/drivers/cursor1.bmp
  ${GEN_DIR}/drivers/cursor2.bmp
  ${GEN_DIR}/drivers/icon.bmp
  ${GEN_DIR}/drivers/rotated.c
)
set_source_files_properties(${_xwtest_generated}
  PROPERTIES GENERATED TRUE
)

add_executable(xwtest_smoke
  "${_wrap_src}"
  ${GEN_DIR}/drivers/cursor1.bmp
  ${GEN_DIR}/drivers/cursor2.bmp
  ${GEN_DIR}/drivers/icon.bmp
  ${GEN_DIR}/drivers/rotated.c
)
add_dependencies(xwtest_smoke prepare_sources)
target_compile_definitions(xwtest_smoke PRIVATE SELFTEST)
target_include_directories(xwtest_smoke PRIVATE ${GEN_DIR}/drivers ${X11_INCLUDE_DIR})
target_link_libraries(xwtest_smoke PRIVATE ${X11_LIBRARIES} ${X11_Xaw_LIB} ${X11_Xmu_LIB} ${X11_Xt_LIB})
if(UNIX AND NOT APPLE)
  target_link_libraries(xwtest_smoke PRIVATE m)
endif()

set(XWTEST_SMOKE_SUPPORT TRUE)

set(_xwtest_display "$ENV{DISPLAY}")
if(DEFINED XWTEST_SMOKE_DISPLAY AND NOT XWTEST_SMOKE_DISPLAY STREQUAL "")
  set(_xwtest_display "${XWTEST_SMOKE_DISPLAY}")
endif()
if(NOT _xwtest_display)
  set(_xwtest_display ":0")
endif()

if(XWTEST_SMOKE_SUPPORT)
  set(_xwtest_smoke_cmd ${CMAKE_COMMAND} -E env LC_ALL=C TZ=UTC)
  if(_xwtest_display)
    list(APPEND _xwtest_smoke_cmd DISPLAY=${_xwtest_display})
  endif()
  list(APPEND _xwtest_smoke_cmd $<TARGET_FILE:xwtest_smoke>)

  file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/cases/01_smoke/expected.txt" _expected_regex REGEX ".+")
  if(NOT _expected_regex)
    set(_expected_regex "\[xwtest-smoke] window is viewable")
  endif()

  add_test(NAME 01_smoke
           COMMAND ${_xwtest_smoke_cmd})
  set_tests_properties(01_smoke
    PROPERTIES
      LABELS "smoke;x11"
      PASS_REGULAR_EXPRESSION "${_expected_regex}")
else()
  message(STATUS "xwtest_smoke target not available; skipping GUI smoke test registration.")
endif()

set(_tryxw_src "${CMAKE_CURRENT_SOURCE_DIR}/cases/02_tryxw/tryxw.f")
if(EXISTS "${_tryxw_src}")
  add_executable(tryxw_smoke "${_tryxw_src}")
  target_link_libraries(tryxw_smoke
    PRIVATE
      ugs
      ${X11_LIBRARIES} ${X11_Xaw_LIB} ${X11_Xmu_LIB} ${X11_Xt_LIB}
  )
  target_include_directories(tryxw_smoke PRIVATE ${GEN_DIR})

  set(_tryxw_display "$ENV{DISPLAY}")
  if(DEFINED XWTEST_SMOKE_DISPLAY AND NOT XWTEST_SMOKE_DISPLAY STREQUAL "")
    set(_tryxw_display "${XWTEST_SMOKE_DISPLAY}")
  endif()
  if(NOT _tryxw_display)
    set(_tryxw_display ":0")
  endif()

  set(_tryxw_cmd ${CMAKE_COMMAND} -E env LC_ALL=C TZ=UTC)
  if(_tryxw_display)
    list(APPEND _tryxw_cmd DISPLAY=${_tryxw_display})
  endif()
  list(APPEND _tryxw_cmd $<TARGET_FILE:tryxw_smoke>)

  add_test(NAME 02_tryxw
           COMMAND ${_tryxw_cmd})
  set_tests_properties(02_tryxw
    PROPERTIES
      LABELS "smoke;x11;fortran")
else()
  message(STATUS "tryxw_smoke source missing; skipping case 02_tryxw.")
endif()

set(_package_smoke_src_dir "${CMAKE_CURRENT_SOURCE_DIR}/package_smoke")
set(_package_smoke_script "${CMAKE_CURRENT_SOURCE_DIR}/package_smoke/run_package_smoke.cmake")
if(EXISTS "${_package_smoke_src_dir}/CMakeLists.txt" AND EXISTS "${_package_smoke_script}")
  add_test(NAME package_smoke
           COMMAND ${CMAKE_COMMAND}
             -DMAIN_BUILD_DIR=${CMAKE_BINARY_DIR}
             -DPACKAGE_PREFIX=${CMAKE_BINARY_DIR}/package-prefix
             -DPACKAGE_SMOKE_SOURCE_DIR=${_package_smoke_src_dir}
             -DPACKAGE_SMOKE_BINARY_DIR=${CMAKE_BINARY_DIR}/package-smoke
             -P ${_package_smoke_script})
  set_tests_properties(package_smoke
    PROPERTIES
      LABELS "package")
endif()
