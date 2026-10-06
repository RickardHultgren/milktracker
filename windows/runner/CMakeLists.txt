cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)
add_executable(${BINARY_NAME} WIN32
  "main.cpp"
)
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
