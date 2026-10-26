// libhagralayershell — wlr-foreign-toplevel-management: 다른 클라이언트 창 목록/제어
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QtWaylandClient/QWaylandClientExtensionTemplate>
#include <QObject>
#include <QString>

#include "qwayland-wlr-foreign-toplevel-management-unstable-v1.h"

namespace HagraLayerShell {

class ToplevelManager;

/// 컴포지터가 알려주는 하나의 최상위 창.
class Toplevel : public QObject, public QtWayland::zwlr_foreign_toplevel_handle_v1
{
    Q_OBJECT
    Q_PROPERTY(QString title READ title NOTIFY changed)
    Q_PROPERTY(QString appId READ appId NOTIFY changed)
    Q_PROPERTY(bool activated READ isActivated NOTIFY changed)
    Q_PROPERTY(bool minimized READ isMinimized NOTIFY changed)
    Q_PROPERTY(bool maximized READ isMaximized NOTIFY changed)
    Q_PROPERTY(bool fullscreen READ isFullscreen NOTIFY changed)
public:
    Toplevel(::zwlr_foreign_toplevel_handle_v1 *handle, ToplevelManager *manager);
    ~Toplevel() override;

    QString title() const { return m_title; }
    QString appId() const { return m_appId; }
    bool isActivated() const { return m_activated; }
    bool isMinimized() const { return m_minimized; }
    bool isMaximized() const { return m_maximized; }
    bool isFullscreen() const { return m_fullscreen; }
    /// 첫 `done` 이벤트를 받아 초기 상태가 완성되었는지.
    bool isReady() const { return m_ready; }

    Q_INVOKABLE void activate();
    Q_INVOKABLE void minimize();
    Q_INVOKABLE void unminimize();
    Q_INVOKABLE void maximize();
    Q_INVOKABLE void unmaximize();
    Q_INVOKABLE void close();

Q_SIGNALS:
    void ready();     ///< 첫 done
    void changed();   ///< 이후 done마다
    void closed();    ///< 창이 사라짐 (이후 deleteLater)

protected:
    void zwlr_foreign_toplevel_handle_v1_title(const QString &title) override;
    void zwlr_foreign_toplevel_handle_v1_app_id(const QString &app_id) override;
    void zwlr_foreign_toplevel_handle_v1_state(wl_array *state) override;
    void zwlr_foreign_toplevel_handle_v1_done() override;
    void zwlr_foreign_toplevel_handle_v1_closed() override;

private:
    ToplevelManager *m_manager;
    QString m_title, m_appId;
    bool m_activated = false, m_minimized = false, m_maximized = false, m_fullscreen = false;
    bool m_ready = false;
};

/// zwlr_foreign_toplevel_manager_v1 글로벌.
class ToplevelManager : public QWaylandClientExtensionTemplate<ToplevelManager>,
                        public QtWayland::zwlr_foreign_toplevel_manager_v1
{
    Q_OBJECT
public:
    ToplevelManager();
    ~ToplevelManager() override;
    static ToplevelManager *instance();

    /// 활성화 요청에 쓰는 wl_seat (Qt 네이티브 인터페이스에서 얻음). 없으면 nullptr.
    struct wl_seat *seat() const;

Q_SIGNALS:
    void toplevelAdded(HagraLayerShell::Toplevel *toplevel);
    void finished();

protected:
    void zwlr_foreign_toplevel_manager_v1_toplevel(::zwlr_foreign_toplevel_handle_v1 *toplevel) override;
    void zwlr_foreign_toplevel_manager_v1_finished() override;
};

} // namespace HagraLayerShell
