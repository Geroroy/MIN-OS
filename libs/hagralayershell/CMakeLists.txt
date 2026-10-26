# libhagralayershell — Qt 6 창을 wlr-layer-shell 표면으로 만드는 작은 정적 라이브러리.
# Qt 공개 API(QWaylandClientExtensionTemplate)와 QPA 네이티브 인터페이스만 사용한다.
set(CMAKE_AUTOMOC ON)

add_library(hagralayershell STATIC
  src/layershell.cpp
  src/layerwindow.cpp
  src/foreigntoplevel.cpp
  include/hagralayershell/layershell.h
  include/hagralayershell/layerwindow.h
  include/hagralayershell/foreigntoplevel.h
)

qt6_generate_wayland_protocol_client_sources(hagralayershell
  FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/protocols/wlr-layer-shell-unstable-v1.xml
    ${CMAKE_CURRENT_SOURCE_DIR}/protocols/wlr-foreign-toplevel-management-unstable-v1.xml
    ${CMAKE_CURRENT_SOURCE_DIR}/protocols/xdg-shell.xml
)

target_include_directories(hagralayershell
  PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include ${CMAKE_CURRENT_BINARY_DIR}
)
target_link_libraries(hagralayershell
  PUBLIC Qt6::Gui Qt6::Quick Qt6::Qml Qt6::WaylandClient
  PRIVATE Qt6::GuiPrivate
)
