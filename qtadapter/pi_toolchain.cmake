set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# ==========================================
# Sysroot Configuration
# ==========================================
set(SYSROOT /usr/aarch64-linux-gnu)
set(CMAKE_FIND_ROOT_PATH ${SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# ==========================================
# Cross-compiler Setup
# ==========================================
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

# Compiler flags for debug symbols and optimization
set(CMAKE_C_FLAGS_DEBUG "-g3 -O0" CACHE STRING "C Debug flags")
set(CMAKE_CXX_FLAGS_DEBUG "-g3 -O0" CACHE STRING "C++ Debug flags")

# ==========================================
# Qt5 Configuration for ARM64
# ==========================================
# Primary paths for multiarch Qt5 libraries
set(QT_LIBRARY_PATHS
    ${SYSROOT}/lib
    /usr/lib/aarch64-linux-gnu
    /usr/lib/aarch64-linux-gnu/cmake
)

set(Qt5_DIR /usr/lib/aarch64-linux-gnu/cmake/Qt5 CACHE PATH "Qt5 CMake config path")
set(CMAKE_PREFIX_PATH
    /usr/lib/aarch64-linux-gnu/cmake/Qt5
    /usr/lib/aarch64-linux-gnu
)

# ==========================================
# pkg-config Path for Qt5 Discovery
# ==========================================
set(ENV{PKG_CONFIG_LIBDIR} "/usr/lib/aarch64-linux-gnu/pkgconfig")

# ==========================================
# Debugging Support
# ==========================================
# Ensure debug symbols are always included in cross-compiled binaries
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-omit-frame-pointer" CACHE STRING "CXX flags for debugging" FORCE)
