cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
)
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
