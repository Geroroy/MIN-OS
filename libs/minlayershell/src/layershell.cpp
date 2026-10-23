// SPDX-License-Identifier: GPL-3.0-or-later
#include "minlayershell/layershell.h"

#include <QCoreApplication>
#include <QElapsedTimer>
#include <QGuiApplication>
#include <QLoggingCategory>
#include <qpa/qplatformnativeinterface.h>

#include <wayland-client-core.h>

Q_LOGGING_CATEGORY(lcLayerShell, "minos.layershell")

namespace MinLayerShell {

static LayerShellGlobal *s_instance = nullptr;

LayerShellGlobal::LayerShellGlobal()
    : QWaylandClientExtensionTemplate<LayerShellGlobal>(4)
{
    // Qt 6.4+: 레지스트리 리스너를 즉시 등록한다 (지연 등록이면 isActive()가 이벤트 루프 이후에만 참).
    initialize();
}

LayerShellGlobal::~LayerShellGlobal()
{
    if (s_instance == this)
        s_instance = nullptr;
}

LayerShellGlobal *LayerShellGlobal::instance()
{
    if (!s_instance) {
        s_instance = new LayerShellGlobal();
        s_instance->setParent(QCoreApplication::instance());
        if (!s_instance->waitForActive())
            qCWarning(lcLayerShell) << "compositor does not advertise zwlr_layer_shell_v1";
        else
            qCInfo(lcLayerShell) << "zwlr_layer_shell_v1 bound, version" << s_instance->QtWayland::zwlr_layer_shell_v1::version();
    }
    return s_instance;
}

bool LayerShellGlobal::waitForActive(int timeoutMs)
{
    QElapsedTimer timer;
    timer.start();
    while (!isActive() && timer.elapsed() < timeoutMs)
        QCoreApplication::processEvents(QEventLoop::AllEvents | QEventLoop::WaitForMoreEvents, 20);
    return isActive();
}

wl_surface *waylandSurfaceFor(QWindow *window)
{
    if (!window || !window->handle())
        return nullptr;
    QPlatformNativeInterface *native = QGuiApplication::platformNativeInterface();
    if (!native)
        return nullptr;
    return static_cast<wl_surface *>(native->nativeResourceForWindow(QByteArrayLiteral("surface"), window));
}

wl_display *waylandDisplay()
{
    QPlatformNativeInterface *native = QGuiApplication::platformNativeInterface();
    if (!native)
        return nullptr;
    return static_cast<wl_display *>(native->nativeResourceForIntegration(QByteArrayLiteral("wl_display")));
}

void prepareEnvironment()
{
    // Qt::BypassWindowManagerHint 가 설정된 창에는 xdg_toplevel 역할을 만들지 않는다 (qtwayland 공식 환경변수).
    qputenv("QT_WAYLAND_USE_BYPASSWINDOWMANAGERHINT", "1");
    // 셸 창에는 클라이언트 측 장식이 없어야 한다.
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM"))
        qputenv("QT_QPA_PLATFORM", "wayland");
}

} // namespace MinLayerShell
