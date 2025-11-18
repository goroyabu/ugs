set(XWTEST_SMOKE_SUPPORT FALSE)

set(_wrap_src "${CMAKE_CURRENT_SOURCE_DIR}/cases/01_smoke/xwindowc_smoke.c")
if(NOT EXISTS "${_wrap_src}")
  message(FATAL_ERROR "Missing xwtest smoke source: ${_wrap_src}")
endif()

set(_xwtest_generated
  ${UGS_GEN_DIR}/drivers/cursor1.bmp
  ${UGS_GEN_DIR}/drivers/cursor2.bmp
  ${UGS_GEN_DIR}/drivers/icon.bmp
  ${UGS_GEN_DIR}/drivers/rotated.c
)
set_source_files_properties(${_xwtest_generated}
  PROPERTIES GENERATED TRUE
)

add_executable(xwtest_smoke
  "${_wrap_src}"
  ${UGS_GEN_DIR}/drivers/cursor1.bmp
  ${UGS_GEN_DIR}/drivers/cursor2.bmp
  ${UGS_GEN_DIR}/drivers/icon.bmp
  ${UGS_GEN_DIR}/drivers/rotated.c
)
add_dependencies(xwtest_smoke prepare_sources)
target_compile_definitions(xwtest_smoke PRIVATE SELFTEST)
target_include_directories(xwtest_smoke PRIVATE ${UGS_GEN_DIR}/drivers ${X11_INCLUDE_DIR})
target_link_libraries(xwtest_smoke PRIVATE ${X11_LIBRARIES} ${X11_Xaw_LIB} ${X11_Xmu_LIB} ${X11_Xt_LIB})

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

  add_test(NAME 01_smoke_xwtest
           COMMAND ${_xwtest_smoke_cmd})
  set_tests_properties(01_smoke_xwtest
    PROPERTIES
      LABELS "smoke;x11"
      PASS_REGULAR_EXPRESSION "${_expected_regex}")
else()
  message(STATUS "xwtest_smoke target not available; skipping GUI smoke test registration.")
endif()
