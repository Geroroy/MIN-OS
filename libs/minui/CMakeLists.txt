# MinUI — QML 디자인 시스템 모듈 (순수 QML). import MinUI 1.0
file(GLOB MINUI_QML_FILES ${CMAKE_CURRENT_SOURCE_DIR}/qml/MinUI/*.qml ${CMAKE_CURRENT_SOURCE_DIR}/qml/MinUI/qmldir)
add_custom_target(minui SOURCES ${MINUI_QML_FILES})
install(DIRECTORY qml/MinUI DESTINATION ${MINOS_QML_INSTALL_DIR})
