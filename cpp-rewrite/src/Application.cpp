#include "Application.hpp"

#include "imgui.h"
#include "backends/imgui_impl_opengl3.h"
#include "backends/imgui_impl_sdl2.h"

#include <SDL.h>
#include <SDL_opengl.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cctype>
#include <cmath>
#include <cstddef>
#include <cstdio>
#include <cstring>
#include <iomanip>
#include <limits>
#include <mutex>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

namespace cpprewrite {

enum class RegionTriState : int { Any = 0, Yes, No };

struct Application::Impl {
    SDL_Window* window = nullptr;
    SDL_GLContext gl_context = nullptr;
    ProcessMemory process;
    std::vector<ProcessInfo> processes;
    bool show_process_window = false;
    bool focus_process_window = false;
    int selected_process = -1;
    int attached_process_index = -1;
    std::string attached_process_name;
    std::string process_error_message;
    ValueType value_type = ValueType::Int32;
    bool signed_value = true;
    char value_buffer[128] = "";
    char process_filter[128] = "";
    std::vector<ScanResult> results;
    std::vector<bool> result_selection;
    int last_selected_result = -1;
    struct RegionFilter {
        RegionTriState writable = RegionTriState::Any;
        RegionTriState executable = RegionTriState::Any;
    };
    std::vector<RegionFilter> region_filters;
    char scan_start_buffer[32] = "0x0000000000000000";
    char scan_end_buffer[32] = "0x7fffffffffffffff";
    std::string range_error_message;
    std::string scan_status_message;
    std::atomic<bool> scan_in_progress{false};
    std::atomic<float> scan_progress{0.0f};
    std::atomic<bool> cancel_scan{false};
    std::thread scan_thread;
    std::mutex scan_mutex;
    std::vector<ScanResult> pending_results;
    bool pending_results_ready = false;
    bool last_scan_canceled = false;
    struct StoredEntry {
        ScanResult result;
        std::string live_value;
        bool last_read_success = false;
    };
    std::vector<StoredEntry> stored_entries;
    int editing_stored_index = -1;
    bool show_edit_window = false;
    bool focus_edit_input = false;
    char edit_value_buffer[128] = "";
    std::string edit_error_message;

    bool Initialize();
    void Shutdown();
    void RenderFrame();
    void RenderMainWindow();
    void RenderProcessWindow();
    void RenderScannerPanel();
    void RenderRegionTable();
    void RenderResultsAndStoredPanels();
    void RenderResultsTable();
    void RenderStoredValuesPanel();
    void RenderStoredEditWindow();
    void RefreshProcesses();
    void SyncRegionFilters(bool force_reset);
    void CancelScan(bool suppress_message);
    void HandleAsyncResults();
    bool ParseAddress(const char* text, std::uintptr_t& value) const;
    void EnsureSelectionSize();
    void HandleResultRowClick(std::size_t index, bool ctrl, bool shift);
    void StoreResultRow(std::size_t index);
    void StoreSelectedResults();
    void RemoveStoredRow(std::size_t index);
    void OpenStoredEditWindow(std::size_t index);
    bool ReadStoredEntryValue(StoredEntry& entry);
    void UpdateStoredEntries();
    bool WriteStoredEntryValue(StoredEntry& entry, const std::string& text);
};

Application::Application() : impl_(new Impl()) {}

Application::~Application() {
    if (impl_) {
        impl_->Shutdown();
        delete impl_;
        impl_ = nullptr;
    }
}

bool Application::Initialize() {
    return impl_->Initialize();
}

void Application::Run() {
    SDL_Event event;
    bool running = true;
    while (running) {
        while (SDL_PollEvent(&event) != 0) {
            ImGui_ImplSDL2_ProcessEvent(&event);
            if (event.type == SDL_QUIT) {
                running = false;
            }
            if (event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE &&
                event.window.windowID == SDL_GetWindowID(impl_->window)) {
                running = false;
            }
        }

        impl_->RenderFrame();
        SDL_Delay(1);
    }
}

bool Application::Impl::Initialize() {
#ifdef SDL_HINT_VIDEO_WAYLAND_PREFER_LIBDECOR
    SDL_SetHint(SDL_HINT_VIDEO_WAYLAND_PREFER_LIBDECOR, "1");
#endif
#ifdef SDL_HINT_VIDEO_WAYLAND_ALLOW_LIBDECOR
    SDL_SetHint(SDL_HINT_VIDEO_WAYLAND_ALLOW_LIBDECOR, "1");
#endif
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_GAMECONTROLLER) != 0) {
        return false;
    }

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, 0);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);

    window = SDL_CreateWindow("Cheat Engine C++ Rewrite", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                              1280, 720, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);
    if (!window) {
        return false;
    }

    gl_context = SDL_GL_CreateContext(window);
    if (!gl_context) {
        return false;
    }
    SDL_GL_MakeCurrent(window, gl_context);
    SDL_GL_SetSwapInterval(1);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui::StyleColorsDark();

    ImGui_ImplSDL2_InitForOpenGL(window, gl_context);
    ImGui_ImplOpenGL3_Init("#version 150");

    RefreshProcesses();
    return true;
}

void Application::Impl::Shutdown() {
    CancelScan(true);
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();

    if (gl_context) {
        SDL_GL_DeleteContext(gl_context);
        gl_context = nullptr;
    }
    if (window) {
        SDL_DestroyWindow(window);
        window = nullptr;
    }
    SDL_Quit();
}

void Application::Impl::RenderFrame() {
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplSDL2_NewFrame();
    ImGui::NewFrame();

    RenderMainWindow();
    if (show_process_window) {
        RenderProcessWindow();
    }

    ImGui::Render();
    ImGuiIO& io = ImGui::GetIO();
    const ImVec2 display_size = io.DisplaySize;
    const ImVec2 framebuffer_scale = io.DisplayFramebufferScale;
    const int fb_width = static_cast<int>(display_size.x * framebuffer_scale.x);
    const int fb_height = static_cast<int>(display_size.y * framebuffer_scale.y);
    glViewport(0, 0, fb_width > 0 ? fb_width : 1, fb_height > 0 ? fb_height : 1);
    glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
    SDL_GL_SwapWindow(window);
}

