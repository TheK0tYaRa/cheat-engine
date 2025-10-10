# Cheat Engine C++ Rewrite (Linux, ImGui)

This folder contains an experimental rewrite of the Cheat Engine memory scanner UI for Linux using modern C++17 and Dear ImGui. The rewrite focuses on providing a lightweight graphical interface for inspecting processes and performing basic value scans.

## Features

- Process browser backed by `/proc` that lists running processes by PID and command name.
- On-demand attachment to a selected process with live region refresh.
- Exact-value scans for 32-bit integers, unsigned integers, and floating point values.
- Optional filtering to writable memory regions for faster, safer scans.
- Dear ImGui-based interface rendered through SDL2 and OpenGL 3.

## Building

The project uses CMake. You will need development packages for SDL2, OpenGL, and a C++17-capable compiler. CMake automatically downloads Dear ImGui via `FetchContent`, so outbound network access is required during the first configuration.

```bash
sudo apt install build-essential cmake libsdl2-dev libopengl-dev

cd cpp-rewrite
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

The resulting binary `cheat-engine-rewrite` is located in `build/`.

> **Note:** Accessing `/proc/<pid>/mem` usually requires root or ptrace permissions. Run the program with `sudo` if you need to scan another user's processes.

## Running

```bash
sudo ./build/cheat-engine-rewrite
```

Use the **Processes** panel to refresh and select a process. The **Scanner** panel allows you to pick a value type, input a value, and run a new scan. Results display addresses, matching bytes, and the containing memory region.

## Third-party code

This folder vendors Dear ImGui source files (MIT License) directly from the official project to simplify builds. SDL2 and OpenGL remain external dependencies.
