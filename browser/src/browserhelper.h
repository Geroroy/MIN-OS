// 하그라 브라우저 — QML 에 노출되는 도우미: 주소 입력 해석, 검색 엔진, 시작 페이지의 자주 가는 곳, 저장 경로, 데스크톱 알림.
//   설정: ~/.config/hagra/browser.conf   [browser] search=<id> · shortcuts=<제목>\t<주소> 목록
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QLoggingCategory>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QUrl>
#include <QVariantList>

Q_DECLARE_LOGGING_CATEGORY(lcBrowser)

class BrowserHelper : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString searchEngine READ searchEngine WRITE setSearchEngine NOTIFY searchEngineChanged)
    Q_PROPERTY(QVariantList searchEngines READ searchEngines CONSTANT)
    Q_PROPERTY(QVariantList shortcuts READ shortcuts NOTIFY shortcutsChanged)
    Q_PROPERTY(QString storagePath READ storagePath CONSTANT)
    Q_PROPERTY(QString cachePath READ cachePath CONSTANT)
    Q_PROPERTY(bool storageWritable READ storageWritable CONSTANT)
    Q_PROPERTY(QString downloadDir READ downloadDir CONSTANT)
    Q_PROPERTY(QString acceptLanguage READ acceptLanguage CONSTANT)
public:
    explicit BrowserHelper(QObject *parent = nullptr);

    /// 주소 표시줄 입력 → 열 주소. 주소처럼 보이면 그대로(스킴이 없으면 https://, localhost·IP 는 http://), 아니면 검색 주소.
    Q_INVOKABLE QString fixup(const QString &input) const;
    /// 검색 주소 (현재 검색 엔진)
    Q_INVOKABLE QString searchUrl(const QString &query) const;
    /// 사람이 읽기 좋은 주소 (표시줄 비초점 상태용): 퍼센트 인코딩을 풀고 한글 도메인은 유니코드로 보인다
    Q_INVOKABLE QString displayUrl(const QUrl &url) const;
    /// 탭 제목이 없을 때 쓰는 짧은 이름 (호스트 또는 파일 이름)
    Q_INVOKABLE QString shortName(const QUrl &url) const;

    QString searchEngine() const { return m_search; }
    void setSearchEngine(const QString &id);
    QVariantList searchEngines() const;

    QVariantList shortcuts() const;
    Q_INVOKABLE bool hasShortcut(const QString &url) const;
    Q_INVOKABLE void addShortcut(const QString &title, const QString &url);
    Q_INVOKABLE void removeShortcut(const QString &url);
    Q_INVOKABLE void toggleShortcut(const QString &title, const QString &url);

    QString storagePath() const;
    QString cachePath() const;
    /// 프로필·캐시 디렉터리를 만들고 쓸 수 있는지. 아니면 QML 은 메모리 전용(사생활 보호) 프로필로 돈다.
    bool storageWritable() const;
    QString downloadDir() const;
    QString acceptLanguage() const;

    /// org.freedesktop.Notifications 로 알림을 보낸다 (하그라 셸 알림 서버). 실패하면 false.
    Q_INVOKABLE bool notify(const QString &title, const QString &body) const;

    /// 진단 기록 (hagra.browser 범주; 헤드리스 검사가 읽는다)
    Q_INVOKABLE void log(const QString &message) const;

    static QString configPath();

signals:
    void searchEngineChanged();
    void shortcutsChanged();

private:
    struct Shortcut { QString title; QString url; };
    void load();
    void save() const;
    static QStringList defaultShortcuts();
    QString m_search;
    QList<Shortcut> m_shortcuts;
};