void Application::Impl::RenderMainWindow() {
    ImGuiIO& io = ImGui::GetIO();
    ImGui::SetNextWindowPos(ImVec2(0.0f, 0.0f));
    ImGui::SetNextWindowSize(io.DisplaySize);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowRounding, 0.0f);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0f);
    ImGuiWindowFlags flags = ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove |
                            ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_NoResize |
                            ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_MenuBar;
    if (ImGui::Begin("Cheat Engine##MainWindow", nullptr, flags)) {
        if (ImGui::BeginMenuBar()) {
            if (ImGui::BeginMenu("File")) {
                if (ImGui::MenuItem("Refresh Processes")) {
                    RefreshProcesses();
                }
                bool should_quit = false;
                if (ImGui::MenuItem("Quit")) {
                    should_quit = true;
                }
                ImGui::EndMenu();
                if (should_quit) {
                    SDL_Event quit_event{};
                    quit_event.type = SDL_QUIT;
                    SDL_PushEvent(&quit_event);
                }
            }
            ImGui::EndMenuBar();
        }

        ImGui::BeginChild("ScannerPanel", ImVec2(0.0f, 0.0f), true);
        RenderScannerPanel();
        ImGui::EndChild();
    }
    ImGui::End();
    ImGui::PopStyleVar(2);
}

namespace {

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

bool ParseIntegerForType(const std::string& text, std::size_t bits, bool is_signed,
                         std::uint64_t& raw_value) {
    if (text.empty() || bits == 0) {
        return false;
    }

    try {
        std::size_t processed = 0;
        if (is_signed) {
            long long parsed = std::stoll(text, &processed, 0);
            if (processed != text.size()) {
                return false;
            }
            if (bits < 64) {
                const long long min_value = -(1LL << (bits - 1));
                const long long max_value = (1LL << (bits - 1)) - 1;
                if (parsed < min_value || parsed > max_value) {
                    return false;
                }
            }
            raw_value = static_cast<std::uint64_t>(static_cast<std::int64_t>(parsed));
        } else {
            unsigned long long parsed = std::stoull(text, &processed, 0);
            if (processed != text.size()) {
                return false;
            }
            if (bits < 64) {
                const unsigned long long max_value = (1ULL << bits) - 1;
                if (parsed > max_value) {
                    return false;
                }
            }
            raw_value = static_cast<std::uint64_t>(parsed);
        }
    } catch (...) {
        return false;
    }

    if (bits < 64) {
        const std::uint64_t mask = (static_cast<std::uint64_t>(1) << bits) - 1;
        raw_value &= mask;
    }
    return true;
}

const char* ValueTypeName(ValueType type) {
    switch (type) {
        case ValueType::Int4:
            return "Int4";
        case ValueType::Int8:
            return "Int8";
        case ValueType::Int16:
            return "Int16";
        case ValueType::Int32:
            return "Int32";
        case ValueType::Int64:
            return "Int64";
        case ValueType::Float:
            return "Float";
        case ValueType::Double:
            return "Double";
        case ValueType::String:
            return "String";
        case ValueType::CStringPointer:
            return "char*";
    }
    return "Unknown";
}

RegionTriState NextState(RegionTriState state) {
    switch (state) {
        case RegionTriState::Any:
            return RegionTriState::Yes;
        case RegionTriState::Yes:
            return RegionTriState::No;
        case RegionTriState::No:
        default:
            return RegionTriState::Any;
    }
}

bool MatchesTriState(bool value, RegionTriState state) {
    switch (state) {
        case RegionTriState::Any:
            return true;
        case RegionTriState::Yes:
            return value;
        case RegionTriState::No:
            return !value;
    }
    return true;
}

void RenderTriStateCheckbox(const char* label, RegionTriState& state) {
    bool value = state == RegionTriState::Yes;
    bool toggled = ImGui::Checkbox(label, &value);

    if (state == RegionTriState::Any) {
        ImDrawList* draw_list = ImGui::GetWindowDrawList();
        const ImVec2 rect_min = ImGui::GetItemRectMin();
        const float height = ImGui::GetItemRectSize().y;
        const ImGuiStyle& style = ImGui::GetStyle();
        const float square_padding = style.FramePadding.y;
        const float square_size = height - square_padding * 2.0f;
        ImVec2 square_min(rect_min.x + style.FramePadding.x, rect_min.y + square_padding);
        ImVec2 square_max(square_min.x + square_size, square_min.y + square_size);
        const ImU32 color = ImGui::GetColorU32(ImGuiCol_CheckMark);
        draw_list->AddRectFilled(square_min, square_max, color, style.FrameRounding);
    }

    if (toggled) {
        state = NextState(state);
    }
}

bool IsIntegerType(ValueType type) {
    switch (type) {
        case ValueType::Int4:
        case ValueType::Int8:
        case ValueType::Int16:
        case ValueType::Int32:
        case ValueType::Int64:
            return true;
        default:
            return false;
    }
}

}  // namespace

