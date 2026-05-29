set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Force the cross-compiler
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

# Teach CMake where the ARM64 Qt5 libraries live
set(CMAKE_PREFIX_PATH "/usr/lib/aarch64-linux-gnu/cmake/Qt5")
set(Qt5_DIR "/usr/lib/aarch64-linux-gnu/cmake/Qt5")

# Direct CMake to look inside the arm64 system paths
set(CMAKE_FIND_ROOT_PATH /usr/lib/aarch64-linux-gnu)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
