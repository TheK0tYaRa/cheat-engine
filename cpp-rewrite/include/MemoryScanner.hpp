#pragma once

#include "ProcessMemory.hpp"

#include <cstdint>
#include <functional>
#include <optional>
#include <string>
#include <variant>
#include <vector>

namespace cpprewrite {

enum class ValueType {
    Int32,
    UInt32,
    Float,
    Double,
};

struct ScanRequest {
    ValueType type = ValueType::Int32;
    std::string value_text;
    bool only_writable = true;
};

struct ScanResult {
    std::uintptr_t address = 0;
    std::vector<std::uint8_t> bytes;
};

class MemoryScanner {
public:
    explicit MemoryScanner(ProcessMemory& process);

    std::vector<ScanResult> PerformScan(const ScanRequest& request);

private:
    using ValueVariant = std::variant<std::int32_t, std::uint32_t, float, double>;

    static std::optional<ValueVariant> ParseValue(ValueType type, const std::string& text);
    static std::size_t ValueSize(ValueType type);
    static bool CompareValue(ValueType type, const std::uint8_t* data, const ValueVariant& value);
    static bool IsFinite(ValueType type, const ValueVariant& value);

    ProcessMemory& process_;
};

}  // namespace cpprewrite