void Application::Impl::RenderProcessWindow() {
    if (focus_process_window) {
        ImGui::SetNextWindowFocus();
        focus_process_window = false;
    }
    ImGui::SetNextWindowSize(ImVec2(380.0f, 520.0f), ImGuiCond_FirstUseEver);

    if (selected_process < 0 || selected_process >= static_cast<int>(processes.size())) {
        selected_process = attached_process_index;
    }

    ImGuiWindowFlags flags = ImGuiWindowFlags_NoCollapse;
    bool open = show_process_window;
    if (!ImGui::Begin("Processes", &open, flags)) {
        ImGui::End();
        show_process_window = open;
        return;
    }
    show_process_window = open;

    if (!ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows)) {
        ImGui::SetWindowFocus();
    }

    if (ImGui::Button("Refresh")) {
        RefreshProcesses();
    }
    ImGui::SameLine();
    ImGui::SetNextItemWidth(-1.0f);
    ImGui::InputTextWithHint("##ProcessSearch", "Search by name or PID", process_filter,
                             IM_ARRAYSIZE(process_filter));

    ImGui::Separator();

    std::string filter_text(process_filter);
    std::string filter_lower = filter_text;
    std::transform(filter_lower.begin(), filter_lower.end(), filter_lower.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });

    ImGui::BeginChild("ProcessList", ImVec2(0.0f, -ImGui::GetFrameHeightWithSpacing() * 2.0f), true);
    for (std::size_t i = 0; i < processes.size(); ++i) {
        const ProcessInfo& info = processes[i];
        bool matches = true;
        if (!filter_lower.empty()) {
            std::string name_lower = info.name;
            std::transform(name_lower.begin(), name_lower.end(), name_lower.begin(),
                           [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
            const std::string pid_text = std::to_string(info.pid);
            std::string pid_lower = pid_text;
            std::transform(pid_lower.begin(), pid_lower.end(), pid_lower.begin(),
                           [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
            matches = name_lower.find(filter_lower) != std::string::npos ||
                      pid_lower.find(filter_lower) != std::string::npos;
        }
        if (!matches) {
            continue;
        }

        std::string label = std::to_string(info.pid) + " - " + info.name;
        if (ImGui::Selectable(label.c_str(), selected_process == static_cast<int>(i))) {
            selected_process = static_cast<int>(i);
            process_error_message.clear();
        }
    }
    ImGui::EndChild();

    if (!process.is_open()) {
        ImGui::TextWrapped(
            "Select a process to begin scanning. Reading another process's memory usually requires elevated privileges.");
    } else {
        if (!attached_process_name.empty()) {
            ImGui::Text("Currently attached: %s (PID %d)", attached_process_name.c_str(), process.pid());
        } else {
            ImGui::Text("Currently attached PID %d", process.pid());
        }
    }

    bool can_attach = selected_process >= 0 && selected_process < static_cast<int>(processes.size());
    ImGui::BeginDisabled(!can_attach);
    if (ImGui::Button("Attach to Selected")) {
        const ProcessInfo& info = processes[selected_process];
        CancelScan(true);
        if (process.open(info.pid)) {
            attached_process_index = selected_process;
            attached_process_name = info.name;
            process.refresh_regions();
            SyncRegionFilters(true);
            results.clear();
            result_selection.clear();
            last_selected_result = -1;
            stored_entries.clear();
            show_edit_window = false;
            editing_stored_index = -1;
            process_error_message.clear();
            show_process_window = false;
            scan_status_message.clear();
            range_error_message.clear();
        } else {
            process_error_message = "Failed to open process. Try running with elevated permissions.";
        }
    }
    ImGui::EndDisabled();
    ImGui::SameLine();
    if (ImGui::Button("Close")) {
        show_process_window = false;
    }

    if (!process_error_message.empty()) {
        ImGui::Spacing();
        ImGui::TextWrapped("%s", process_error_message.c_str());
    }

    ImGui::End();
}

void Application::Impl::RenderScannerPanel() {
    HandleAsyncResults();

    if (ImGui::Button("Select Process...")) {
        show_process_window = true;
        focus_process_window = true;
        process_error_message.clear();
    }
    ImGui::SameLine();
    if (process.is_open()) {
        if (!attached_process_name.empty()) {
            ImGui::Text("Attached: %s (PID %d)", attached_process_name.c_str(), process.pid());
        } else {
            ImGui::Text("Attached PID %d", process.pid());
        }
    } else {
        ImGui::TextDisabled("No process attached");
    }

    ImGui::Separator();

    static const char* value_labels[] = {"Int4",  "Int8",  "Int16", "Int32", "Int64",
                                         "Float", "Double", "String", "Char*"};
    int current_type = static_cast<int>(value_type);
    if (ImGui::Combo("Value Type", &current_type, value_labels, IM_ARRAYSIZE(value_labels))) {
        value_type = static_cast<ValueType>(current_type);
    }

    const bool is_integer = IsIntegerType(value_type);
    ImGui::BeginDisabled(!is_integer);
    ImGui::Checkbox("Signed", &signed_value);
    ImGui::EndDisabled();

    ImGui::InputText("Value", value_buffer, sizeof(value_buffer));
    RenderRegionTable();
    ImGui::InputText("Start Address", scan_start_buffer, IM_ARRAYSIZE(scan_start_buffer));
    ImGui::InputText("End Address", scan_end_buffer, IM_ARRAYSIZE(scan_end_buffer));
    if (!range_error_message.empty()) {
        ImGui::TextColored(ImVec4(1.0f, 0.4f, 0.4f, 1.0f), "%s", range_error_message.c_str());
    }

    const bool scanning = scan_in_progress.load();
    const bool can_scan = process.is_open() && !scanning;
    if (process.is_open()) {
        SyncRegionFilters(false);
    }
    ImGui::BeginDisabled(!can_scan);
    if (ImGui::Button("New Scan")) {
        range_error_message.clear();
        scan_status_message.clear();

        std::uintptr_t start_address = 0;
        std::uintptr_t end_address = 0;
        const bool start_valid = ParseAddress(scan_start_buffer, start_address);
        const bool end_valid = ParseAddress(scan_end_buffer, end_address);
        if (!start_valid) {
            range_error_message = "Invalid start address.";
        } else if (!end_valid) {
            range_error_message = "Invalid end address.";
        } else if (start_address > end_address) {
            range_error_message = "Start address must be less than or equal to end address.";
        } else {
            ScanRequest request;
            request.type = value_type;
            request.value_text = value_buffer;
            request.is_signed = signed_value;
            request.start_address = start_address;
            request.end_address = end_address;
            request.region_selection.clear();
            request.region_selection.resize(process.regions().size());
            for (std::size_t i = 0; i < process.regions().size(); ++i) {
                const MemoryRegion& region = process.regions()[i];
                bool include = false;
                if (region.readable()) {
                    if (i < region_filters.size()) {
                        include = MatchesTriState(region.writable(), region_filters[i].writable) &&
                                  MatchesTriState(region.executable(), region_filters[i].executable);
                    } else {
                        include = true;
                    }
                }
                request.region_selection[i] = include;
            }

            CancelScan(true);

            {
                std::lock_guard<std::mutex> lock(scan_mutex);
                pending_results.clear();
                pending_results_ready = false;
                last_scan_canceled = false;
            }

            results.clear();
            result_selection.clear();
            last_selected_result = -1;
            cancel_scan.store(false);
            scan_in_progress.store(true);
            scan_progress.store(0.0f);

            scan_thread = std::thread([this, request]() mutable {
                MemoryScanner scanner(process);
                auto progress_cb = [this](std::size_t processed, std::size_t total) {
                    float progress = 0.0f;
                    if (total > 0) {
                        progress = static_cast<float>(processed) / static_cast<float>(total);
                    }
                    progress = std::clamp(progress, 0.0f, 1.0f);
                    scan_progress.store(progress);
                };

                std::vector<ScanResult> thread_results =
                    scanner.PerformScan(request, progress_cb, &cancel_scan);
                const bool canceled = cancel_scan.load();
                if (!canceled) {
                    std::lock_guard<std::mutex> lock(scan_mutex);
                    pending_results = std::move(thread_results);
                    pending_results_ready = true;
                    last_scan_canceled = false;
                } else {
                    std::lock_guard<std::mutex> lock(scan_mutex);
                    pending_results.clear();
                    pending_results_ready = false;
                    last_scan_canceled = true;
                }

                if (canceled) {
                    scan_progress.store(0.0f);
                } else {
                    scan_progress.store(1.0f);
                }
                scan_in_progress.store(false);
            });
        }
    }
    ImGui::EndDisabled();

    if (scanning) {
        float progress = scan_progress.load();
        progress = std::clamp(progress, 0.0f, 1.0f);
        ImGui::ProgressBar(progress, ImVec2(-FLT_MIN, 0.0f));
    } else if (!scan_status_message.empty()) {
        ImGui::TextUnformatted(scan_status_message.c_str());
    }

    if (!process.is_open()) {
        ImGui::TextWrapped(
            "Attach to a process from the Processes window to configure memory region filters and run scans.");
    }

    RenderResultsAndStoredPanels();
}

void Application::Impl::RenderRegionTable() {
    std::string preview_label = "Attach to a process";
    std::size_t total_selectable = 0;
    std::size_t included_regions = 0;

    if (process.is_open()) {
        SyncRegionFilters(false);

        const auto& regions = process.regions();
        for (std::size_t i = 0; i < regions.size(); ++i) {
            const MemoryRegion& region = regions[i];
            if (!region.readable()) {
                continue;
            }
            ++total_selectable;
            if (MatchesTriState(region.writable(), region_filters[i].writable) &&
                MatchesTriState(region.executable(), region_filters[i].executable)) {
                ++included_regions;
            }
        }

        if (total_selectable == 0) {
            preview_label = "No readable regions";
        } else if (included_regions == 0) {
            preview_label = "No regions selected";
        } else if (included_regions == total_selectable) {
            preview_label = "All regions";
        } else {
            preview_label = std::to_string(included_regions) + " of " + std::to_string(total_selectable) + " regions";
        }
    }

    ImGui::SetNextItemWidth(-FLT_MIN);
    const bool disable_combo = !process.is_open();
    if (disable_combo) {
        ImGui::BeginDisabled(true);
    }

    if (ImGui::BeginCombo("Regions", preview_label.c_str())) {
        if (!process.is_open()) {
            ImGui::TextDisabled("Attach to a process to configure regions.");
        } else {
            const auto& regions = process.regions();
            if (total_selectable == 0) {
                ImGui::TextDisabled("No readable regions detected.");
            } else {
                const bool all_selected = included_regions == total_selectable;
                if (ImGui::Selectable("All", all_selected)) {
                    const bool enable_all = !all_selected;
                    for (std::size_t i = 0; i < regions.size(); ++i) {
                        if (!regions[i].readable()) {
                            continue;
                        }
                        if (enable_all) {
                            region_filters[i].writable = RegionTriState::Any;
                            region_filters[i].executable = RegionTriState::Any;
                        } else {
                            region_filters[i].writable =
                                regions[i].writable() ? RegionTriState::No : RegionTriState::Yes;
                            region_filters[i].executable = RegionTriState::Any;
                        }
                    }
                }
                if (all_selected) {
                    ImGui::SetItemDefaultFocus();
                }
                ImGui::Separator();

                if (ImGui::BeginTable("RegionSelectionTable", 6,
                                      ImGuiTableFlags_Borders | ImGuiTableFlags_RowBg |
                                          ImGuiTableFlags_Resizable | ImGuiTableFlags_ScrollY,
                                      ImVec2(0.0f, ImGui::GetFontSize() * 12.0f))) {
                    ImGui::TableSetupColumn("Writable", ImGuiTableColumnFlags_WidthFixed,
                                            ImGui::GetFontSize() * 4.5f);
                    ImGui::TableSetupColumn("Executable", ImGuiTableColumnFlags_WidthFixed,
                                            ImGui::GetFontSize() * 5.0f);
                    ImGui::TableSetupColumn("Start", ImGuiTableColumnFlags_WidthFixed,
                                            ImGui::GetFontSize() * 9.0f);
                    ImGui::TableSetupColumn("End", ImGuiTableColumnFlags_WidthFixed,
                                            ImGui::GetFontSize() * 9.0f);
                    ImGui::TableSetupColumn("Perms", ImGuiTableColumnFlags_WidthFixed,
                                            ImGui::GetFontSize() * 5.0f);
                    ImGui::TableSetupColumn("Path", ImGuiTableColumnFlags_WidthStretch);
                    ImGui::TableHeadersRow();

                    for (std::size_t i = 0; i < regions.size(); ++i) {
                        const MemoryRegion& region = regions[i];
                        ImGui::PushID(static_cast<int>(i));
                        ImGui::TableNextRow();

                        const bool readable = region.readable();
                        const bool included = readable &&
                                              MatchesTriState(region.writable(), region_filters[i].writable) &&
                                              MatchesTriState(region.executable(), region_filters[i].executable);

                        if (!included) {
                            const ImU32 dim_color = ImGui::GetColorU32(ImVec4(0.25f, 0.18f, 0.18f, 0.35f));
                            ImGui::TableSetBgColor(ImGuiTableBgTarget_RowBg0, dim_color);
                        }

                        ImGui::TableSetColumnIndex(0);
                        ImGui::BeginDisabled(!readable);
                        RenderTriStateCheckbox("##Writable", region_filters[i].writable);
                        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) {
                            ImGui::SetTooltip("Cycle between Any, Yes, and No to include or exclude writable regions.");
                        }
                        ImGui::EndDisabled();

                        ImGui::TableSetColumnIndex(1);
                        ImGui::BeginDisabled(!readable);
                        RenderTriStateCheckbox("##Executable", region_filters[i].executable);
                        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) {
                            ImGui::SetTooltip(
                                "Cycle between Any, Yes, and No to include or exclude executable regions.");
                        }
                        ImGui::EndDisabled();

                        ImGui::TableSetColumnIndex(2);
                        ImGui::Text("%p", reinterpret_cast<void*>(region.start));

                        ImGui::TableSetColumnIndex(3);
                        ImGui::Text("%p", reinterpret_cast<void*>(region.end));

                        ImGui::TableSetColumnIndex(4);
                        ImGui::TextUnformatted(region.permissions.c_str());

                        ImGui::TableSetColumnIndex(5);
                        if (!region.pathname.empty()) {
                            ImGui::TextUnformatted(region.pathname.c_str());
                        } else {
                            ImGui::TextDisabled("<anonymous>");
                        }

                        ImGui::PopID();
                    }

                    ImGui::EndTable();
                }
            }
        }
        ImGui::EndCombo();
    }

    if (disable_combo) {
        ImGui::EndDisabled();
    }
}

void Application::Impl::RenderResultsAndStoredPanels() {
    ImGui::Separator();
    UpdateStoredEntries();

    const float total_width = ImGui::GetContentRegionAvail().x;
    if (total_width <= 0.0f) {
        RenderResultsTable();
        RenderStoredEditWindow();
        return;
    }

    ImGui::Columns(2, "ResultsStoredColumns", false);
    ImGui::SetColumnWidth(0, total_width * 0.55f);

    RenderResultsTable();

    ImGui::NextColumn();
    RenderStoredValuesPanel();

    ImGui::Columns(1);
    RenderStoredEditWindow();
}

void Application::Impl::RenderResultsTable() {
    EnsureSelectionSize();

    ImGui::Text("Results: %zu", results.size());
    ImGui::SameLine();
    const bool has_selection = std::any_of(result_selection.begin(), result_selection.end(), [](bool selected) {
        return selected;
    });
    if (!has_selection) {
        ImGui::BeginDisabled(true);
    }
    if (ImGui::Button("Store Selected")) {
        StoreSelectedResults();
    }
    if (!has_selection) {
        ImGui::EndDisabled();
    }

    if (results.empty()) {
        ImGui::Spacing();
        ImGui::TextDisabled("Run a scan to populate results.");
        return;
    }

    ImGui::TextDisabled("Ctrl-click to toggle, Shift-click to extend selection. Double-click to store.");

    const ImGuiTableFlags table_flags = ImGuiTableFlags_Borders | ImGuiTableFlags_RowBg |
                                        ImGuiTableFlags_Resizable | ImGuiTableFlags_ScrollY;
    if (ImGui::BeginTable("ResultsTable", 5, table_flags)) {
        ImGui::TableSetupColumn("Address", ImGuiTableColumnFlags_WidthFixed, ImGui::GetFontSize() * 10.0f);
        ImGui::TableSetupColumn("Bit Offset", ImGuiTableColumnFlags_WidthFixed, ImGui::GetFontSize() * 5.0f);
        ImGui::TableSetupColumn("Value", ImGuiTableColumnFlags_WidthFixed, ImGui::GetFontSize() * 8.0f);
        ImGui::TableSetupColumn("Bytes", ImGuiTableColumnFlags_WidthStretch);
        ImGui::TableSetupColumn("Region", ImGuiTableColumnFlags_WidthStretch);
        ImGui::TableHeadersRow();

        const float row_height = ImGui::GetTextLineHeightWithSpacing();
        for (std::size_t i = 0; i < results.size(); ++i) {
            const ScanResult& result = results[i];
            ImGui::PushID(static_cast<int>(i));
            ImGui::TableNextRow();
            ImGui::TableSetColumnIndex(0);

            bool row_selected = result_selection[i];
            ImGuiSelectableFlags selectable_flags =
                ImGuiSelectableFlags_SpanAllColumns | ImGuiSelectableFlags_AllowOverlap;
            if (ImGui::Selectable("##ResultRow", row_selected, selectable_flags, ImVec2(0.0f, row_height))) {
                const ImGuiIO& io = ImGui::GetIO();
                HandleResultRowClick(i, io.KeyCtrl, io.KeyShift);
            }
            if (ImGui::IsItemHovered() && ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left)) {
                StoreResultRow(i);
            }

            ImGui::SameLine(0.0f, 0.0f);
            ImGui::Text("0x%lx", static_cast<unsigned long>(result.address));

            ImGui::TableSetColumnIndex(1);
            if (result.bit_offset != 0) {
                ImGui::Text("%zu", result.bit_offset);
            } else {
                ImGui::TextUnformatted("-");
            }

            ImGui::TableSetColumnIndex(2);
            if (!result.display_value.empty()) {
                ImGui::TextUnformatted(result.display_value.c_str());
            } else {
                ImGui::TextUnformatted("-");
            }

            ImGui::TableSetColumnIndex(3);
            std::string byte_string;
            for (std::uint8_t byte : result.bytes) {
                char buffer[4];
                std::snprintf(buffer, sizeof(buffer), "%02X ", byte);
                byte_string += buffer;
            }
            ImGui::TextUnformatted(byte_string.c_str());

            ImGui::TableSetColumnIndex(4);
            const MemoryRegion* containing_region = nullptr;
            for (const auto& region : process.regions()) {
                if (result.address >= region.start && result.address < region.end) {
                    containing_region = &region;
                    break;
                }
            }
            if (containing_region) {
                ImGui::Text("%p-%p %s", reinterpret_cast<void*>(containing_region->start),
                            reinterpret_cast<void*>(containing_region->end),
                            containing_region->pathname.c_str());
            } else {
                ImGui::TextUnformatted("?");
            }

            ImGui::PopID();
        }
        ImGui::EndTable();
    }
}

