#include "Application.hpp"

#include <cstdlib>
#include <iostream>

int main() {
    cpprewrite::Application app;
    if (!app.Initialize()) {
        std::cerr << "Failed to initialize application. Ensure SDL2, OpenGL, and permissions are available." << std::endl;
        return EXIT_FAILURE;
    }

    app.Run();
    return EXIT_SUCCESS;
}
