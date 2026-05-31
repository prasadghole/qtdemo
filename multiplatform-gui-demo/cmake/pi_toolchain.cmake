set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# ── Sysroot ───────────────────────────────────────────────────────────────────
set(SYSROOT /usr/aarch64-linux-gnu)
set(CMAKE_FIND_ROOT_PATH ${SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# ── Cross-compiler ────────────────────────────────────────────────────────────
set(CMAKE_C_COMPILER   aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

set(CMAKE_C_FLAGS_DEBUG   "-g3 -O0" CACHE STRING "C debug flags")
set(CMAKE_CXX_FLAGS_DEBUG "-g3 -O0" CACHE STRING "C++ debug flags")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-omit-frame-pointer"
    CACHE STRING "CXX flags" FORCE)

# ── Qt5 ARM64 paths (used when GUI_ADAPTER=qt) ────────────────────────────────
set(Qt5_DIR /usr/lib/aarch64-linux-gnu/cmake/Qt5 CACHE PATH "Qt5 ARM64 cmake dir")
set(CMAKE_PREFIX_PATH
    /usr/lib/aarch64-linux-gnu/cmake/Qt5
    /usr/lib/aarch64-linux-gnu
)
set(ENV{PKG_CONFIG_LIBDIR} "/usr/lib/aarch64-linux-gnu/pkgconfig")

# ── wxWidgets ARM64 path (used when GUI_ADAPTER=wx) ───────────────────────────
# Set by Docker: ENV wxWidgets_ROOT_DIR=/opt/wx-arm64
if(DEFINED ENV{wxWidgets_ROOT_DIR})
    set(wxWidgets_ROOT_DIR $ENV{wxWidgets_ROOT_DIR})
endif()
