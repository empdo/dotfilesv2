// RoundedPopupCard.qml
import QtQuick

Item {
    id: root

    default property alias content: contentItem.data

    property bool smoothBottom

    property color backgroundColor: "#1a1a1a"
    property color borderColor: "#ebffd9"
    property real outerRadius: 18
    property real innerRadius: 42
    property real padding: 80

    // Card grows with content + padding
    implicitWidth: Math.max(contentItem.childrenRect.width, 10)
    implicitHeight: smoothBottom ? Math.max(contentItem.childrenRect.height + padding - innerRadius, 10) : Math.max(contentItem.childrenRect.height + padding, 10)

    // Force canvas repaint during animated size changes
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        z: -1
        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            const OR = root.outerRadius;
            const IR = root.innerRadius;

            ctx.strokeStyle = root.borderColor;

            ctx.clearRect(0, 0, w, h);
            ctx.beginPath();

            ctx.moveTo(0, 0);
            ctx.quadraticCurveTo(0, IR, IR, IR);

            ctx.lineTo(w - OR, IR);
            ctx.quadraticCurveTo(w, IR, w, IR + OR);

            if (root.smoothBottom) {
                ctx.lineTo(w, h);
                ctx.lineTo(0, h);
            } else {
                ctx.lineTo(w, h - IR - OR);
                ctx.quadraticCurveTo(w, h - IR, w - OR, h - IR);

                ctx.lineTo(IR, h - IR);
                ctx.quadraticCurveTo(0, h - IR, 0, h);
            }

            ctx.fillStyle = root.backgroundColor;
            ctx.strokeStyle = root.borderColor;
            ctx.lineWidth = 1;
            ctx.fill();
            ctx.stroke();

            if (root.smoothBottom) {
                ctx.beginPath();
                ctx.strokeStyle = root.backgroundColor;
                ctx.lineWidth = 2;

                ctx.moveTo(0, h);
                ctx.lineTo(w, h);

                ctx.stroke();
            }
        }
    }

    // SAFE area inside the curved shape
    Item {
        id: contentArea
        anchors {
            top: parent.top
            bottom: parent.bottom

            // TOP MUST ACCOUNT FOR INNER RADIUS
            topMargin: root.padding / 2

        }
    }

    Column {
        id: contentItem
        anchors.fill: contentArea
        spacing: 10
    }

    layer.enabled: true
    layer.smooth: true
    layer.samples: 1
}
