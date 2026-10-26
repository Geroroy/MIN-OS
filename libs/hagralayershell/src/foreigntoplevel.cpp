// SPDX-License-Identifier: GPL-3.0-or-later
#include "hagralayershell/foreigntoplevel.h"

#include <QCoreApplication>
#include <QElapsedTimer>
#include <QGuiApplication>
#include <QLoggingCategory>
#include <qpa/qplatformnativeinterface.h>

#include <wayland-client-protocol.h>

Q_LOGGING_CATEGORY(lcToplevel, "hagra.toplevel")

namespace HagraLayerShell {

// ---- Toplevel ----

Toplevel::Toplevel(::zwlr_foreign_toplevel_handle_v1 *handle, ToplevelManager *manager)
    : QObject(manager), QtWayland::zwlr_foreign_toplevel_handle_v1(handle), m_manager(manager)
{
}

Toplevel::~Toplevel()
{
    if (isInitialized())
        destroy();
}

void Toplevel::activate()
{
    if (wl_seat *seat = m_manager->seat())
        QtWayland::zwlr_foreign_toplevel_handle_v1::activate(seat);
    else
        qCWarning(lcToplevel) << "activate: no wl_seat available";
}
void Toplevel::minimize()   { set_minimized(); }
void Toplevel::unminimize() { unset_minimized(); }
void Toplevel::maximize()   { set_maximized(); }
void Toplevel::unmaximize() { unset_maximized(); }
void Toplevel::close()      { QtWayland::zwlr_foreign_toplevel_handle_v1::close(); }

void Toplevel::zwlr_foreign_toplevel_handle_v1_title(const QString &title) { m_title = title; }
void Toplevel::zwlr_foreign_toplevel_handle_v1_app_id(const QString &appId) { m_appId = appId; }

void Toplevel::zwlr_foreign_toplevel_handle_v1_state(wl_array *state)
{
    m_activated = m_minimized = m_maximized = m_fullscreen = false;
    const auto *begin = static_cast<const uint32_t *>(state->data);
    const auto *end = begin + state->size / sizeof(uint32_t);
    for (const uint32_t *it = begin; it != end; ++it) {
        switch (*it) {
        case state_maximized:  m_maximized = true; break;
        case state_minimized:  m_minimized = true; break;
        case state_activated:  m_activated = true; break;
        case state_fullscreen: m_fullscreen = true; break;
        default: break;
        }
    }
}

void Toplevel::zwlr_foreign_toplevel_handle_v1_done()
{
    if (!m_ready) {
        m_ready = true;
        emit ready();
    }
    emit changed();
}

void Toplevel::zwlr_foreign_toplevel_handle_v1_closed()
{
    emit closed();
    deleteLater();
}

// ---- ToplevelManager ----

static ToplevelManager *s_manager = nullptr;

ToplevelManager::ToplevelManager()
    : QWaylandClientExtensionTemplate<ToplevelManager>(3)
{
    initialize();
}

ToplevelManager::~ToplevelManager()
{
    if (s_manager == this)
        s_manager = nullptr;
}

ToplevelManager *ToplevelManager::instance()
{
    if (!s_manager) {
        s_manager = new ToplevelManager();
        s_manager->setParent(QCoreApplication::instance());
        QElapsedTimer timer;
        timer.start();
        while (!s_manager->isActive() && timer.elapsed() < 2000)
            QCoreApplication::processEvents(QEventLoop::AllEvents | QEventLoop::WaitForMoreEvents, 20);
        if (!s_manager->isActive())
            qCWarning(lcToplevel) << "compositor does not advertise zwlr_foreign_toplevel_manager_v1";
    }
    return s_manager;
}

wl_seat *ToplevelManager::seat() const
{
    QPlatformNativeInterface *native = QGuiApplication::platformNativeInterface();
    if (!native)
        return nullptr;
    return static_cast<wl_seat *>(native->nativeResourceForIntegration(QByteArrayLiteral("wl_seat")));
}

void ToplevelManager::zwlr_foreign_toplevel_manager_v1_toplevel(::zwlr_foreign_toplevel_handle_v1 *handle)
{
    auto *toplevel = new Toplevel(handle, this);
    emit toplevelAdded(toplevel);
}

void ToplevelManager::zwlr_foreign_toplevel_manager_v1_finished()
{
    emit finished();
}

} // namespace HagraLayerShell