void Application::Impl::RenderStoredValuesPanel() {
    ImGui::Text("Stored Values: %zu", stored_entries.size());
    if (!process.is_open()) {
        ImGui::SameLine();
        ImGui::TextDisabled("(attach to edit)");
    } else if (!process.can_write()) {
        ImGui::SameLine();
        ImGui::TextDisabled("(process opened read-only)");
    }

    if (stored_entries.empty()) {
        ImGui::Spacing();
        ImGui::TextDisabled("Double-click a result or use Store Selected to pin values here.");
        return;
    }

    const ImGuiTableFlags table_flags = ImGuiTableFlags_Borders | ImGuiTableFlags_RowBg |
                                        ImGuiTableFlags_Resizable | ImGuiTableFlags_ScrollY;
    if (ImGui::BeginTable("StoredValuesTable", 5, table_flags)) {
        ImGui::TableSetupColumn("Address", ImGuiTableColumnFlags_WidthFixed, ImGui::GetFontSize() * 10.0f);
        ImGui::TableSetupColumn("Value", ImGuiTableColumnFlags_WidthStretch);
        ImGui::TableSetupColumn("Type", ImGuiTableColumnFlags_WidthFixed, ImGui::GetFontSize() * 6.0f);
        ImGui::TableSetupColumn("Bit Offset", ImGuiTableColumnFlags_WidthFixed, ImGui::GetFontSize() * 5.0f);
        ImGui::TableSetupColumn("Actions", ImGuiTableColumnFlags_WidthFixed, ImGui::GetFontSize() * 5.0f);
        ImGui::TableHeadersRow();

        const float row_height = ImGui::GetTextLineHeightWithSpacing();
        for (std::size_t i = 0; i < stored_entries.size(); ++i) {
            StoredEntry& entry = stored_entries[i];
            ImGui::PushID(static_cast<int>(i));
            ImGui::TableNextRow();

            ImGui::TableSetColumnIndex(0);
            ImGuiSelectableFlags selectable_flags =
                ImGuiSelectableFlags_SpanAllColumns | ImGuiSelectableFlags_AllowOverlap;
            ImGui::Selectable("##StoredRow", false, selectable_flags, ImVec2(0.0f, row_height));
            if (ImGui::IsItemHovered() && ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left)) {
                OpenStoredEditWindow(i);
            }
            ImGui::SameLine(0.0f, 0.0f);
            ImGui::Text("0x%lx", static_cast<unsigned long>(entry.result.address));

            ImGui::TableSetColumnIndex(1);
            if (entry.last_read_success) {
                ImGui::TextUnformatted(entry.live_value.c_str());
            } else if (!process.is_open()) {
                ImGui::TextDisabled("<detached>");
            } else {
                ImGui::TextDisabled("<unreadable>");
            }

            ImGui::TableSetColumnIndex(2);
            std::string type_label = ValueTypeName(entry.result.type);
            if (IsIntegerType(entry.result.type)) {
                type_label += entry.result.is_signed ? " (signed)" : " (unsigned)";
            }
            ImGui::TextUnformatted(type_label.c_str());

            ImGui::TableSetColumnIndex(3);
            if (entry.result.type == ValueType::Int4) {
                ImGui::Text("%zu", entry.result.bit_offset);
            } else {
                ImGui::TextUnformatted("-");
            }

            ImGui::TableSetColumnIndex(4);
            if (ImGui::SmallButton("Remove")) {
                RemoveStoredRow(i);
                ImGui::PopID();
                ImGui::EndTable();
                return;
            }

            ImGui::PopID();
        }
        ImGui::EndTable();
    }
}

