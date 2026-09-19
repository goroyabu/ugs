cmake_minimum_required(VERSION 3.15)
project(ugs_cmake_example LANGUAGES Fortran)

include(CTest)

find_package(ugs CONFIG REQUIRED)

if(NOT TARGET ugs::ugs)
  message(FATAL_ERROR "The installed package does not provide ugs::ugs")
endif()

if(DEFINED UGS_EXPECTED_PREFIX AND NOT UGS_EXPECTED_PREFIX STREQUAL "")
  get_filename_component(_expected_prefix "${UGS_EXPECTED_PREFIX}" REALPATH)
  get_filename_component(_resolved_package_dir "${ugs_DIR}" REALPATH)
  string(FIND "${_resolved_package_dir}/" "${_expected_prefix}/" _package_prefix_index)
  if(NOT _package_prefix_index EQUAL 0)
    message(FATAL_ERROR
      "ugsConfig.cmake resolved outside the expected prefix: ${ugs_DIR}")
  endif()

  set(_ugs_locations)
  get_target_property(_ugs_imported_configurations
    ugs::ugs IMPORTED_CONFIGURATIONS)
  foreach(_ugs_configuration IN LISTS _ugs_imported_configurations)
    string(TOUPPER "${_ugs_configuration}" _ugs_configuration_upper)
    get_target_property(_ugs_configuration_location ugs::ugs
      "IMPORTED_LOCATION_${_ugs_configuration_upper}")
    if(_ugs_configuration_location
       AND NOT _ugs_configuration_location MATCHES "-NOTFOUND$")
      list(APPEND _ugs_locations "${_ugs_configuration_location}")
    endif()
  endforeach()

  foreach(_ugs_location_property IN ITEMS
      IMPORTED_LOCATION_NOCONFIG IMPORTED_LOCATION)
    get_target_property(_ugs_location ugs::ugs "${_ugs_location_property}")
    if(_ugs_location AND NOT _ugs_location MATCHES "-NOTFOUND$")
      list(APPEND _ugs_locations "${_ugs_location}")
    endif()
  endforeach()

  if(NOT _ugs_locations)
    message(FATAL_ERROR "ugs::ugs does not provide an imported library location")
  endif()

  list(REMOVE_DUPLICATES _ugs_locations)
  foreach(_ugs_location IN LISTS _ugs_locations)
    get_filename_component(_resolved_ugs_location "${_ugs_location}" REALPATH)
    string(FIND "${_resolved_ugs_location}/" "${_expected_prefix}/"
      _library_prefix_index)
    if(NOT _library_prefix_index EQUAL 0)
      message(FATAL_ERROR
        "ugs::ugs resolved outside the expected prefix: ${_ugs_location}")
    endif()
  endforeach()
endif()

add_executable(ugs_postscript_example ugs_postscript_example.f90)
target_link_libraries(ugs_postscript_example PRIVATE ugs::ugs)

if(BUILD_TESTING)
  add_test(NAME ugs_postscript_example.run
    COMMAND $<TARGET_FILE:ugs_postscript_example>)
  set_tests_properties(ugs_postscript_example.run PROPERTIES
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
endif()
