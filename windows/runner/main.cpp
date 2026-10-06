#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <memory>

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line, _In_ int show_command) {
  flutter::DartProject project(L"data");
  flutter::FlutterViewController controller(800, 600, project);
  if (!controller.engine() || !controller.view()) return EXIT_FAILURE;
  controller.ForceRedraw();
  MSG msg;
  while (GetMessage(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }
  return EXIT_SUCCESS;
}
