cmake_minimum_required(VERSION 3.15)
project(ugs_package_smoke LANGUAGES C)

find_package(ugs CONFIG REQUIRED)

add_executable(ugs_package_smoke main.c)
target_link_libraries(ugs_package_smoke PRIVATE ugs::ugs)
