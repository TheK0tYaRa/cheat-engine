#include "MemoryScanner.hpp"

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstring>
#include <iomanip>
#include <limits>
#include <optional>
#include <sstream>
#include <string>

namespace cpprewrite {

namespace {

constexpr std::size_t kReadChunk = 1 << 16;

std::size_t IntegerBitWidth(ValueType type) {
    switch (type) {
        case ValueType::Int4:
            return 4;
        case ValueType::Int8:
            return 8;
        case ValueType::Int16:
            return 16;
        case ValueType::Int32:
            return 32;
        case ValueType::Int64:
            return 64;
        default:
            return 0;
    }
}

std::uint64_t ReadLittleEndian(const std::uint8_t* data, std::size_t bytes) {
    std::uint64_t value = 0;
    for (std::size_t i = 0; i < bytes; ++i) {
        value |= static_cast<std::uint64_t>(data[i]) << (i * 8);
    }
    return value;
}

std::int64_t SignExtend(std::uint64_t value, std::size_t bits) {
    if (bits == 0) {
        return 0;
    }
    if (bits >= 64) {
        return static_cast<std::int64_t>(value);
    }
    const std::uint64_t sign_bit = static_cast<std::uint64_t>(1) << (bits - 1);
    std::uint64_t extended = (value ^ sign_bit) - sign_bit;
    return static_cast<std::int64_t>(extended);
}

std::uintptr_t InclusiveRangeEndToExclusive(std::uintptr_t inclusive_end) {
    if (inclusive_end == std::numeric_limits<std::uintptr_t>::max()) {
        return std::numeric_limits<std::uintptr_t>::max();
    }
    return inclusive_end + 1;
}

std::string FormatIntegerString(std::uint64_t raw, std::size_t bits, bool is_signed) {
    if (bits < 64) {
        const std::uint64_t mask = (static_cast<std::uint64_t>(1) << bits) - 1;
        raw &= mask;
    }
    if (is_signed) {
        return std::to_string(SignExtend(raw, bits));
    }
    return std::to_string(raw);
}

template <typename T>
std::string FormatFloatingString(T value) {
    std::ostringstream oss;
    oss << std::setprecision(std::numeric_limits<T>::digits10 + 1) << value;
    return oss.str();
}

std::string FormatPointerString(std::uintptr_t value) {
    std::ostringstream oss;
    oss << "0x" << std::uppercase << std::hex << std::setw(sizeof(std::uintptr_t) * 2)
        << std::setfill('0') << value;
    return oss.str();
}

std::string FormatResultValue(ValueType type, const std::uint8_t* data, std::size_t value_size,
                              bool is_signed) {
    switch (type) {
        case ValueType::Int4:
            break;
        case ValueType::Int8:
        case ValueType::Int16:
        case ValueType::Int32:
        case ValueType::Int64: {
            const std::size_t bits = IntegerBitWidth(type);
            const std::uint64_t raw = ReadLittleEndian(data, value_size);
            return FormatIntegerString(raw, bits, is_signed);
        }
        case ValueType::Float: {
            float value;
            std::memcpy(&value, data, sizeof(value));
            return FormatFloatingString(value);
        }
        case ValueType::Double: {
            double value;
            std::memcpy(&value, data, sizeof(value));
            return FormatFloatingString(value);
        }
        case ValueType::String:
            return std::string(reinterpret_cast<const char*>(data), value_size);
        case ValueType::CStringPointer: {
            std::uintptr_t pointer_value = 0;
            std::memcpy(&pointer_value, data, sizeof(pointer_value));
            return FormatPointerString(pointer_value);
        }
    }
    return {};
}

}  // namespace

MemoryScanner::MemoryScanner(ProcessMemory& process) : process_(process) {}

std::vector<ScanResult> MemoryScanner::PerformScan(
    const ScanRequest& request,
    const std::function<void(std::size_t, std::size_t)>& progress_callback,
    std::atomic<bool>* cancel) {
    std::vector<ScanResult> results;
    if (!process_.is_open()) {
        if (progress_callback) {
            progress_callback(0, 0);
        }
        return results;
    }

    if (request.start_address > request.end_address) {
        if (progress_callback) {
            progress_callback(0, 0);
        }
        return results;
    }

    auto parsed = ParseValue(request.type, request.is_signed, request.value_text);
    if (!parsed.has_value() || !IsFinite(request.type, parsed.value())) {
        if (progress_callback) {
            progress_callback(0, 0);
        }
        return results;
    }

    const ValueVariant& parsed_value = parsed.value();
    const std::size_t value_size = ValueSize(request.type, parsed_value);
    if (request.type == ValueType::String && value_size == 0) {
        if (progress_callback) {
            progress_callback(0, 0);
        }
        return results;
    }

    std::vector<std::uint8_t> buffer(kReadChunk);
    std::vector<std::uint8_t> candidate(value_size > 0 ? value_size : 1);

    const auto& regions = process_.regions();
    if (regions.empty()) {
        if (progress_callback) {
            progress_callback(0, 0);
        }
        return results;
    }

    const std::uintptr_t exclusive_global_end = InclusiveRangeEndToExclusive(request.end_address);

    std::size_t total_bytes = 0;
    for (std::size_t region_index = 0; region_index < regions.size(); ++region_index) {
        if (cancel && cancel->load()) {
            break;
        }

        const MemoryRegion& region = regions[region_index];
        if (!region.readable()) {
            continue;
        }
        if (region_index >= request.region_selection.size() || !request.region_selection[region_index]) {
            continue;
        }

        const std::uintptr_t segment_start = std::max(region.start, request.start_address);
        const std::uintptr_t segment_end = std::min(region.end, exclusive_global_end);
        if (segment_start >= segment_end) {
            continue;
        }

        total_bytes += static_cast<std::size_t>(segment_end - segment_start);
    }

    if (progress_callback) {
        progress_callback(0, total_bytes);
    }

    if (total_bytes == 0) {
        return results;
    }

    std::size_t processed_bytes = 0;

    for (std::size_t region_index = 0; region_index < regions.size(); ++region_index) {
        if (cancel && cancel->load()) {
            break;
        }

        const MemoryRegion& region = regions[region_index];
        if (!region.readable()) {
            continue;
        }
        if (region_index >= request.region_selection.size() || !request.region_selection[region_index]) {
            continue;
        }

        const std::uintptr_t segment_start = std::max(region.start, request.start_address);
        const std::uintptr_t segment_end = std::min(region.end, exclusive_global_end);
        if (segment_start >= segment_end) {
            continue;
        }

        std::uintptr_t address = segment_start;
        while (address < segment_end) {
            if (cancel && cancel->load()) {
                break;
            }

            const std::size_t chunk_remaining = static_cast<std::size_t>(segment_end - address);
            const std::size_t to_read = std::min<std::size_t>(buffer.size(), chunk_remaining);
            if (!process_.read(address, buffer.data(), to_read)) {
                processed_bytes += to_read;
                if (progress_callback) {
                    progress_callback(processed_bytes, total_bytes);
                }
                break;
            }

            if (request.type == ValueType::Int4) {
                for (std::size_t offset = 0; offset < to_read; ++offset) {
                    const std::uint8_t byte = buffer[offset];
                    for (int nibble = 0; nibble < 2; ++nibble) {
                        const std::uint8_t value = (byte >> (nibble * 4)) & 0x0F;
                        bool matches = false;
                        if (request.is_signed) {
                            const std::int64_t target = std::get<std::int64_t>(parsed_value);
                            std::int8_t signed_value = static_cast<std::int8_t>(value);
                            if (value & 0x8U) {
                                signed_value |= static_cast<std::int8_t>(0xF0);
                            }
                            matches = (target == signed_value);
                        } else {
                            const std::uint64_t target = std::get<std::uint64_t>(parsed_value);
                            matches = (target == value);
                        }
                        if (matches) {
                            ScanResult result;
                            result.address = address + offset;
                            result.bit_offset = static_cast<std::size_t>(nibble * 4);
                            result.bytes = {value};
                            result.type = request.type;
                            result.is_signed = request.is_signed;
                            result.value_size = 1;
                            result.display_value =
                                FormatIntegerString(value, IntegerBitWidth(ValueType::Int4), request.is_signed);
                            results.push_back(std::move(result));
                        }
                    }
                }
            } else {
                for (std::size_t offset = 0; offset + value_size <= to_read; ++offset) {
                    std::memcpy(candidate.data(), buffer.data() + offset, value_size);
                    if (CompareValue(request.type, candidate.data(), parsed_value, request.is_signed)) {
                        ScanResult result;
                        result.address = address + offset;
                        result.bytes.assign(candidate.begin(), candidate.begin() + value_size);
                        result.type = request.type;
                        result.is_signed = request.is_signed;
                        result.value_size = value_size;
                        result.display_value =
                            FormatResultValue(request.type, candidate.data(), value_size, request.is_signed);
                        results.push_back(std::move(result));
                    }
                }
            }

            address += to_read;
            processed_bytes += to_read;
            if (progress_callback) {
                progress_callback(processed_bytes, total_bytes);
            }
        }
    }

    if (progress_callback) {
        if (cancel && cancel->load()) {
            progress_callback(processed_bytes, total_bytes);
        } else {
            progress_callback(total_bytes, total_bytes);
        }
    }

    return results;
}

std::optional<MemoryScanner::ValueVariant> MemoryScanner::ParseValue(ValueType type, bool is_signed,
                                                                    const std::string& text) {
    try {
        switch (type) {
            case ValueType::Int4:
            case ValueType::Int8:
            case ValueType::Int16:
            case ValueType::Int32:
            case ValueType::Int64: {
                if (text.empty()) {
                    return std::nullopt;
                }
                std::size_t processed = 0;
                const std::size_t bits = IntegerBitWidth(type);
                if (bits == 0) {
                    return std::nullopt;
                }
                if (is_signed) {
                    long long parsed = std::stoll(text, &processed, 0);
                    if (processed != text.size()) {
                        return std::nullopt;
                    }
                    if (bits < 64) {
                        const long long min_value = -(1LL << (bits - 1));
                        const long long max_value = (1LL << (bits - 1)) - 1;
                        if (parsed < min_value || parsed > max_value) {
                            return std::nullopt;
                        }
                    }
                    return static_cast<std::int64_t>(parsed);
                }
                unsigned long long parsed = std::stoull(text, &processed, 0);
                if (processed != text.size()) {
                    return std::nullopt;
                }
                if (bits < 64) {
                    const unsigned long long max_value = (1ULL << bits) - 1;
                    if (parsed > max_value) {
                        return std::nullopt;
                    }
                }
                return static_cast<std::uint64_t>(parsed);
            }
            case ValueType::Float:
                return std::stof(text);
            case ValueType::Double:
                return std::stod(text);
            case ValueType::String:
                return text;
            case ValueType::CStringPointer: {
                if (text.empty()) {
                    return std::nullopt;
                }
                std::size_t processed = 0;
                unsigned long long parsed = std::stoull(text, &processed, 0);
                if (processed != text.size()) {
                    return std::nullopt;
                }
                return CStringAddress{static_cast<std::uintptr_t>(parsed)};
            }
        }
    } catch (...) {
        return std::nullopt;
    }
    return std::nullopt;
}

std::size_t MemoryScanner::ValueSize(ValueType type, const ValueVariant& value) {
    switch (type) {
        case ValueType::Int4:
        case ValueType::Int8:
        case ValueType::Int16:
        case ValueType::Int32:
        case ValueType::Int64: {
            const std::size_t bits = IntegerBitWidth(type);
            return (bits + 7) / 8;
        }
        case ValueType::Float:
            return sizeof(float);
        case ValueType::Double:
            return sizeof(double);
        case ValueType::String:
            return std::get<std::string>(value).size();
        case ValueType::CStringPointer:
            return sizeof(std::uintptr_t);
    }
    return 0;
}

bool MemoryScanner::CompareValue(ValueType type, const std::uint8_t* data, const ValueVariant& value,
                                 bool is_signed) {
    switch (type) {
        case ValueType::Int4:
            return false;
        case ValueType::Int8:
        case ValueType::Int16:
        case ValueType::Int32:
        case ValueType::Int64: {
            const std::size_t bits = IntegerBitWidth(type);
            const std::size_t bytes = (bits + 7) / 8;
            std::uint64_t raw = ReadLittleEndian(data, bytes);
            if (bits < 64) {
                const std::uint64_t mask = (static_cast<std::uint64_t>(1) << bits) - 1;
                raw &= mask;
            }
            if (is_signed) {
                const std::int64_t target = std::get<std::int64_t>(value);
                const std::int64_t candidate = SignExtend(raw, bits);
                return candidate == target;
            }
            return raw == std::get<std::uint64_t>(value);
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
        case ValueType::String: {
            const std::string& expected = std::get<std::string>(value);
            return std::memcmp(data, expected.data(), expected.size()) == 0;
        }
        case ValueType::CStringPointer: {
            std::uintptr_t candidate = 0;
            std::memcpy(&candidate, data, sizeof(candidate));
            return candidate == std::get<CStringAddress>(value).value;
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
