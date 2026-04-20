#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <string>
#include <vector>

#include "flutter_window.h"
#include "utils.h"

bool g_start_in_tray = false;

namespace {
constexpr wchar_t kSingleInstanceMutexName[] = L"Hoplixi.SingleInstance.Mutex";
constexpr wchar_t kShowWindowMessageName[] = L"Hoplixi.ShowWindowMessage";
}

int APIENTRY wWinMain(HINSTANCE instance, HINSTANCE prev,
                      wchar_t *command_line, int show_command) {
    std::vector<std::string> command_line_arguments = GetCommandLineArguments();
    for (const auto& arg : command_line_arguments) {
        if (arg == "--start-in-tray") {
            g_start_in_tray = true;
            break;
    }
    }

    HANDLE single_instance_mutex =
            ::CreateMutexW(nullptr, TRUE, kSingleInstanceMutexName);
    if (single_instance_mutex == nullptr) {
        return EXIT_FAILURE;
    }

    if (::GetLastError() == ERROR_ALREADY_EXISTS) {
        // If an instance is already running and this is a regular launch,
        // ask the existing window to show itself.
        if (!g_start_in_tray) {
            const UINT show_message =
                    ::RegisterWindowMessageW(kShowWindowMessageName);
            if (show_message != 0) {
                ::PostMessage(HWND_BROADCAST, show_message, 0, 0);
            }
    }
        ::CloseHandle(single_instance_mutex);
        return EXIT_SUCCESS;
    }

    // Attach to console when present (e.g., 'flutter run') or create a
    // new console when running with a debugger.
    if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
        CreateAndAttachConsole();
    }

    // Initialize COM, so that it is available for use in the library and/or
    // plugins.
    ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

    flutter::DartProject project(L"data");

    project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

    FlutterWindow window(project);
    Win32Window::Point origin(10, 10);
    Win32Window::Size size(1280, 720);
    if (!window.Create(L"country_steel_docs_dev", origin, size)) {
        ::CloseHandle(single_instance_mutex);
        return EXIT_FAILURE;
    }
    window.SetQuitOnClose(true);

    ::MSG msg;
    while (::GetMessage(&msg, nullptr, 0, 0)) {
        ::TranslateMessage(&msg);
        ::DispatchMessage(&msg);
    }

    ::CloseHandle(single_instance_mutex);
    ::CoUninitialize();
    return EXIT_SUCCESS;
}
