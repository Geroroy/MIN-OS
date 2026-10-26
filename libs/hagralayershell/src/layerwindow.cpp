// SPDX-License-Identifier: GPL-3.0-or-later
#include "hagralayershell/layerwindow.h"
#include "hagralayershell/layershell.h"

#include <QCoreApplication>
#include <QElapsedTimer>
#include <QLoggingCategory>
#include <QPlatformSurfaceEvent>
#include <QResizeEvent>
#include <QtQml/qqml.h>

#include <wayland-client-core.h>
#include <wayland-client-protocol.h>

Q_DECLARE_LOGGING_CATEGORY(lcLayerShell)

namespace HagraLayerShell {

/// zwlr_layer_surface_v1 프록시. configure/closed 이벤트를 LayerWindow로 전달한다.
class LayerSurface : public QtWayland::zwlr_layer_surface_v1
{
public:
    LayerSurface(::zwlr_layer_surface_v1 *object, LayerWindow *window)
        : QtWayland::zwlr_layer_surface_v1(object), m_window(window) {}
    ~LayerSurface() override
    {
        if (isInitialized())
            destroy();
    }

protected:
    void zwlr_layer_surface_v1_configure(uint32_t serial, uint32_t width, uint32_t height) override
    {
        ack_configure(serial);
        m_window->handleConfigure(width, height);
    }
    void zwlr_layer_surface_v1_closed() override { m_window->handleClosed(); }

private:
    LayerWindow *m_window;
};

LayerWindow::LayerWindow(QWindow *parent)
    : QQuickWindow(parent)
{
    // FramelessWindowHint: 장식 없음. BypassWindowManagerHint: Qt가 xdg_toplevel 역할을 만들지 않음
    // (QT_WAYLAND_USE_BYPASSWINDOWMANAGERHINT=1 필요 — prepareEnvironment()).
    setFlags(Qt::FramelessWindowHint | Qt::BypassWindowManagerHint);
    connect(this, &QWindow::visibleChanged, this, &LayerWindow::visibleChanged);
    if (!qEnvironmentVariableIsSet("QT_WAYLAND_USE_BYPASSWINDOWMANAGERHINT"))
        qCWarning(lcLayerShell) << "QT_WAYLAND_USE_BYPASSWINDOWMANAGERHINT is not set; call HagraLayerShell::prepareEnvironment() before QGuiApplication";
}

LayerWindow::~LayerWindow()
{
    destroyLayerSurface();
}

void LayerWindow::registerQmlTypes()
{
    qmlRegisterType<LayerWindow>("HagraLayerShell", 1, 0, "LayerWindow");
}

// ---- QQmlParserStatus: 모든 속성이 설정된 뒤에 보이도록 지연한다 (QQuickWindowQmlImpl과 같은 방식) ----

void LayerWindow::classBegin() { m_completing = true; }

void LayerWindow::componentComplete()
{
    m_completing = false;
    if (m_visiblePending) {
        m_visiblePending = false;
        setVisible(true);
    }
}

void LayerWindow::setVisible(bool visible)
{
    if (m_completing) {
        m_visiblePending = visible;
        return;
    }
    if (m_inSetVisible) {
        QWindow::setVisible(visible);
        return;
    }
    m_inSetVisible = true;
    if (visible) {
        // create() → SurfaceCreated 이벤트 → createLayerSurface() → 첫 configure 대기 → 그 다음 Qt가 노출/렌더링.
        QWindow::setVisible(true);
    } else {
        // Qt는 숨길 때 wl_surface를 파괴한다. layer_surface를 먼저 없애고, 플랫폼 창도 파괴하여
        // 다음 show() 때 SurfaceCreated 이벤트를 다시 받도록 한다.
        destroyLayerSurface();
        QWindow::setVisible(false);
        destroy();
    }
    m_inSetVisible = false;
}

bool LayerWindow::event(QEvent *event)
{
    if (event->type() == QEvent::PlatformSurface) {
        auto *pse = static_cast<QPlatformSurfaceEvent *>(event);
        if (pse->surfaceEventType() == QPlatformSurfaceEvent::SurfaceCreated)
            createLayerSurface();
        else if (pse->surfaceEventType() == QPlatformSurfaceEvent::SurfaceAboutToBeDestroyed)
            destroyLayerSurface();
    }
    return QQuickWindow::event(event);
}

void LayerWindow::resizeEvent(QResizeEvent *event)
{
    QQuickWindow::resizeEvent(event);
    // 애플리케이션이 스스로 크기를 바꾼 경우 컴포지터에 알린다 (configure에 의한 resize는 제외).
    if (m_surface && !m_inConfigure)
        pushSize();
}

// ---- layer surface 수명 ----

void LayerWindow::createLayerSurface()
{
    if (m_surface)
        return;
    LayerShellGlobal *shell = LayerShellGlobal::instance();
    if (!shell || !shell->isActive()) {
        qCWarning(lcLayerShell) << "cannot create layer surface: zwlr_layer_shell_v1 not available";
        return;
    }
    wl_surface *surface = waylandSurfaceFor(this);
    if (!surface) {
        qCWarning(lcLayerShell) << "cannot create layer surface: no wl_surface for window";
        return;
    }

    ::zwlr_layer_surface_v1 *object =
        shell->get_layer_surface(surface, nullptr, static_cast<uint32_t>(m_layer), m_scope);
    m_surface = new LayerSurface(object, this);
    m_configured = false;
    pushState();
    pushSize();

    // 역할 부여 후 버퍼 없는 첫 commit → 컴포지터가 configure를 보낸다.
    wl_surface_commit(surface);
    if (wl_display *display = waylandDisplay())
        wl_display_flush(display);

    // Qt가 첫 버퍼를 붙이기 전에 configure/ack가 끝나야 한다 (프로토콜 요구). 짧게 동기 대기한다.
    // 주의: 이 대기 중에는 QWindow::resize() 를 호출하지 않는다. 창은 아직 create() 안에 있어 showEvent 전이고,
    // resize → QWaylandWindow::setGeometry → Expose 이벤트가 중첩 루프에서 전달되면 QQuickWindow 가 backing store 없이
    // 렌더링을 시도해 segfault 한다 (출력 폭이 QML 의 초기 width 와 다른 1920×1080 에서 재현). 크기는 대기가 끝난 뒤 적용한다.
    QElapsedTimer timer;
    timer.start();
    m_creating = true;
    m_pendingSize = QSize();
    while (!m_configured && timer.elapsed() < 2000)
        QCoreApplication::processEvents(QEventLoop::AllEvents | QEventLoop::WaitForMoreEvents, 20);
    m_creating = false;
    if (!m_configured)
        qCWarning(lcLayerShell) << "layer surface" << m_scope << "was not configured within 2s";
    if (m_pendingSize.isValid() && m_pendingSize != size()) {
        m_inConfigure = true;
        resize(m_pendingSize);   // Expose 는 큐에 쌓여 showEvent 이후 메인 루프에서 처리된다
        m_inConfigure = false;
    }
}

void LayerWindow::destroyLayerSurface()
{
    delete m_surface;
    m_surface = nullptr;
    if (m_configured) {
        m_configured = false;
        emit configuredChanged();
    }
}

void LayerWindow::pushState()
{
    if (!m_surface)
        return;
    m_surface->set_anchor(static_cast<uint32_t>(m_anchors));
    m_surface->set_exclusive_zone(m_exclusiveZone);
    m_surface->set_margin(m_margins.top(), m_margins.right(), m_margins.bottom(), m_margins.left());
    uint32_t kbd = static_cast<uint32_t>(m_keyboard);
    if (kbd == KeyboardOnDemand && m_surface->version() < 4)
        kbd = KeyboardExclusive; // on_demand는 v4부터
    m_surface->set_keyboard_interactivity(kbd);
}

void LayerWindow::pushSize()
{
    if (!m_surface)
        return;
    // 양쪽 가장자리에 고정된 축은 0(컴포지터가 결정), 아니면 창 크기.
    const bool stretchX = (m_anchors & AnchorLeft) && (m_anchors & AnchorRight);
    const bool stretchY = (m_anchors & AnchorTop) && (m_anchors & AnchorBottom);
    const uint32_t w = stretchX ? 0 : static_cast<uint32_t>(qMax(1, width()));
    const uint32_t h = stretchY ? 0 : static_cast<uint32_t>(qMax(1, height()));
    m_surface->set_size(w, h);
}

void LayerWindow::handleConfigure(quint32 width, quint32 height)
{
    QSize size(width > 0 ? int(width) : this->width(), height > 0 ? int(height) : this->height());
    if (m_creating) {
        m_pendingSize = size;    // createLayerSurface() 가 대기 종료 후 적용
    } else {
        m_inConfigure = true;
        if (size != this->size())
            resize(size);
        m_inConfigure = false;
    }
    if (!m_configured) {
        m_configured = true;
        qCDebug(lcLayerShell) << "layer surface" << m_scope << "configured" << size;
        emit configuredChanged();
    }
}

void LayerWindow::handleClosed()
{
    qCInfo(lcLayerShell) << "layer surface" << m_scope << "closed by compositor";
    emit closedByCompositor();
    setVisible(false);
}

// ---- 속성 ----

void LayerWindow::setLayer(Layer layer)
{
    if (m_layer == layer) return;
    m_layer = layer;
    if (m_surface && m_surface->version() >= 2)
        m_surface->set_layer(static_cast<uint32_t>(layer));
    emit layerChanged();
}

void LayerWindow::setAnchors(Anchors anchors)
{
    if (m_anchors == anchors) return;
    m_anchors = anchors;
    pushState();
    pushSize();
    emit anchorsChanged();
}

void LayerWindow::setExclusiveZone(int zone)
{
    if (m_exclusiveZone == zone) return;
    m_exclusiveZone = zone;
    if (m_surface) m_surface->set_exclusive_zone(zone);
    emit exclusiveZoneChanged();
}

void LayerWindow::setKeyboardInteractivity(KeyboardInteractivity k)
{
    if (m_keyboard == k) return;
    m_keyboard = k;
    pushState();
    emit keyboardInteractivityChanged();
}

void LayerWindow::setScope(const QString &scope)
{
    if (m_scope == scope) return;
    m_scope = scope; // 표면 생성 시에만 적용된다
    emit scopeChanged();
}

void LayerWindow::setMarginTop(int v)    { if (m_margins.top() == v) return;    m_margins.setTop(v);    pushState(); emit marginsChanged(); }
void LayerWindow::setMarginRight(int v)  { if (m_margins.right() == v) return;  m_margins.setRight(v);  pushState(); emit marginsChanged(); }
void LayerWindow::setMarginBottom(int v) { if (m_margins.bottom() == v) return; m_margins.setBottom(v); pushState(); emit marginsChanged(); }
void LayerWindow::setMarginLeft(int v)   { if (m_margins.left() == v) return;   m_margins.setLeft(v);   pushState(); emit marginsChanged(); }

} // namespace HagraLayerShell
