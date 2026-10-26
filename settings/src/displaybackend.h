// hagra-settings — 디스플레이: wlr-randr 로 출력·모드·배율을 읽고 적용한다 (labwc 0.7 은 wlr-output-management 를 지원).
//   저장: ~/.config/hagra/display.conf  [output.<NAME>] mode=WxH@R scale=S transform=T enabled=1
//   세션 시작 시 `hagra-settings --apply` 가 저장된 값을 다시 적용한다 (labwc 는 출력 설정을 저장하지 않는다).
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QVariantList>
#include <QVariantMap>

struct OutputMode { int width = 0, height = 0; double refresh = 0; bool current = false, preferred = false; QString label() const; };
struct OutputInfo {
    QString name, description, make, model;
    bool enabled = true;
    QList<OutputMode> modes;
    int x = 0, y = 0;
    QString transform = QStringLiteral("normal");
    double scale = 1.0;
    QString currentMode() const;
};

class DisplayBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY refreshed)
    Q_PROPERTY(QString reason READ reason NOTIFY refreshed)
    Q_PROPERTY(QVariantList outputs READ outputsForQml NOTIFY refreshed)
public:
    explicit DisplayBackend(QObject *parent = nullptr);
    static QString configPath();
    static QList<OutputInfo> parse(const QString &wlrRandrText);   // 단위 테스트 대상

    bool available() const { return m_available; }
    QString reason() const { return m_reason; }
    QVariantList outputsForQml() const;
    QList<OutputInfo> outputs() const { return m_outputs; }

    Q_INVOKABLE void refresh();
    /// 출력 하나에 모드·배율·변환·활성 적용. 성공하면 저장하고 true. mode: "WxH@R" 또는 "WxH", scale: 0 이면 유지.
    Q_INVOKABLE bool apply(const QString &output, const QString &mode, double scale, const QString &transform, bool enabled, bool persist = true);
    Q_INVOKABLE bool setPosition(const QString &output, int x, int y, bool persist = true);
    /// 저장된 설정 제거 (현재 세션은 그대로)
    Q_INVOKABLE void forget(const QString &output);
    Q_INVOKABLE bool hasSaved(const QString &output) const;
    /// 저장된 값을 현재 세션에 적용 (세션 시작 시). 적용한 출력 수.
    int applySaved();

Q_SIGNALS:
    void refreshed();
    void error(const QString &message);

private:
    bool m_available = false;
    QString m_reason;
    QList<OutputInfo> m_outputs;
};
