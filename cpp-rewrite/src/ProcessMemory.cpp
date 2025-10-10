#include "ProcessMemory.hpp"

#include <dirent.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <algorithm>
#include <cerrno>
#include <cstring>
#include <fstream>
#include <sstream>

namespace cpprewrite {
namespace {
std::string ReadComm(int pid) {
    std::string path = "/proc/" + std::to_string(pid) + "/comm";
    std::ifstream file(path);
    if (!file.is_open()) {
        return {};
    }
    std::string name;
    std::getline(file, name);
    return name;
}

bool ParseMapLine(const std::string& line, MemoryRegion& region) {
    std::istringstream iss(line);
    std::string addresses;
    if (!(iss >> addresses >> region.permissions)) {
        return false;
    }
    auto dash = addresses.find('-');
    if (dash == std::string::npos) {
        return false;
    }
    region.start = std::stoull(addresses.substr(0, dash), nullptr, 16);
    region.end = std::stoull(addresses.substr(dash + 1), nullptr, 16);

    std::string offset, dev, inode;
    iss >> offset >> dev >> inode;
    std::getline(iss, region.pathname);
    if (!region.pathname.empty() && region.pathname[0] == ' ') {
        region.pathname.erase(region.pathname.begin());
    }
    return true;
}
}  // namespace

ProcessMemory::ProcessMemory(int pid) {
    open(pid);
}

ProcessMemory::ProcessMemory(ProcessMemory&& other) noexcept {
    *this = std::move(other);
}

ProcessMemory& ProcessMemory::operator=(ProcessMemory&& other) noexcept {
    if (this == &other) {
        return *this;
    }
    close();
    pid_ = other.pid_;
    mem_fd_ = other.mem_fd_;
    regions_ = std::move(other.regions_);
    other.pid_ = -1;
    other.mem_fd_ = -1;
    return *this;
}

ProcessMemory::~ProcessMemory() {
    close();
}

std::vector<ProcessInfo> ProcessMemory::ListProcesses() {
    std::vector<ProcessInfo> processes;
    DIR* dir = opendir("/proc");
    if (!dir) {
        return processes;
    }

    struct dirent* entry = nullptr;
    while ((entry = readdir(dir)) != nullptr) {
        if (entry->d_type != DT_DIR) {
            continue;
        }
        char* end = nullptr;
        long pid = std::strtol(entry->d_name, &end, 10);
        if (!end || *end != '\0') {
            continue;
        }
        ProcessInfo info;
        info.pid = static_cast<int>(pid);
        info.name = ReadComm(info.pid);
        processes.push_back(std::move(info));
    }

    closedir(dir);
    std::sort(processes.begin(), processes.end(), [](const ProcessInfo& a, const ProcessInfo& b) {
        return a.pid < b.pid;
    });
    return processes;
}

bool ProcessMemory::open(int pid) {
    close();

    std::string mem_path = "/proc/" + std::to_string(pid) + "/mem";
    int fd = ::open(mem_path.c_str(), O_RDONLY);
    if (fd < 0) {
        return false;
    }

    pid_ = pid;
    mem_fd_ = fd;
    return refresh_regions();
}

void ProcessMemory::close() {
    if (mem_fd_ >= 0) {
        ::close(mem_fd_);
    }
    mem_fd_ = -1;
    pid_ = -1;
    regions_.clear();
}

bool ProcessMemory::refresh_regions() {
    regions_.clear();
    if (pid_ < 0) {
        return false;
    }

    std::string maps_path = "/proc/" + std::to_string(pid_) + "/maps";
    std::ifstream file(maps_path);
    if (!file.is_open()) {
        return false;
    }

    std::string line;
    while (std::getline(file, line)) {
        MemoryRegion region;
        if (ParseMapLine(line, region)) {
            regions_.push_back(std::move(region));
        }
    }
    return true;
}

bool ProcessMemory::read(std::uintptr_t address, void* buffer, std::size_t size) const {
    if (mem_fd_ < 0) {
        return false;
    }

    ssize_t result = pread(mem_fd_, buffer, size, static_cast<off_t>(address));
    return result == static_cast<ssize_t>(size);
}

}  // namespace cpprewrite
