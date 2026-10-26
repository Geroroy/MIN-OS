# 하그라 셸 — hagra-shell
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

qt_add_executable(hagra-shell
  src/main.cpp
  src/appindex.cpp     src/appindex.h
  src/appiconprovider.cpp src/appiconprovider.h
  src/launcherstate.cpp src/launcherstate.h
  src/power.cpp        src/power.h
  src/shellipc.cpp     src/shellipc.h
  src/toplevelmodel.cpp src/toplevelmodel.h
  qml/qml.qrc
)
target_compile_definitions(hagra-shell PRIVATE
  HAGRA_QML_INSTALL_DIR="${HAGRA_QML_INSTALL_DIR}"
  HAGRA_VERSION="${PROJECT_VERSION}"
  HAGRA_TRANSLATIONS_DIR="${CMAKE_INSTALL_PREFIX}/${HAGRA_TRANSLATIONS_INSTALL_DIR}"
)
hagra_add_translations(hagra-shell ${CMAKE_CURRENT_SOURCE_DIR}/i18n/hagra-shell_en.ts)
target_link_libraries(hagra-shell PRIVATE
  hagralayershell hagratheme
  Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2 Qt6::DBus Qt6::Network
)
install(TARGETS hagra-shell RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

# 단위 테스트: .desktop 파서 / Exec 분해
if(HAGRA_BUILD_TESTS)
  find_package(Qt6 COMPONENTS Test QUIET)
  if(Qt6Test_FOUND)
    qt_add_executable(tst_appindex tests/tst_appindex.cpp src/appindex.cpp src/appindex.h)
    target_include_directories(tst_appindex PRIVATE src)
    target_link_libraries(tst_appindex PRIVATE Qt6::Core Qt6::Gui Qt6::Test)
    add_test(NAME shell.appindex COMMAND tst_appindex)
    qt_add_executable(tst_launcherstate tests/tst_launcherstate.cpp src/launcherstate.cpp src/launcherstate.h)
    target_include_directories(tst_launcherstate PRIVATE src)
    target_link_libraries(tst_launcherstate PRIVATE Qt6::Core Qt6::Test)
    add_test(NAME shell.launcherstate COMMAND tst_launcherstate)
  endif()
endif()