void Application::Impl::RenderStoredEditWindow() {
    if (!show_edit_window || editing_stored_index < 0 ||
        editing_stored_index >= static_cast<int>(stored_entries.size())) {
        show_edit_window = false;
        editing_stored_index = -1;
        return;
    }

    StoredEntry& entry = stored_entries[editing_stored_index];

    if (focus_edit_input) {
        ImGui::SetNextWindowFocus();
    }

    ImGui::SetNextWindowSize(ImVec2(320.0f, 0.0f), ImGuiCond_FirstUseEver);
    if (!ImGui::Begin("Edit Value", &show_edit_window, ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::End();
        return;
    }

    ImGui::Text("Address: 0x%lx", static_cast<unsigned long>(entry.result.address));
    ImGui::Text("Type: %s", ValueTypeName(entry.result.type));
    if (IsIntegerType(entry.result.type)) {
        ImGui::SameLine();
        ImGui::Text("(%s)", entry.result.is_signed ? "signed" : "unsigned");
    }
    if (entry.result.type == ValueType::Int4) {
        ImGui::Text("Bit Offset: %zu", entry.result.bit_offset);
    }

    if (!process.can_write()) {
        ImGui::TextDisabled("Process memory is read-only; editing is unavailable.");
    }

    if (focus_edit_input) {
        ImGui::SetKeyboardFocusHere();
        focus_edit_input = false;
    }

    const ImGuiInputTextFlags flags = ImGuiInputTextFlags_EnterReturnsTrue;
    if (!process.can_write()) {
        ImGui::BeginDisabled(true);
    }
    if (ImGui::InputText("##EditStoredValue", edit_value_buffer, IM_ARRAYSIZE(edit_value_buffer), flags)) {
        if (WriteStoredEntryValue(entry, edit_value_buffer)) {
            show_edit_window = false;
            editing_stored_index = -1;
            edit_error_message.clear();
        } else {
            edit_error_message = "Failed to write value.";
        }
    }
    if (!process.can_write()) {
        ImGui::EndDisabled();
    }

    if (!edit_error_message.empty()) {
        ImGui::TextColored(ImVec4(0.9f, 0.4f, 0.4f, 1.0f), "%s", edit_error_message.c_str());
    }

    if (!ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows)) {
        show_edit_window = false;
        editing_stored_index = -1;
        edit_error_message.clear();
        edit_value_buffer[0] = '\0';
    }

    ImGui::End();
}

