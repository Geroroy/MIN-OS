// MIN Shell — 작업 표시줄용 창 목록 모델 (wlr-foreign-toplevel-management)
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QAbstractListModel>
#include <QList>

namespace MinLayerShell { class Toplevel; class ToplevelManager; }

class ToplevelModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(bool available READ isAvailable NOTIFY availableChanged)
public:
    enum Roles { TitleRole = Qt::UserRole + 1, AppIdRole, ActivatedRole, MinimizedRole, MaximizedRole };
    explicit ToplevelModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int count() const { return m_items.size(); }
    bool isAvailable() const { return m_available; }

    Q_INVOKABLE void activate(int row);
    Q_INVOKABLE void minimize(int row);
    Q_INVOKABLE void close(int row);
    /// 작업 표시줄 클릭 동작: 활성 창이면 최소화, 아니면 활성화(+복원).
    Q_INVOKABLE void toggle(int row);

Q_SIGNALS:
    void countChanged();
    void availableChanged();

private:
    void add(MinLayerShell::Toplevel *t);
    void remove(MinLayerShell::Toplevel *t);
    void changed(MinLayerShell::Toplevel *t);

    QList<MinLayerShell::Toplevel *> m_items;
    bool m_available = false;
};
