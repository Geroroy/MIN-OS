# 하그라 설정 — hagra-settings (Qt6/QML + HagraUI + HagraTheme). 페이지별 백엔드는 설치된 시스템 서비스가 있을 때만 동작한다.
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
find_package(Qt6 6.4 REQUIRED COMPONENTS Xml)

set(HAGRA_SETTINGS_BACKENDS
  src/proc.cpp src/proc.h
  src/conffile.cpp src/conffile.h
  src/systeminfo.cpp src/systeminfo.h
  src/displaybackend.cpp src/displaybackend.h
  src/soundbackend.cpp src/soundbackend.h
  src/inputbackend.cpp src/inputbackend.h
  src/localebackend.cpp src/localebackend.h
  src/networkbackend.cpp src/networkbackend.h
  src/powerbackend.cpp src/powerbackend.h
  src/notifybackend.cpp src/notifybackend.h
  src/wallpapers.cpp src/wallpapers.h
)
qt_add_executable(hagra-settings src/main.cpp ${HAGRA_SETTINGS_BACKENDS} qml/qml.qrc)
target_include_directories(hagra-settings PRIVATE src)
target_compile_definitions(hagra-settings PRIVATE HAGRA_QML_INSTALL_DIR="${HAGRA_QML_INSTALL_DIR}" HAGRA_VERSION="${PROJECT_VERSION}")
target_link_libraries(hagra-settings PRIVATE hagratheme Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2 Qt6::DBus Qt6::Network Qt6::Xml)
install(TARGETS hagra-settings RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES org.hagra.settings.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)

if(HAGRA_BUILD_TESTS)
  find_package(Qt6 COMPONENTS Test QUIET)
  if(Qt6Test_FOUND)
    qt_add_executable(tst_settings tests/tst_settings.cpp ${HAGRA_SETTINGS_BACKENDS})
    target_include_directories(tst_settings PRIVATE src)
    target_compile_definitions(tst_settings PRIVATE HAGRA_VERSION="${PROJECT_VERSION}")
    target_link_libraries(tst_settings PRIVATE hagratheme Qt6::Core Qt6::Gui Qt6::DBus Qt6::Network Qt6::Xml Qt6::Test)
    add_test(NAME settings.backends COMMAND tst_settings)
    set_tests_properties(settings.backends PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
  endif()
endif()
