// MIN Shell — 애플리케이션 색인 (freedesktop .desktop 스캔) 및 실행
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QAbstractListModel>
#include <QStringList>
#include <optional>

struct AppEntry {
    QString id;        // 예: org.codeberg.dnkl.foot (파일명에서 .desktop 제거)
    QString name;
    QString genericName;
    QString comment;
    QString icon;
    QString exec;      // 필드 코드 제거 전 원본
    QString path;      // 작업 디렉터리 (Path=)
    QStringList keywords;
    QStringList categories;
    bool terminal = false;
    bool noDisplay = false;
};

class AppIndex : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY countChanged)

public:
    enum Roles { NameRole = Qt::UserRole + 1, CommentRole, IconRole, ExecRole, IdRole, TerminalRole };

    explicit AppIndex(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString filter() const { return m_filter; }
    void setFilter(const QString &filter);
    int count() const { return m_visible.size(); }
    int totalCount() const { return m_all.size(); }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool launch(int row);
    Q_INVOKABLE bool launchById(const QString &id);
    /// 임의 명령 실행 (예: 터미널). inTerminal=true 이면 터미널 안에서 실행.
    Q_INVOKABLE bool launchCommand(const QString &command, bool inTerminal = false);
    Q_INVOKABLE QString terminalProgram() const;

    // 테스트 가능한 순수 함수들
    static std::optional<AppEntry> parseDesktopFile(const QString &filePath, const QStringList &localeKeys);
    static QStringList execToArgs(const QString &exec);
    static QStringList localeKeys();                 // 예: ["ko_KR", "ko"]
    static QStringList applicationDirs();            // XDG 규칙에 따른 applications/ 디렉터리 목록
    static QList<AppEntry> scan(const QStringList &dirs, const QString &currentDesktop);
    static bool matchesFilter(const AppEntry &entry, const QString &needle, int *score);

Q_SIGNALS:
    void filterChanged();
    void countChanged();
    void launched(const QString &id);
    void launchFailed(const QString &id, const QString &reason);

private:
    bool startEntry(const AppEntry &entry);
    void rebuildVisible();

    QList<AppEntry> m_all;
    QList<int> m_visible;   // m_all 인덱스
    QString m_filter;
};
