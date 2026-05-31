add_library(sensor_core INTERFACE)

target_include_directories(sensor_core INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_compile_features(sensor_core INTERFACE cxx_std_17)
