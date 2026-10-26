// hagra-settings — 배경 이미지 목록: 테마 팩 배경 + /usr/share/hagra/wallpaper + ~/.local/share/hagra/wallpapers + ~/Pictures/Wallpapers (+ ~/사진/배경)
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QVariantList>

class Wallpapers : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList items READ items NOTIFY refreshed)
    Q_PROPERTY(QStringList searchDirs READ searchDirs CONSTANT)
public:
    explicit Wallpapers(QObject *parent = nullptr);
    QVariantList items() const { return m_items; }
    QStringList searchDirs() const;
    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool isImage(const QString &path) const;
    Q_INVOKABLE QString userDir() const;
Q_SIGNALS:
    void refreshed();
private:
    QVariantList m_items;
};
