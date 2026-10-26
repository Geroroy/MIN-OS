// hagra-settings — 키보드·마우스: ~/.config/hagra/input.conf 에 저장하고 labwc 설정으로 렌더링한다.
//   [keyboard] layout=us,kr variant= options=grp:alt_shift_toggle repeatRate=25 repeatDelay=600
//   [pointer]  tap=true naturalScroll=false leftHanded=false speed=0.0 (−1..1)
//   렌더링: 시스템 rc.xml → <libinput>/<keyboard> 값을 바꿔 세션 설정 디렉터리에 쓴다 (hagra-session 이 호출). 키보드 배치는 environment 파일의 XKB_DEFAULT_* 로.
//   적용: 렌더링 후 labwc --reconfigure (libinput 값은 즉시, 배치는 labwc 가 environment 를 다시 읽을 때).
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class InputBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap values READ values NOTIFY changed)
    Q_PROPERTY(QVariantList layouts READ layouts CONSTANT)
    Q_PROPERTY(bool sessionApplySupported READ sessionApplySupported CONSTANT)
    Q_PROPERTY(QString configPath READ configPath CONSTANT)
public:
    explicit InputBackend(QObject *parent = nullptr);
    static QString configPath();
    QVariantMap values() const { return m_values; }
    QVariantList layouts() const;   // xkb evdev.lst 의 ! layout 목록 [{code, name}]
    bool sessionApplySupported() const;

    Q_INVOKABLE void reload();
    Q_INVOKABLE void set(const QString &key, const QVariant &value);   // "keyboard/layout" 등. 저장 + 세션 적용
    Q_INVOKABLE bool applyToSession();
    Q_INVOKABLE void resetAll();

    /// rc.xml 텍스트에 input.conf 값을 적용한 결과 (단위 테스트 대상)
    static QString renderRc(const QString &rcXml, const QVariantMap &values, QString *error = nullptr);
    static QString renderEnvironment(const QString &envText, const QVariantMap &values);
    /// 세션 설정 디렉터리(hagra-session 의 CONF) 에 rc.xml/environment 를 다시 쓴다. 반환: 성공 여부.
    static bool renderInto(const QString &confDir, const QString &sysDir, const QVariantMap &values, QString *error = nullptr);
    static QVariantMap load();
Q_SIGNALS:
    void changed();
private:
    QVariantMap m_values;
};
