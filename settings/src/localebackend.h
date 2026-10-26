// hagra-settings — 언어·지역: 설치된 로케일(locale -a) 중 선택 → ~/.config/hagra/locale.conf (LANG=, LC_TIME= …). hagra-session 이 다음 로그인에 내보낸다.
//   한글 입력기: fcitx5(+hangul) 가 설치되어 있으면 상태·시작을 제공하고, 없으면 설치 안내만 보여 준다.
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class LocaleBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList locales READ locales NOTIFY refreshed)
    Q_PROPERTY(QString currentLang READ currentLang NOTIFY refreshed)     // 세션의 LANG
    Q_PROPERTY(QString savedLang READ savedLang NOTIFY refreshed)         // locale.conf 의 LANG (다음 로그인)
    Q_PROPERTY(QString savedTime READ savedTime NOTIFY refreshed)
    Q_PROPERTY(QVariantMap ime READ ime NOTIFY refreshed)
    Q_PROPERTY(QString timezone READ timezone NOTIFY refreshed)
public:
    explicit LocaleBackend(QObject *parent = nullptr);
    static QString configPath();
    QVariantList locales() const { return m_locales; }
    QString currentLang() const { return qEnvironmentVariable("LANG", QStringLiteral("C")); }
    QString savedLang() const { return m_savedLang; }
    QString savedTime() const { return m_savedTime; }
    QVariantMap ime() const { return m_ime; }
    QString timezone() const { return m_tz; }
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void setLang(const QString &lang);
    Q_INVOKABLE void setTimeFormatLocale(const QString &lc);
    Q_INVOKABLE bool startIme();
    static QVariantList parseLocaleList(const QString &out);
Q_SIGNALS:
    void refreshed();
private:
    QVariantList m_locales;
    QString m_savedLang, m_savedTime, m_tz;
    QVariantMap m_ime;
};
