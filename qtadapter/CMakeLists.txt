cmake_minimum_required(VERSION 3.14)
project(Qt5DecoupledDemo VERSION 1.0 LANGUAGES CXX)

# ── C++ standard ──────────────────────────────────────────────────────────────
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ── Qt5 MOC / UIC / RCC automation ───────────────────────────────────────────
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

# ── Find Qt5 ─────────────────────────────────────────────────────────────────
find_package(Qt5 REQUIRED COMPONENTS Core Widgets)

# ── Source files ─────────────────────────────────────────────────────────────
set(SOURCES
    src/main.cpp
    src/qt_adapter/ui/MainWindow.cpp
)

set(HEADERS
    # Domain interfaces (pure C++)
    src/domain/interfaces/IEventBus.h
    src/domain/interfaces/IWorker.h

    # Domain models
    src/domain/models/SensorData.h

    # Domain workers & services
    src/domain/workers/SensorWorker.h
    src/domain/services/DataProcessingService.h

    # Infrastructure (pure C++)
    src/infrastructure/EventBus.h
    src/infrastructure/WorkerThread.h

    # Qt adapter layer (QObject lives here)
    src/qt_adapter/QtEventBusAdapter.h
    src/qt_adapter/QtWorkerAdapter.h
    src/qt_adapter/ui/MainWindow.h
)

# ── Executable ───────────────────────────────────────────────────────────────
add_executable(${PROJECT_NAME}
    ${SOURCES}
    ${HEADERS}   # listed so they appear in IDEs and AUTOMOC finds them
)

# ── Include paths ─────────────────────────────────────────────────────────────
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# ── Link Qt5 ─────────────────────────────────────────────────────────────────
target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt5::Core
    Qt5::Widgets
    pthread   # needed for std::thread on Linux
)

# ── Compiler warnings ─────────────────────────────────────────────────────────
target_compile_options(${PROJECT_NAME} PRIVATE
    -Wall
    -Wextra
    -Wpedantic
)

message(STATUS "Qt5 version: ${Qt5_VERSION}")
message(STATUS "Build type:  ${CMAKE_BUILD_TYPE}")

# ── Install (used by Qt Creator's deploy-to-device step) ─────────────────────
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION /home/pg
)
