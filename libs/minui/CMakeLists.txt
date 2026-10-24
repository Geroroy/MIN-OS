# MinUI — QML 디자인 시스템 모듈 (순수 QML). import MinUI 1.0
file(GLOB MINUI_QML_FILES ${CMAKE_CURRENT_SOURCE_DIR}/qml/MinUI/*.qml ${CMAKE_CURRENT_SOURCE_DIR}/qml/MinUI/qmldir)
add_custom_target(minui SOURCES ${MINUI_QML_FILES})
install(DIRECTORY qml/MinUI DESTINATION ${MINOS_QML_INSTALL_DIR})

# QML 동작 검사 (키보드·포인터·비활성·포커스·메뉴·자산). qmltestrunner 가 있을 때만 등록된다.
find_program(QMLTESTRUNNER qmltestrunner HINTS /usr/lib/qt6/bin)
if(QMLTESTRUNNER)
    add_test(NAME minui.qml COMMAND ${QMLTESTRUNNER} -import ${CMAKE_CURRENT_SOURCE_DIR}/qml -input ${CMAKE_CURRENT_SOURCE_DIR}/tests -platform offscreen)
    set_tests_properties(minui.qml PROPERTIES ENVIRONMENT "QT_QUICK_BACKEND=software")
endif()
