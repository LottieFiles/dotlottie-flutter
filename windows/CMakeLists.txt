cmake_minimum_required(VERSION 3.14)
project(dotlottie_flutter_windows)

# Select the correct pre-built binary for the target architecture.
# CMAKE_SYSTEM_PROCESSOR is "AMD64" on x86-64 Windows and "ARM64" on arm64.
if(CMAKE_SYSTEM_PROCESSOR MATCHES "ARM64|arm64|aarch64")
  set(DOTLOTTIE_ARCH "arm64")
else()
  set(DOTLOTTIE_ARCH "x86_64")
endif()

set(DOTLOTTIE_DLL
    "${CMAKE_CURRENT_SOURCE_DIR}/${DOTLOTTIE_ARCH}/dotlottie-player/lib/dotlottie_player.dll")

if(EXISTS "${DOTLOTTIE_DLL}")
  set(dotlottie_flutter_bundled_libraries "${DOTLOTTIE_DLL}" PARENT_SCOPE)
else()
  message(WARNING
    "windows/${DOTLOTTIE_ARCH}/dotlottie-player/lib/dotlottie_player.dll not found. "
    "Download the dotlottie-player Windows release and place it at that path.")
endif()
