#pragma once

#include "ProcessMemory.hpp"

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <limits>
#include <optional>
#include <string>
#include <variant>
#include <vector>

namespace cpprewrite {

enum class ValueType {
    Int4,
    Int8,
    Int16,
    Int32,
    Int64,
    Float,
    Double,
    String,
    CStringPointer,
};

struct ScanRequest {
    ValueType type = ValueType::Int32;
    std::string value_text;
    bool is_signed = true;
    std::vector<bool> region_selection;
    std::uintptr_t start_address = 0;
    std::uintptr_t end_address = std::numeric_limits<std::uintptr_t>::max();
};

struct ScanResult {
    std::uintptr_t address = 0;
    std::vector<std::uint8_t> bytes;
    std::size_t bit_offset = 0;
    std::string display_value;
    ValueType type = ValueType::Int32;
    bool is_signed = true;
    std::size_t value_size = 0;
};

class MemoryScanner {
public:
    explicit MemoryScanner(ProcessMemory& process);

    std::vector<ScanResult> PerformScan(
        const ScanRequest& request,
        const std::function<void(std::size_t, std::size_t)>& progress_callback = {},
        std::atomic<bool>* cancel = nullptr);

private:
    struct CStringAddress {
        std::uintptr_t value = 0;
    };

    using ValueVariant =
        std::variant<std::int64_t, std::uint64_t, float, double, std::string, CStringAddress>;

    static std::optional<ValueVariant> ParseValue(ValueType type, bool is_signed, const std::string& text);
    static std::size_t ValueSize(ValueType type, const ValueVariant& value);
    static bool CompareValue(ValueType type, const std::uint8_t* data, const ValueVariant& value,
                            bool is_signed);
    static bool IsFinite(ValueType type, const ValueVariant& value);

    ProcessMemory& process_;
};

}  // namespace cpprewrite