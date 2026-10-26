// 대표 장면의 비활성 창: 긴 텍스트·줄바꿈·탭·버튼을 보여주는 보조 창 (예제, 실제 메모 앱 아님)
import QtQuick
import MinUI 1.0

Window {
    id: win
    title: "메모 — 긴 텍스트와 줄바꿈 검증"
    width: 420; height: 300
    color: Theme.surface
    visible: true
    Column { anchors.fill: parent; anchors.margins: Theme.paddingLarge; spacing: Theme.paddingLarge
        MTabBar { tabs: ["오늘", "이번 주", "보관함"]; currentIndex: 0; width: parent.width }
        MLabel { width: parent.width; wrap: true
                 text: "하그라는 한국의 미감과 생활에 대한 이해를 바탕으로, 누구나 자기 일을 편안하게 해낼 수 있도록 만드는 운영체제입니다. 긴 문장이 창 너비에 맞게 줄바꿈되고, Hangul·Latin·digits 0123456789 가 한 줄에서 기준선을 공유하는지 확인합니다. 두 번째 문단은 비활성 창에서의 대비를 보기 위한 것입니다." }
        Row { spacing: Theme.padding; anchors.right: parent.right
            MButton { text: "취소" }
            MButton { text: "저장"; defaultButton: true }
        }
    }
}