void Application::Impl::EnsureSelectionSize() {
    if (result_selection.size() != results.size()) {
        result_selection.assign(results.size(), false);
        last_selected_result = -1;
    }
}

void Application::Impl::HandleResultRowClick(std::size_t index, bool ctrl, bool shift) {
    EnsureSelectionSize();
    if (index >= result_selection.size()) {
        return;
    }

    if (shift && last_selected_result >= 0 && last_selected_result < static_cast<int>(result_selection.size())) {
        std::size_t anchor = static_cast<std::size_t>(last_selected_result);
        if (!ctrl) {
            std::fill(result_selection.begin(), result_selection.end(), false);
        }
        std::size_t begin = std::min(anchor, index);
        std::size_t end = std::max(anchor, index);
        for (std::size_t i = begin; i <= end; ++i) {
            result_selection[i] = true;
        }
    } else if (ctrl) {
        result_selection[index] = !result_selection[index];
        last_selected_result = static_cast<int>(index);
    } else {
        std::fill(result_selection.begin(), result_selection.end(), false);
        result_selection[index] = true;
        last_selected_result = static_cast<int>(index);
    }
}

void Application::Impl::StoreResultRow(std::size_t index) {
    if (index >= results.size()) {
        return;
    }

    const ScanResult& result = results[index];
    auto existing = std::find_if(stored_entries.begin(), stored_entries.end(), [&](const StoredEntry& entry) {
        return entry.result.address == result.address && entry.result.bit_offset == result.bit_offset &&
               entry.result.type == result.type && entry.result.is_signed == result.is_signed;
    });
    if (existing != stored_entries.end()) {
        return;
    }

    StoredEntry entry;
    entry.result = result;
    entry.live_value = result.display_value;
    entry.last_read_success = true;
    stored_entries.push_back(std::move(entry));
}

