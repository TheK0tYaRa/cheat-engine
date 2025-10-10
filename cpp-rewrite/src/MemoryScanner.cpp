#include "MemoryScanner.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <optional>

namespace cpprewrite {

namespace {
constexpr std::size_t kReadChunk = 1 << 16;
}  // namespace

MemoryScanner::MemoryScanner(ProcessMemory& process) : process_(process) {}

std::vector<ScanResult> MemoryScanner::PerformScan(const ScanRequest& request) {
    std::vector<ScanResult> results;
    if (!process_.is_open()) {
        return results;
    }

    auto parsed = ParseValue(request.type, request.value_text);
    if (!parsed.has_value() || !IsFinite(request.type, parsed.value())) {
        return results;
    }

    std::vector<std::uint8_t> buffer(kReadChunk);
    std::vector<std::uint8_t> candidate(ValueSize(request.type));

    for (const MemoryRegion& region : process_.regions()) {
        if (!region.readable()) {
            continue;
        }
        if (request.only_writable && !region.writable()) {
            continue;
        }

        std::uintptr_t address = region.start;
        while (address < region.end) {
            std::size_t to_read = std::min<std::size_t>(buffer.size(), region.end - address);
            if (!process_.read(address, buffer.data(), to_read)) {
                break;
            }

            for (std::size_t offset = 0; offset + candidate.size() <= to_read; ++offset) {
                std::memcpy(candidate.data(), buffer.data() + offset, candidate.size());
                if (CompareValue(request.type, candidate.data(), parsed.value())) {
                    ScanResult result;
                    result.address = address + offset;
                    result.bytes.assign(candidate.begin(), candidate.end());
                    results.push_back(std::move(result));
                }
            }

            if (to_read < buffer.size()) {
                break;
            }
            address += buffer.size();
        }
    }

    return results;
}

std::optional<MemoryScanner::ValueVariant> MemoryScanner::ParseValue(ValueType type, const std::string& text) {
    try {
        switch (type) {
            case ValueType::Int32:
                return static_cast<std::int32_t>(std::stol(text));
            case ValueType::UInt32:
                return static_cast<std::uint32_t>(std::stoul(text));
            case ValueType::Float:
                return std::stof(text);
            case ValueType::Double:
                return std::stod(text);
        }
    } catch (...) {
        return std::nullopt;
    }
    return std::nullopt;
}

std::size_t MemoryScanner::ValueSize(ValueType type) {
    switch (type) {
        case ValueType::Int32:
        case ValueType::UInt32:
        case ValueType::Float:
            return 4;
        case ValueType::Double:
            return 8;
    }
    return 4;
}

bool MemoryScanner::CompareValue(ValueType type, const std::uint8_t* data, const ValueVariant& value) {
    switch (type) {
        case ValueType::Int32: {
            std::int32_t candidate;
            std::memcpy(&candidate, data, sizeof(candidate));
            return candidate == std::get<std::int32_t>(value);
        }
        case ValueType::UInt32: {
            std::uint32_t candidate;
            std::memcpy(&candidate, data, sizeof(candidate));
            return candidate == std::get<std::uint32_t>(value);
        }
        case ValueType::Float: {
            float candidate;
            std::memcpy(&candidate, data, sizeof(candidate));
            return candidate == std::get<float>(value);
        }
        case ValueType::Double: {
            double candidate;
            std::memcpy(&candidate, data, sizeof(candidate));
            return candidate == std::get<double>(value);
        }
    }
    return false;
}

bool MemoryScanner::IsFinite(ValueType type, const ValueVariant& value) {
    if (type == ValueType::Float) {
        return std::isfinite(std::get<float>(value));
    }
    if (type == ValueType::Double) {
        return std::isfinite(std::get<double>(value));
    }
    return true;
}

}  // namespace cpprewrite
