cmake_minimum_required(VERSION 3.16)
project(cheat-engine-rewrite LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include(FetchContent)

FetchContent_Declare(
    imgui
    URL https://github.com/ocornut/imgui/archive/refs/tags/v1.89.9.zip
)

FetchContent_MakeAvailable(imgui)

set(IMGUI_SRC
    ${imgui_SOURCE_DIR}/imgui.cpp
    ${imgui_SOURCE_DIR}/imgui_draw.cpp
    ${imgui_SOURCE_DIR}/imgui_tables.cpp
    ${imgui_SOURCE_DIR}/imgui_widgets.cpp
    ${imgui_SOURCE_DIR}/backends/imgui_impl_opengl3.cpp
    ${imgui_SOURCE_DIR}/backends/imgui_impl_sdl2.cpp
)

add_library(imgui STATIC ${IMGUI_SRC})

if (MSVC)
    target_compile_options(imgui PRIVATE /W4)
else()
    target_compile_options(imgui PRIVATE -Wall -Wextra -Wpedantic)
endif()

target_compile_definitions(imgui PUBLIC IMGUI_IMPL_OPENGL_LOADER_GL3W)

target_include_directories(imgui PUBLIC ${imgui_SOURCE_DIR} ${imgui_SOURCE_DIR}/backends)

find_package(OpenGL REQUIRED)
find_package(SDL2 REQUIRED)

add_executable(cheat-engine-rewrite
    src/main.cpp
    src/Application.cpp
    src/ProcessMemory.cpp
    src/MemoryScanner.cpp
)

target_include_directories(cheat-engine-rewrite PRIVATE include)

target_link_libraries(cheat-engine-rewrite PRIVATE imgui SDL2::SDL2 OpenGL::GL)

if (UNIX AND NOT APPLE)
    target_link_libraries(cheat-engine-rewrite PRIVATE dl pthread)
endif()
