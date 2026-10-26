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
if(MINOS_BUILD_TESTS)
  enable_testing()   # add_test() 보다 먼저 호출되어야 ctest 가 테스트를 인식한다
endif()

add_subdirectory(libs/minlayershell)
add_subdirectory(libs/minui)
add_subdirectory(libs/hagratheme)
add_subdirectory(tools/preview)
add_subdirectory(tools/theme)

# 테마 팩: design/themes/<id>/theme.json → build/themes/<id>/ (조립) → /usr/share/hagra/themes/<id>/ (설치)
# 런타임(ThemeManager)은 $HAGRA_THEME_PATH → ~/.local/share/hagra/themes → 설치 경로 순으로 찾는다.
file(GLOB_RECURSE MINOS_THEME_SOURCES CONFIGURE_DEPENDS
  ${CMAKE_SOURCE_DIR}/design/themes/*/theme.json ${CMAKE_SOURCE_DIR}/design/themes/*/tokens.json
  ${CMAKE_SOURCE_DIR}/design/tokens/hagra.tokens.json ${CMAKE_SOURCE_DIR}/design/hagra-dancheong-v*/assets/*)
add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/themes/.stamp
  COMMAND python3 -I ${CMAKE_SOURCE_DIR}/design/tools/build_themes.py ${CMAKE_BINARY_DIR}/themes
  COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_BINARY_DIR}/themes/.stamp
  DEPENDS ${MINOS_THEME_SOURCES} ${CMAKE_SOURCE_DIR}/design/tools/build_themes.py ${CMAKE_SOURCE_DIR}/design/tools/gen_tokens.py
  COMMENT "Assembling HAGRA theme packs")
add_custom_target(themes ALL DEPENDS ${CMAKE_BINARY_DIR}/themes/.stamp)
install(DIRECTORY ${CMAKE_BINARY_DIR}/themes/ DESTINATION ${CMAKE_INSTALL_DATADIR}/hagra/themes PATTERN ".stamp" EXCLUDE)
# 디자인 자산 (아이콘·배경). design/assets/icons/*.svg → /usr/share/hagra/icons
install(DIRECTORY ${CMAKE_SOURCE_DIR}/design/assets/icons DESTINATION ${CMAKE_INSTALL_DATADIR}/hagra OPTIONAL)
if(MINOS_BUILD_SHELL)
  add_subdirectory(shell)
endif()
