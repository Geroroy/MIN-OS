// 탭 하나 = WebEngineView 하나. 창(Main.qml)의 함수로 새 창 요청·전체 화면·권한·문맥 메뉴·찾기 결과를 넘긴다.
import QtQuick
import QtWebEngine
import HagraBrowser 1.0

WebEngineView {
    id: view
    property var browser: null           // Main.qml 의 창
    property bool showStart: true         // 시작 페이지(새 탭)를 보이는 중. 탐색이 시작되면 false
    property bool crashed: false          // 렌더러 프로세스가 비정상 종료됨
    property url hoveredUrl: ""
    property int findMatches: -1          // 찾기 결과 (−1: 찾지 않음)
    property int findActive: 0
    property bool everLoaded: false       // 페이지를 한 번이라도 다 불러왔나 (내려받기만 하려고 열린 탭 구분용)
    readonly property string displayTitle: showStart ? qsTr("새 탭")
                                         : title.length ? title
                                         : url.toString().length ? Browser.shortName(url) : qsTr("불러오는 중")

    visible: browser !== null && browser.current === view && !showStart
    settings.fullScreenSupportEnabled: true
    settings.pluginsEnabled: true          // 내장 PDF 보기
    settings.pdfViewerEnabled: true
    settings.focusOnNavigationEnabled: true
    settings.dnsPrefetchEnabled: true

    onLoadingChanged: function(request) {
        if (request.status === WebEngineView.LoadStartedStatus) { showStart = false; crashed = false }
        else if (request.status === WebEngineView.LoadSucceededStatus) { everLoaded = true; Browser.log("loaded " + request.url + " — " + title) }
        else if (request.status === WebEngineView.LoadFailedStatus) Browser.log("load failed " + request.url + " (" + request.errorString + ")")
    }
    onNewWindowRequested: function(request) { browser.openNewWindowRequest(view, request) }
    onFullScreenRequested: function(request) { request.accept(); browser.setPageFullScreen(view, request.toggleOn) }
    onFeaturePermissionRequested: function(securityOrigin, feature) { browser.askPermission(view, securityOrigin, feature) }
    onContextMenuRequested: function(request) { request.accepted = true; browser.showContextMenu(view, request) }
    onWindowCloseRequested: browser.closeTab(view)
    onLinkHovered: function(url) { hoveredUrl = url }
    onFindTextFinished: function(result) { findMatches = result.numberOfMatches; findActive = result.activeMatch }
    onCertificateError: function(error) { error.rejectCertificate() }   // 인증서 오류는 거부 (Chromium 오류 페이지)
    onRenderProcessTerminated: function(status, exitCode) {
        if (status !== WebEngineView.NormalTerminationStatus) { crashed = true; Browser.log("render process terminated: status " + status + " code " + exitCode) }
    }
}