void Application::Impl::StoreSelectedResults() {
    EnsureSelectionSize();
    for (std::size_t i = 0; i < results.size(); ++i) {
        if (result_selection[i]) {
            StoreResultRow(i);
        }
    }
}

void Application::Impl::RemoveStoredRow(std::size_t index) {
    if (index >= stored_entries.size()) {
        return;
    }

    if (editing_stored_index == static_cast<int>(index)) {
        show_edit_window = false;
        editing_stored_index = -1;
        edit_error_message.clear();
        edit_value_buffer[0] = '\0';
    } else if (editing_stored_index > static_cast<int>(index)) {
        --editing_stored_index;
    }

    stored_entries.erase(stored_entries.begin() + static_cast<std::ptrdiff_t>(index));
}

void Application::Impl::OpenStoredEditWindow(std::size_t index) {
    if (index >= stored_entries.size()) {
        return;
    }

    StoredEntry& entry = stored_entries[index];
    ReadStoredEntryValue(entry);
    editing_stored_index = static_cast<int>(index);
    show_edit_window = true;
    focus_edit_input = true;
    edit_error_message.clear();
    if (entry.last_read_success) {
        std::snprintf(edit_value_buffer, sizeof(edit_value_buffer), "%s", entry.live_value.c_str());
    } else {
        edit_value_buffer[0] = '\0';
    }
}

bool Application::Impl::ReadStoredEntryValue(StoredEntry& entry) {
    if (!process.is_open()) {
        entry.last_read_success = false;
        return false;
    }

    const ValueType type = entry.result.type;
    const std::size_t value_size = entry.result.value_size != 0 ? entry.result.value_size : entry.result.bytes.size();

    if (type == ValueType::Int4) {
        std::uint8_t byte = 0;
        if (!process.read(entry.result.address, &byte, 1)) {
            entry.last_read_success = false;
            return false;
        }
        std::uint8_t nibble = (byte >> entry.result.bit_offset) & 0x0F;
        entry.result.bytes = {nibble};
        entry.live_value = FormatIntegerString(nibble, IntegerBitWidth(ValueType::Int4), entry.result.is_signed);
        entry.result.display_value = entry.live_value;
        entry.last_read_success = true;
        return true;
    }

    if (value_size == 0) {
        entry.last_read_success = false;
        return false;
    }

    std::vector<std::uint8_t> buffer(value_size);
    if (!process.read(entry.result.address, buffer.data(), buffer.size())) {
        entry.last_read_success = false;
        return false;
    }

    entry.result.bytes = buffer;
    entry.live_value = FormatResultValue(type, buffer.data(), buffer.size(), entry.result.is_signed);
    entry.result.display_value = entry.live_value;
    entry.last_read_success = true;
    return true;
}

void Application::Impl::UpdateStoredEntries() {
    for (auto& entry : stored_entries) {
        if (!ReadStoredEntryValue(entry)) {
            entry.live_value.clear();
        }
    }
}

