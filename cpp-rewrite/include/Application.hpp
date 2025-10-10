#pragma once

#include "MemoryScanner.hpp"
#include "ProcessMemory.hpp"

namespace cpprewrite {

class Application {
public:
    Application();
    ~Application();

    Application(const Application&) = delete;
    Application& operator=(const Application&) = delete;

    bool Initialize();
    void Run();

private:
    struct Impl;
    Impl* impl_ = nullptr;
};

}  // namespace cpprewrite
