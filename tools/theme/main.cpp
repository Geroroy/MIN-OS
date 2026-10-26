// hagra-theme — 테마 선택 명령줄 도구 (세션 스크립트·테스트·사용자용)
//   hagra-theme list                 테마 ID, 표시 이름, [current]/[default]
//   hagra-theme current              현재 선택된 테마 ID
//   hagra-theme apply ID             선택·저장·세션 반영 (labwc --reconfigure, swaybg 재시작). 알 수 없는 ID 면 기본 테마로 복귀, 종료 코드 2
//   hagra-theme reset                기본 테마로 복귀
//   hagra-theme sync                 저장된 선택으로 관리 상태 파일을 다시 쓴다 (세션 시작 시; 세션 반영 없음)
//   hagra-theme wallpaper            적용할 배경 경로 (사용자 지정 > 테마 기본 > 기본 테마)
//   hagra-theme wallpaper-fill       배경 바깥 색 (#RRGGBB)
//   hagra-theme state-dir            관리 상태 디렉터리 (themerc-override, wallpaper, current)
//   hagra-theme set-wallpaper PATH   사용자 배경 지정 (테마 기본 배경 사용 해제)
//   hagra-theme use-theme-wallpaper  테마 기본 배경 사용으로 되돌림
//   hagra-theme tokens [ID]          토큰 JSON 출력 (HagraUI.Theme.applyTokens 형식)
// SPDX-License-Identifier: GPL-3.0-or-later
#include <QCoreApplication>
#include <QLoggingCategory>
#include <QJsonDocument>
#include <QTextStream>
#include <cstdio>

#include "hagratheme/thememanager.h"

using HagraTheme::ThemeManager;

int main(int argc, char *argv[])
{
    QLoggingCategory::setFilterRules(QStringLiteral("hagra.theme.debug=false"));
    QCoreApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("hagra-theme"));
    const QStringList args = app.arguments().mid(1);
    QTextStream out(stdout);
    if (args.isEmpty() || args[0] == QLatin1String("--help") || args[0] == QLatin1String("-h")) {
        out << "usage: hagra-theme list|current|apply ID|reset|sync|wallpaper|wallpaper-fill|state-dir|set-wallpaper PATH|use-theme-wallpaper|tokens [ID]\n";
        return args.isEmpty() ? 2 : 0;
    }
    ThemeManager mgr;
    const QString cmd = args[0];
    if (cmd == QLatin1String("list")) {
        for (const auto &t : mgr.themes())
            out << t.id << '\t' << t.displayName << (t.id == mgr.currentId() ? "\t[current]" : "") << (t.id == mgr.defaultId() ? "\t[default]" : "") << '\n';
        return 0;
    }
    if (cmd == QLatin1String("current")) { out << mgr.currentId() << '\n'; return 0; }
    if (cmd == QLatin1String("apply")) {
        if (args.size() < 2) { out << "apply: theme ID required\n"; return 2; }
        const bool ok = mgr.apply(args[1], true);
        out << mgr.currentId() << '\n';
        return ok ? 0 : 2;
    }
    if (cmd == QLatin1String("reset")) { mgr.resetToDefault(); out << mgr.currentId() << '\n'; return 0; }
    if (cmd == QLatin1String("sync")) { const bool ok = mgr.syncState(); out << mgr.currentId() << '\n'; return ok ? 0 : 1; }
    if (cmd == QLatin1String("wallpaper")) { out << mgr.effectiveWallpaper() << '\n'; return mgr.effectiveWallpaper().isEmpty() ? 1 : 0; }
    if (cmd == QLatin1String("wallpaper-fill")) { out << mgr.current().wallpaperFill << '\n'; return 0; }
    if (cmd == QLatin1String("state-dir")) { out << ThemeManager::stateDir() << '\n'; return 0; }
    if (cmd == QLatin1String("set-wallpaper")) {
        if (args.size() < 2) { out << "set-wallpaper: path required\n"; return 2; }
        mgr.setUserWallpaper(args[1]);
        out << mgr.effectiveWallpaper() << '\n';
        return 0;
    }
    if (cmd == QLatin1String("use-theme-wallpaper")) { mgr.setUseThemeWallpaper(true); out << mgr.effectiveWallpaper() << '\n'; return 0; }
    if (cmd == QLatin1String("tokens")) {
        const auto t = args.size() > 1 ? mgr.theme(args[1]) : mgr.current();
        out << QJsonDocument::fromVariant(mgr.tokensFor(t)).toJson() << '\n';
        return t.valid() ? 0 : 2;
    }
    out << "unknown command: " << cmd << '\n';
    return 2;
}
