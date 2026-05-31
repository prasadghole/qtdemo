set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# ── Cross-compiler ────────────────────────────────────────────────────────────
set(CMAKE_C_COMPILER   x86_64-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++)
set(CMAKE_RC_COMPILER  x86_64-w64-mingw32-windres)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# ── wxWidgets for MinGW ───────────────────────────────────────────────────────
# Priority: cmake var > env var > Docker default
if(NOT wxWidgets_ROOT_DIR AND DEFINED ENV{wxWidgets_ROOT_DIR})
    set(wxWidgets_ROOT_DIR $ENV{wxWidgets_ROOT_DIR})
endif()
if(NOT wxWidgets_ROOT_DIR)
    set(wxWidgets_ROOT_DIR /opt/wx-mingw)
endif()

# Link C/C++ runtimes statically so the .exe runs without MinGW DLLs
set(CMAKE_EXE_LINKER_FLAGS
    "${CMAKE_EXE_LINKER_FLAGS} -static-libgcc -static-libstdc++"
    CACHE STRING "Linker flags" FORCE)
