// libminlayershell — zwlr_layer_shell_v1 글로벌 바인딩
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QtWaylandClient/QWaylandClientExtensionTemplate>
#include <QWindow>

#include "qwayland-wlr-layer-shell-unstable-v1.h"

struct wl_surface;
struct wl_display;

namespace MinLayerShell {

/// zwlr_layer_shell_v1 글로벌. 프로세스당 하나.
class LayerShellGlobal : public QWaylandClientExtensionTemplate<LayerShellGlobal>,
                         public QtWayland::zwlr_layer_shell_v1
{
    Q_OBJECT
public:
    LayerShellGlobal();
    ~LayerShellGlobal() override;

    /// 전역 인스턴스. 처음 호출 시 생성하고 레지스트리 바인딩이 끝날 때까지 기다린다.
    static LayerShellGlobal *instance();

    /// 컴포지터가 layer-shell을 광고했는지(바인딩 완료) 확인. timeoutMs 동안 이벤트를 처리한다.
    bool waitForActive(int timeoutMs = 2000);
};

/// QWindow의 wl_surface (없으면 nullptr). 플랫폼 창이 만들어진 뒤에만 유효하다.
wl_surface *waylandSurfaceFor(QWindow *window);

/// 현재 QGuiApplication의 wl_display.
wl_display *waylandDisplay();

/// QGuiApplication 생성 **이전**에 호출: Qt가 xdg_toplevel 역할을 부여하지 않도록 환경을 설정한다.
void prepareEnvironment();

} // namespace MinLayerShell
