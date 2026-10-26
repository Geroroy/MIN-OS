// libhagralayershell — LayerWindow: layer-shell 표면으로 표시되는 QQuickWindow
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QQuickWindow>
#include <QQmlParserStatus>
#include <QMargins>

namespace HagraLayerShell {

class LayerSurface;

/**
 * QML에서 `LayerWindow { layer: LayerWindow.Bottom; anchors: LayerWindow.AnchorLeft | ... }` 로 사용한다.
 * 창이 보이게 되는 시점에 wl_surface에 zwlr_layer_surface_v1 역할을 부여하고,
 * 첫 configure를 받아 ack 한 뒤에 Qt가 첫 버퍼를 붙이도록 순서를 보장한다.
 */
class LayerWindow : public QQuickWindow, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    Q_PROPERTY(Layer layer READ layer WRITE setLayer NOTIFY layerChanged)
    Q_PROPERTY(Anchors anchors READ anchors WRITE setAnchors NOTIFY anchorsChanged)
    Q_PROPERTY(int exclusiveZone READ exclusiveZone WRITE setExclusiveZone NOTIFY exclusiveZoneChanged)
    Q_PROPERTY(KeyboardInteractivity keyboardInteractivity READ keyboardInteractivity WRITE setKeyboardInteractivity NOTIFY keyboardInteractivityChanged)
    Q_PROPERTY(QString scope READ scope WRITE setScope NOTIFY scopeChanged)
    Q_PROPERTY(int marginTop READ marginTop WRITE setMarginTop NOTIFY marginsChanged)
    Q_PROPERTY(int marginRight READ marginRight WRITE setMarginRight NOTIFY marginsChanged)
    Q_PROPERTY(int marginBottom READ marginBottom WRITE setMarginBottom NOTIFY marginsChanged)
    Q_PROPERTY(int marginLeft READ marginLeft WRITE setMarginLeft NOTIFY marginsChanged)
    Q_PROPERTY(bool configured READ isConfigured NOTIFY configuredChanged)
    // QWindow::setVisible 은 가상 함수가 아니므로 QQuickWindowQmlImpl 과 같은 방식으로 속성을 재선언한다.
    Q_PROPERTY(bool visible READ isVisible WRITE setVisible NOTIFY visibleChanged)

public:
    enum Layer { Background = 0, Bottom = 1, Top = 2, Overlay = 3 };
    Q_ENUM(Layer)

    enum Anchor { AnchorNone = 0, AnchorTop = 1, AnchorBottom = 2, AnchorLeft = 4, AnchorRight = 8 };
    Q_DECLARE_FLAGS(Anchors, Anchor)
    Q_FLAG(Anchors)

    enum KeyboardInteractivity { KeyboardNone = 0, KeyboardExclusive = 1, KeyboardOnDemand = 2 };
    Q_ENUM(KeyboardInteractivity)

    explicit LayerWindow(QWindow *parent = nullptr);
    ~LayerWindow() override;

    Layer layer() const { return m_layer; }
    void setLayer(Layer layer);
    Anchors anchors() const { return m_anchors; }
    void setAnchors(Anchors anchors);
    int exclusiveZone() const { return m_exclusiveZone; }
    void setExclusiveZone(int zone);
    KeyboardInteractivity keyboardInteractivity() const { return m_keyboard; }
    void setKeyboardInteractivity(KeyboardInteractivity k);
    QString scope() const { return m_scope; }
    void setScope(const QString &scope);
    int marginTop() const { return m_margins.top(); }
    int marginRight() const { return m_margins.right(); }
    int marginBottom() const { return m_margins.bottom(); }
    int marginLeft() const { return m_margins.left(); }
    void setMarginTop(int v);
    void setMarginRight(int v);
    void setMarginBottom(int v);
    void setMarginLeft(int v);
    bool isConfigured() const { return m_configured; }

    /// QML 타입 등록: import HagraLayerShell 1.0
    static void registerQmlTypes();

    /// QML `visible` 속성. 컴포넌트 완성 전에는 지연되고, 숨길 때는 layer surface 를 먼저 정리한다.
    void setVisible(bool visible);

Q_SIGNALS:
    void visibleChanged(bool arg);   // QWindow::visibleChanged 를 다시 선언 (생성자에서 연결)
    void layerChanged();
    void anchorsChanged();
    void exclusiveZoneChanged();
    void keyboardInteractivityChanged();
    void scopeChanged();
    void marginsChanged();
    void configuredChanged();
    /// 컴포지터가 표면을 닫았다 (출력 제거 등).
    void closedByCompositor();

protected:
    // QQmlParserStatus
    void classBegin() override;
    void componentComplete() override;
    // QWindow
    bool event(QEvent *event) override;
    void resizeEvent(QResizeEvent *event) override;

private:
    friend class LayerSurface;
    void createLayerSurface();
    void destroyLayerSurface();
    void pushState();
    void pushSize();
    void handleConfigure(quint32 width, quint32 height);
    void handleClosed();

    LayerSurface *m_surface = nullptr;
    Layer m_layer = Top;
    Anchors m_anchors = AnchorNone;
    int m_exclusiveZone = 0;
    KeyboardInteractivity m_keyboard = KeyboardNone;
    QString m_scope = QStringLiteral("hagra");
    QMargins m_margins;
    bool m_configured = false;
    bool m_inConfigure = false;
    bool m_completing = false;
    bool m_visiblePending = false;
    bool m_inSetVisible = false;
    bool m_creating = false;       // createLayerSurface() 의 동기 대기 중 (configure 에 의한 resize 를 지연)
    QSize m_pendingSize;           // 생성 중 받은 configure 크기 (대기 종료 후 적용)
};

Q_DECLARE_OPERATORS_FOR_FLAGS(LayerWindow::Anchors)

} // namespace HagraLayerShell
