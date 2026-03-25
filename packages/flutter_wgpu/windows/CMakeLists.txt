cmake_minimum_required(VERSION 3.15)

set(PROJECT_NAME "flutter_wgpu")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "flutter_wgpu_plugin")

add_library(${PLUGIN_NAME} SHARED
  "flutter_wgpu_plugin.cpp"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
  d3d11
  dxgi
)

# wgpu_native.dll is bundled by the wgpu_libs package
