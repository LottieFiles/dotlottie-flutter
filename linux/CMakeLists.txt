cmake_minimum_required(VERSION 3.14)
project(dotlottie_flutter_linux)

# Select the correct pre-built binary for the target architecture.
# CMAKE_SYSTEM_PROCESSOR is "x86_64" on x86-64 Linux and "aarch64" on arm64.
if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64|ARM64")
  set(DOTLOTTIE_ARCH "arm64")
else()
  set(DOTLOTTIE_ARCH "x86_64")
endif()

set(DOTLOTTIE_SO
    "${CMAKE_CURRENT_SOURCE_DIR}/${DOTLOTTIE_ARCH}/dotlottie-player/lib/libdotlottie_rs.so")

if(EXISTS "${DOTLOTTIE_SO}")
  install(FILES "${DOTLOTTIE_SO}" DESTINATION "${CMAKE_INSTALL_PREFIX}")
else()
  message(WARNING
    "linux/${DOTLOTTIE_ARCH}/dotlottie-player/lib/libdotlottie_rs.so not found. "
    "Download the dotlottie-player Linux release and place it at that path.")
endif()
