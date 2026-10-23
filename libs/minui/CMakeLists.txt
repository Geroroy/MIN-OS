# MinUI — QML 디자인 시스템 모듈 (순수 QML). import MinUI 1.0
set(MINUI_QML_FILES
  qml/MinUI/qmldir
  qml/MinUI/Theme.qml
  qml/MinUI/MButton.qml
  qml/MinUI/MLabel.qml
  qml/MinUI/MSeparator.qml
  qml/MinUI/MTextField.qml
  qml/MinUI/MListRow.qml
)
add_custom_target(minui SOURCES ${MINUI_QML_FILES})
install(DIRECTORY qml/MinUI DESTINATION ${MINOS_QML_INSTALL_DIR})
