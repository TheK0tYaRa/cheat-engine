#include "Application.hpp"

#include "imgui.h"
#include "backends/imgui_impl_opengl3.h"
#include "backends/imgui_impl_sdl2.h"

#include <SDL2/SDL.h>
#include <SDL2/SDL_opengl.h>

#include <chrono>
#include <cstdio>
#include <vector>

namespace cpprewrite {

struct Application::Impl {
    SDL_Window* window = nullptr;
    SDL_GLContext gl_context = nullptr;
    ProcessMemory process;
    std::vector<ProcessInfo> processes;
    int selected_process = -1;
    ValueType value_type = ValueType::Int32;
    char value_buffer[64] = "";
    bool only_writable = true;
    std::vector<ScanResult> results;

    bool Initialize();
    void Shutdown();
    void RenderFrame();
    void RenderProcessList();
    void RenderScanner();
    void RefreshProcesses();
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
    }
}

bool Application::Impl::Initialize() {
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

    RenderProcessList();
    RenderScanner();

    ImGui::Render();
    glViewport(0, 0, static_cast<int>(ImGui::GetIO().DisplaySize.x),
               static_cast<int>(ImGui::GetIO().DisplaySize.y));
    glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
    SDL_GL_SwapWindow(window);
}

void Application::Impl::RenderProcessList() {
    ImGui::Begin("Processes");
    if (ImGui::Button("Refresh")) {
        RefreshProcesses();
    }
    ImGui::Separator();
    ImGui::BeginChild("ProcessList", ImVec2(0, 300), true);
    for (std::size_t i = 0; i < processes.size(); ++i) {
        const ProcessInfo& info = processes[i];
        std::string label = std::to_string(info.pid) + " - " + info.name;
        if (ImGui::Selectable(label.c_str(), selected_process == static_cast<int>(i))) {
            selected_process = static_cast<int>(i);
            if (process.open(info.pid)) {
                process.refresh_regions();
                results.clear();
            }
        }
    }
    ImGui::EndChild();

    if (!process.is_open()) {
        ImGui::TextWrapped("Select a process to begin scanning. Reading another process's memory usually requires elevated privileges.");
    } else {
        ImGui::Text("Attached to PID %d", process.pid());
    }

    ImGui::End();
}

void Application::Impl::RenderScanner() {
    ImGui::Begin("Scanner");
    static const char* value_labels[] = {"Int32", "UInt32", "Float", "Double"};
    int current_type = static_cast<int>(value_type);
    if (ImGui::Combo("Value Type", &current_type, value_labels, IM_ARRAYSIZE(value_labels))) {
        value_type = static_cast<ValueType>(current_type);
    }

    ImGui::InputText("Value", value_buffer, sizeof(value_buffer));
    ImGui::Checkbox("Only writable regions", &only_writable);

    if (ImGui::Button("New Scan")) {
        if (process.is_open()) {
            ScanRequest request;
            request.type = value_type;
            request.value_text = value_buffer;
            request.only_writable = only_writable;
            MemoryScanner scanner(process);
            results = scanner.PerformScan(request);
        }
    }

    ImGui::Separator();
    ImGui::Text("Results: %zu", results.size());

    if (ImGui::BeginTable("ResultsTable", 3, ImGuiTableFlags_Borders | ImGuiTableFlags_RowBg | ImGuiTableFlags_Resizable)) {
        ImGui::TableSetupColumn("Address", ImGuiTableColumnFlags_WidthStretch);
        ImGui::TableSetupColumn("Bytes", ImGuiTableColumnFlags_WidthStretch);
        ImGui::TableSetupColumn("Region", ImGuiTableColumnFlags_WidthStretch);
        ImGui::TableHeadersRow();

        for (const auto& result : results) {
            ImGui::TableNextRow();
            ImGui::TableSetColumnIndex(0);
            ImGui::Text("0x%lx", static_cast<unsigned long>(result.address));

            ImGui::TableSetColumnIndex(1);
            std::string byte_string;
            for (std::uint8_t byte : result.bytes) {
                char buffer[4];
                std::snprintf(buffer, sizeof(buffer), "%02X ", byte);
                byte_string += buffer;
            }
            ImGui::TextUnformatted(byte_string.c_str());

            ImGui::TableSetColumnIndex(2);
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
        }
        ImGui::EndTable();
    }

    ImGui::End();
}

void Application::Impl::RefreshProcesses() {
    processes = ProcessMemory::ListProcesses();
    if (selected_process >= static_cast<int>(processes.size())) {
        selected_process = -1;
    }
}

}  // namespace cpprewrite
