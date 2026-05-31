cmake_minimum_required(VERSION 3.16)
project(MultiplatformGuiDemo VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(GUI_ADAPTER "qt" CACHE STRING "GUI adapter to build: qt or wx")
set_property(CACHE GUI_ADAPTER PROPERTY STRINGS qt wx)

if(NOT GUI_ADAPTER MATCHES "^(qt|wx)$")
    message(FATAL_ERROR "GUI_ADAPTER must be 'qt' or 'wx', got: '${GUI_ADAPTER}'")
endif()

message(STATUS "Building adapter : ${GUI_ADAPTER}")
message(STATUS "Build type       : ${CMAKE_BUILD_TYPE}")
message(STATUS "System           : ${CMAKE_SYSTEM_NAME} ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "Compiler         : ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")

include(cmake/CompilerWarnings.cmake)

add_subdirectory(core)

if(GUI_ADAPTER STREQUAL "qt")
    add_subdirectory(adapters/qt)
elseif(GUI_ADAPTER STREQUAL "wx")
    add_subdirectory(adapters/wx)
endif()
