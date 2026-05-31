if(NOT wxWidgets_ROOT_DIR AND DEFINED ENV{wxWidgets_ROOT_DIR})
    set(wxWidgets_ROOT_DIR "$ENV{wxWidgets_ROOT_DIR}")
endif()
if(WIN32 AND NOT wxWidgets_ROOT_DIR)
    set(wxWidgets_ROOT_DIR "C:/wxWidgets")
endif()

if(wxWidgets_ROOT_DIR)
    message(STATUS "wxWidgets root: ${wxWidgets_ROOT_DIR}")
endif()

set(wxWidgets_USE_STATIC OFF)
set(wxWidgets_USE_UNICODE ON)

find_package(wxWidgets REQUIRED COMPONENTS core base)
include(${wxWidgets_USE_FILE})

add_executable(SensorDemoWx
    src/WxApp.cpp
    src/WxEventBusAdapter.cpp
    src/ui/MainWindow.cpp
    src/WxApp.h
    src/WxEventBusAdapter.h
    src/ui/MainWindow.h
)

target_include_directories(SensorDemoWx PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(SensorDemoWx PRIVATE
    sensor_core
    ${wxWidgets_LIBRARIES}
)

if(UNIX AND NOT APPLE)
    target_link_libraries(SensorDemoWx PRIVATE pthread)
endif()

if(WIN32)
    set_target_properties(SensorDemoWx PROPERTIES WIN32_EXECUTABLE ON)
endif()

apply_compiler_warnings(SensorDemoWx)

message(STATUS "wxWidgets libraries: ${wxWidgets_LIBRARIES}")
