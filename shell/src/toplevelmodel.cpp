// SPDX-License-Identifier: GPL-3.0-or-later
#include "toplevelmodel.h"
#include "hagralayershell/foreigntoplevel.h"

using HagraLayerShell::Toplevel;
using HagraLayerShell::ToplevelManager;

ToplevelModel::ToplevelModel(QObject *parent)
    : QAbstractListModel(parent)
{
    ToplevelManager *mgr = ToplevelManager::instance();
    m_available = mgr && mgr->isActive();
    if (!m_available)
        return;
    connect(mgr, &ToplevelManager::toplevelAdded, this, [this](Toplevel *t) {
        // 첫 done 이후에만 목록에 넣어 제목 없는 항목이 잠깐 보이는 것을 막는다.
        connect(t, &Toplevel::ready, this, [this, t] { add(t); });
        connect(t, &Toplevel::closed, this, [this, t] { remove(t); });
    });
}

int ToplevelModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_items.size();
}

QVariant ToplevelModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_items.size())
        return {};
    const Toplevel *t = m_items.at(index.row());
    switch (role) {
    case TitleRole: case Qt::DisplayRole: return t->title().isEmpty() ? t->appId() : t->title();
    case AppIdRole: return t->appId();
    case ActivatedRole: return t->isActivated();
    case MinimizedRole: return t->isMinimized();
    case MaximizedRole: return t->isMaximized();
    default: return {};
    }
}

QHash<int, QByteArray> ToplevelModel::roleNames() const
{
    return { { TitleRole, "title" }, { AppIdRole, "appId" }, { ActivatedRole, "activated" },
             { MinimizedRole, "minimized" }, { MaximizedRole, "maximized" } };
}

void ToplevelModel::add(Toplevel *t)
{
    if (m_items.contains(t))
        return;
    beginInsertRows({}, m_items.size(), m_items.size());
    m_items.append(t);
    endInsertRows();
    connect(t, &Toplevel::changed, this, [this, t] { changed(t); });
    emit countChanged();
}

void ToplevelModel::remove(Toplevel *t)
{
    const int row = m_items.indexOf(t);
    if (row < 0)
        return;
    beginRemoveRows({}, row, row);
    m_items.removeAt(row);
    endRemoveRows();
    emit countChanged();
}

void ToplevelModel::changed(Toplevel *t)
{
    const int row = m_items.indexOf(t);
    if (row >= 0)
        emit dataChanged(index(row), index(row));
}

void ToplevelModel::activate(int row) { if (row >= 0 && row < m_items.size()) { m_items[row]->unminimize(); m_items[row]->activate(); } }
void ToplevelModel::minimize(int row) { if (row >= 0 && row < m_items.size()) m_items[row]->minimize(); }
void ToplevelModel::close(int row)    { if (row >= 0 && row < m_items.size()) m_items[row]->close(); }
void ToplevelModel::toggle(int row)
{
    if (row < 0 || row >= m_items.size()) return;
    Toplevel *t = m_items[row];
    if (t->isActivated() && !t->isMinimized()) t->minimize();
    else activate(row);
}
