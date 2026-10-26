// 하그라 셸 — 앱 아이콘 이미지 공급자. QML: Image { source: "image://appicon/<Icon= 값>" }
//   1) 절대 경로(PNG/SVG/XPM)  2) 아이콘 테마 조회(QIcon::fromTheme: hicolor + 설치된 테마, /usr/share/icons)  3) /usr/share/pixmaps/<name>.{svg,png,xpm}
//   실패하면 빈 이미지 → QML 쪽에서 HagraUI 자리 표시자(머리글자)로 대체한다.
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QQuickImageProvider>

class AppIconProvider : public QQuickImageProvider
{
public:
    AppIconProvider();
    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override;
    /// 아이콘 이름/경로를 실제 파일로 해석 (테스트용). 못 찾으면 빈 문자열.
    static QString resolve(const QString &iconName);
    static void setupTheme();
};
