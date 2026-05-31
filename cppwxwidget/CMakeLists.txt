cmake_minimum_required(VERSION 3.14)
project(WxWidgetDemo)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic")

# wxWidgets configuration
set(wxWidgets_USE_STATIC OFF)
set(wxWidgets_USE_UNICODE ON)

if(WIN32)
    set(wxWidgets_ROOT_DIR "C:/wxWidgets")
    find_package(wxWidgets REQUIRED COMPONENTS core base)
else()
    find_package(wxWidgets REQUIRED COMPONENTS core base)
endif()

include(${wxWidgets_USE_FILE})

# Domain layer (no dependencies on UI)
set(DOMAIN_SOURCES
    src/domain/models/SensorData.h
    src/domain/interfaces/IEventBus.h
    src/domain/interfaces/IWorker.h
    src/domain/services/DataProcessingService.h
    src/domain/workers/SensorWorker.h
)

# Infrastructure layer (no UI dependencies)
set(INFRASTRUCTURE_SOURCES
    src/infrastructure/EventBus.h
    src/infrastructure/WorkerThread.h
)

# wxWidgets UI Adapter layer
set(WX_ADAPTER_SOURCES
    src/wx_adapter/ui/MainWindow.h
    src/wx_adapter/ui/MainWindow.cpp
    src/wx_adapter/WxEventBusAdapter.h
    src/wx_adapter/WxEventBusAdapter.cpp
    src/wx_adapter/WxApp.h
    src/wx_adapter/WxApp.cpp
)

# Main executable
add_executable(WxWidgetDemo
    ${DOMAIN_SOURCES}
    ${INFRASTRUCTURE_SOURCES}
    ${WX_ADAPTER_SOURCES}
)

target_include_directories(WxWidgetDemo PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_link_libraries(WxWidgetDemo ${wxWidgets_LIBRARIES})

# Platform-specific settings
if(APPLE)
    set_target_properties(WxWidgetDemo PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.example.wxwidgetdemo"
    )
endif()

if(WIN32)
    set_target_properties(WxWidgetDemo PROPERTIES
        WIN32_EXECUTABLE ON
    )
endif()
