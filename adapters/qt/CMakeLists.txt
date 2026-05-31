set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt5 REQUIRED COMPONENTS Core Widgets)

add_executable(SensorDemoQt
    src/main.cpp
    src/ui/MainWindow.cpp
    src/QtEventBusAdapter.h
    src/QtWorkerAdapter.h
    src/ui/MainWindow.h
)

target_include_directories(SensorDemoQt PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(SensorDemoQt PRIVATE
    sensor_core
    Qt5::Core
    Qt5::Widgets
    pthread
)

apply_compiler_warnings(SensorDemoQt)

message(STATUS "Qt5 version: ${Qt5_VERSION}")