bool Application::Impl::WriteStoredEntryValue(StoredEntry& entry, const std::string& text) {
    if (!process.is_open() || !process.can_write()) {
        return false;
    }

    const ValueType type = entry.result.type;
    switch (type) {
        case ValueType::Int4:
        case ValueType::Int8:
        case ValueType::Int16:
        case ValueType::Int32:
        case ValueType::Int64: {
            const std::size_t bits = IntegerBitWidth(type);
            std::uint64_t raw = 0;
            if (!ParseIntegerForType(text, bits, entry.result.is_signed, raw)) {
                return false;
            }

            if (type == ValueType::Int4) {
                std::uint8_t byte = 0;
                if (!process.read(entry.result.address, &byte, 1)) {
                    return false;
                }
                std::uint8_t nibble = static_cast<std::uint8_t>(raw & 0x0F);
                if (entry.result.bit_offset == 0) {
                    byte = static_cast<std::uint8_t>((byte & 0xF0) | nibble);
                } else {
                    byte = static_cast<std::uint8_t>((byte & 0x0F) | (nibble << 4));
                }
                if (!process.write(entry.result.address, &byte, 1)) {
                    return false;
                }
            } else {
                std::size_t bytes = entry.result.value_size != 0 ? entry.result.value_size : entry.result.bytes.size();
                if (bytes == 0) {
                    return false;
                }
                std::vector<std::uint8_t> buffer(bytes);
                for (std::size_t i = 0; i < bytes; ++i) {
                    buffer[i] = static_cast<std::uint8_t>((raw >> (i * 8)) & 0xFFU);
                }
                if (!process.write(entry.result.address, buffer.data(), buffer.size())) {
                    return false;
                }
            }
            break;
        }
        case ValueType::Float: {
            try {
                float value = std::stof(text);
                if (!std::isfinite(value)) {
                    return false;
                }
                if (!process.write_value(entry.result.address, value)) {
                    return false;
                }
            } catch (...) {
                return false;
            }
            break;
        }
        case ValueType::Double: {
            try {
                double value = std::stod(text);
                if (!std::isfinite(value)) {
                    return false;
                }
                if (!process.write_value(entry.result.address, value)) {
                    return false;
                }
            } catch (...) {
                return false;
            }
            break;
        }
        case ValueType::String: {
            std::size_t bytes = entry.result.value_size != 0 ? entry.result.value_size : entry.result.bytes.size();
            if (bytes == 0) {
                return false;
            }
            std::vector<char> buffer(bytes, '\0');
            std::size_t copy = std::min(bytes, text.size());
            std::memcpy(buffer.data(), text.data(), copy);
            if (!process.write(entry.result.address, buffer.data(), buffer.size())) {
                return false;
            }
            break;
        }
        case ValueType::CStringPointer: {
            try {
                std::size_t processed = 0;
                unsigned long long value = std::stoull(text, &processed, 0);
                if (processed != text.size()) {
                    return false;
                }
                std::uintptr_t pointer_value = static_cast<std::uintptr_t>(value);
                if (!process.write_value(entry.result.address, pointer_value)) {
                    return false;
                }
            } catch (...) {
                return false;
            }
            break;
        }
    }

    ReadStoredEntryValue(entry);
    return true;
}

void Application::Impl::CancelScan(bool suppress_message) {
    const bool was_running = scan_in_progress.load();
    if (was_running) {
        cancel_scan.store(true);
    }
    if (scan_thread.joinable()) {
        scan_thread.join();
        scan_thread = std::thread();
    }
    cancel_scan.store(false);
    scan_in_progress.store(false);
    scan_progress.store(0.0f);

    {
        std::lock_guard<std::mutex> lock(scan_mutex);
        pending_results.clear();
        pending_results_ready = false;
        last_scan_canceled = (!suppress_message && was_running);
    }

    if (!suppress_message && was_running) {
        scan_status_message = "Scan canceled.";
    } else if (suppress_message) {
        scan_status_message.clear();
    }
}

void Application::Impl::HandleAsyncResults() {
    if (!scan_in_progress.load() && scan_thread.joinable()) {
        scan_thread.join();
        scan_thread = std::thread();
    }

    std::vector<ScanResult> new_results;
    bool apply_results = false;
    bool canceled = false;

    {
        std::lock_guard<std::mutex> lock(scan_mutex);
        if (pending_results_ready) {
            new_results = std::move(pending_results);
            pending_results.clear();
            pending_results_ready = false;
            apply_results = true;
        }
        if (last_scan_canceled) {
            canceled = true;
            last_scan_canceled = false;
        }
    }

    if (apply_results) {
        results = std::move(new_results);
        result_selection.assign(results.size(), false);
        last_selected_result = -1;
        scan_status_message = "Scan complete.";
    } else if (canceled) {
        scan_status_message = "Scan canceled.";
    }

    if (scan_in_progress.load()) {
        scan_status_message.clear();
    }
}

bool Application::Impl::ParseAddress(const char* text, std::uintptr_t& value) const {
    if (!text) {
        return false;
    }

    std::string input(text);
    input.erase(std::remove_if(input.begin(), input.end(), [](unsigned char c) {
                  return std::isspace(c) != 0;
              }),
                input.end());

    if (input.empty()) {
        return false;
    }

    try {
        std::size_t processed = 0;
        unsigned long long parsed = std::stoull(input, &processed, 0);
        if (processed != input.size()) {
            return false;
        }
        value = static_cast<std::uintptr_t>(parsed);
        return true;
    } catch (...) {
        return false;
    }
}

void Application::Impl::RefreshProcesses() {
    const int current_pid = process.is_open() ? process.pid() : -1;
    processes = ProcessMemory::ListProcesses();

    if (current_pid == -1) {
        attached_process_index = -1;
        attached_process_name.clear();
    } else {
        attached_process_index = -1;
        for (std::size_t i = 0; i < processes.size(); ++i) {
            if (processes[i].pid == current_pid) {
                attached_process_index = static_cast<int>(i);
                attached_process_name = processes[i].name;
                break;
            }
        }
    }

    if (selected_process < 0 || selected_process >= static_cast<int>(processes.size())) {
        selected_process = attached_process_index;
    }

    if (process.is_open()) {
        process.refresh_regions();
        SyncRegionFilters(true);
    }

    process_error_message.clear();
}

void Application::Impl::SyncRegionFilters(bool force_reset) {
    const auto& regions = process.regions();
    const std::size_t previous_size = region_filters.size();
    if (force_reset) {
        region_filters.assign(regions.size(), {});
    } else {
        region_filters.resize(regions.size());
    }

    for (std::size_t i = 0; i < regions.size(); ++i) {
        const MemoryRegion& region = regions[i];
        const bool should_initialize = force_reset || i >= previous_size;
        if (should_initialize) {
            region_filters[i].writable = RegionTriState::Any;
            region_filters[i].executable = RegionTriState::Any;
        }

        if (!region.readable()) {
            region_filters[i].writable = RegionTriState::Any;
            region_filters[i].executable = RegionTriState::Any;
            continue;
        }

        if (!region.writable() && region_filters[i].writable == RegionTriState::Yes) {
            region_filters[i].writable = RegionTriState::Any;
        }

        if (!region.executable() && region_filters[i].executable == RegionTriState::Yes) {
            region_filters[i].executable = RegionTriState::Any;
        }
    }
}

}  // namespace cpprewrite