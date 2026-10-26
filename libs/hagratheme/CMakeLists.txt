# libhagratheme — 테마 팩 레지스트리·선택 저장·런타임 적용 (셸·미리보기·설정이 공유)
set(CMAKE_AUTOMOC ON)
add_library(hagratheme STATIC
  src/thememanager.cpp
  include/hagratheme/thememanager.h
)
target_include_directories(hagratheme PUBLIC include)
target_compile_definitions(hagratheme PUBLIC HAGRA_THEME_INSTALL_DIR="${CMAKE_INSTALL_FULL_DATADIR}/hagra/themes")
target_link_libraries(hagratheme PUBLIC Qt6::Core Qt6::Gui Qt6::Qml)

if(HAGRA_BUILD_TESTS)
  find_package(Qt6 COMPONENTS Test QUIET)
  if(Qt6Test_FOUND)
    qt_add_executable(tst_thememanager tests/tst_thememanager.cpp)
    target_link_libraries(tst_thememanager PRIVATE hagratheme Qt6::Test)
    add_test(NAME theme.manager COMMAND tst_thememanager)
    set_tests_properties(theme.manager PROPERTIES ENVIRONMENT "HAGRA_THEME_PATH=${CMAKE_BINARY_DIR}/themes;QT_QPA_PLATFORM=offscreen")
  endif()
endif()
