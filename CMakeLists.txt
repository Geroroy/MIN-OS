# MIN OS — 최상위 CMake 프로젝트
# 모든 MIN 컴포넌트(라이브러리·셸·앱)를 한 번에 빌드/설치한다.
#   cmake -S . -B build -G Ninja -DCMAKE_INSTALL_PREFIX=/usr && cmake --build build && cmake --install build
cmake_minimum_required(VERSION 3.22)
project(minos VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

include(GNUInstallDirs)
find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 DBus Network WaylandClient)
qt_standard_project_setup()

# Qt QML 모듈 설치 경로 (예: /usr/lib/x86_64-linux-gnu/qt6/qml)
if(NOT MINOS_QML_INSTALL_DIR)
  set(MINOS_QML_INSTALL_DIR "${QT6_INSTALL_PREFIX}/${QT6_INSTALL_QML}")
endif()
message(STATUS "MIN OS: QML modules install to ${MINOS_QML_INSTALL_DIR}")

option(MINOS_BUILD_SHELL "Build MIN Shell" ON)
option(MINOS_BUILD_TESTS "Build unit tests" ON)

add_subdirectory(libs/minlayershell)
add_subdirectory(libs/minui)
if(MINOS_BUILD_SHELL)
  add_subdirectory(shell)
endif()
if(MINOS_BUILD_TESTS)
  enable_testing()
endif()
