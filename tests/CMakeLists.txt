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
