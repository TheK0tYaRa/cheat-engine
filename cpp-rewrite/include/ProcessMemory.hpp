#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace cpprewrite {

struct MemoryRegion {
    std::uintptr_t start = 0;
    std::uintptr_t end = 0;
    std::string permissions;
    std::string pathname;

    [[nodiscard]] std::size_t size() const { return end - start; }
    [[nodiscard]] bool readable() const { return !permissions.empty() && permissions[0] == 'r'; }
    [[nodiscard]] bool writable() const { return permissions.size() > 1 && permissions[1] == 'w'; }
};

struct ProcessInfo {
    int pid = -1;
    std::string name;
};

class ProcessMemory {
public:
    ProcessMemory() = default;
    explicit ProcessMemory(int pid);
    ProcessMemory(const ProcessMemory&) = delete;
    ProcessMemory& operator=(const ProcessMemory&) = delete;
    ProcessMemory(ProcessMemory&& other) noexcept;
    ProcessMemory& operator=(ProcessMemory&& other) noexcept;
    ~ProcessMemory();

    static std::vector<ProcessInfo> ListProcesses();

    bool open(int pid);
    void close();

    [[nodiscard]] bool is_open() const { return mem_fd_ >= 0; }
    [[nodiscard]] int pid() const { return pid_; }
    [[nodiscard]] const std::vector<MemoryRegion>& regions() const { return regions_; }

    bool refresh_regions();

    bool read(std::uintptr_t address, void* buffer, std::size_t size) const;

    template <typename T>
    std::optional<T> read_value(std::uintptr_t address) const {
        T value{};
        if (!read(address, &value, sizeof(T))) {
            return std::nullopt;
        }
        return value;
    }

private:
    int pid_ = -1;
    int mem_fd_ = -1;
    std::vector<MemoryRegion> regions_;
};

}  // namespace cpprewrite
