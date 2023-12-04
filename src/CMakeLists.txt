# The Flutter tooling requires that developers have CMake 3.14 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.14)

project(aub_ai_library VERSION 0.0.1 LANGUAGES C CXX)

# Add the directory containing llama.cpp to the include path
#add_subdirectory(llama.cpp)

# Ensure that llama.cpp and any other relevant source files from its directory are correctly included in your CMakeLists.txt. This involves adding these source files to the add_library command alongside aub_ai.c.
add_library(aub_ai
  aub_ai.c
)

# Link your main library with the llama library
target_link_libraries(aub_ai PRIVATE llama)

set_target_properties(aub_ai PROPERTIES
  PUBLIC_HEADER aub_ai.h
  OUTPUT_NAME "aub_ai"
)

target_compile_definitions(aub_ai PUBLIC DART_SHARED_LIB)
