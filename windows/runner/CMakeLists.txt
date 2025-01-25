cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define binary name if not already defined
if(NOT DEFINED BINARY_NAME)
    set(BINARY_NAME "app")
endif()

# Define Flutter managed directory if not already defined
if(NOT DEFINED FLUTTER_MANAGED_DIR)
    set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../flutter")
endif()

# Define the executable for our application
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Set standard compiler and linker options for Windows
target_compile_features(${BINARY_NAME} PUBLIC cxx_std_17)
target_compile_options(${BINARY_NAME} PRIVATE /W4 /WX /wd"4100")
target_compile_options(${BINARY_NAME} PRIVATE /EHsc)
target_compile_definitions(${BINARY_NAME} PRIVATE "_HAS_EXCEPTIONS=0")
target_compile_definitions(${BINARY_NAME} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")

# Disable Windows macros that conflict with C++ standard library functions
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Link required libraries
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_link_libraries(${BINARY_NAME} PRIVATE user32.lib)

# Include directories
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Add dependency on Flutter build
# if(DEFINED FLUTTER_MANAGED_DIR)
#     add_dependencies(${BINARY_NAME} flutter_assemble)
# endif()