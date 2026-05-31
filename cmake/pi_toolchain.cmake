set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# ── Sysroot ───────────────────────────────────────────────────────────────────
set(SYSROOT /usr/aarch64-linux-gnu)
# Include multiarch lib dir so find_library() can resolve ARM64 .so files
# installed via Debian/Ubuntu multiarch packages (e.g. libwxgtk3.2-dev:arm64)
set(CMAKE_FIND_ROOT_PATH ${SYSROOT} /usr/lib/aarch64-linux-gnu)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
# BOTH: FindwxWidgets uses find_path() with absolute paths from wx-config;
# ONLY mode prepends the sysroot and misses arch-independent headers in
# /usr/include/wx-3.2 that come from the wx3.2-headers package.
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)

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
# Priority 1: explicit cmake -DwxWidgets_ROOT_DIR=... or env var (Docker path)
# Priority 2: Debian/Ubuntu multiarch package (libwxgtk3.2-dev:arm64)
set(_WX_MULTIARCH_CONFIG /usr/lib/aarch64-linux-gnu/wx/config/gtk3-unicode-3.2)
if(DEFINED ENV{wxWidgets_ROOT_DIR})
    set(wxWidgets_ROOT_DIR $ENV{wxWidgets_ROOT_DIR})
elseif(NOT DEFINED wxWidgets_ROOT_DIR AND EXISTS "${_WX_MULTIARCH_CONFIG}")
    set(wxWidgets_CONFIG_EXECUTABLE "${_WX_MULTIARCH_CONFIG}"
        CACHE FILEPATH "ARM64 wx-config from libwxgtk3.2-dev:arm64")
    message(STATUS "wxWidgets ARM64 : using multiarch config ${_WX_MULTIARCH_CONFIG}")
endif()
unset(_WX_MULTIARCH_CONFIG)
