// RoundedPopupCard.qml
//
// The panel a bar popup is drawn in: a rounded card with two concave fillets
// along the edge it is attached to, so it reads as growing out of the bar
// rather than floating beside it.
//
// The path is written once, in the bar's own terms -- `u` is depth away from
// the bar, `v` runs along it -- and `point()` turns that into canvas
// coordinates for whichever edge the bar is on. A horizontal bar is the same
// shape a quarter turn round, so there is one path rather than two.
import QtQuick
import "modules" as Modules

Item {
    id: root

    default property alias content: contentItem.data

    property bool smoothBottom

    // Set by a bar that runs along the bottom of the screen: the card is then
    // attached along its own bottom edge and grows upwards.
    property bool horizontal

    property color backgroundColor: Modules.Theme.background
    property color borderColor: Modules.Theme.foreground
    property real outerRadius: 18
    property real innerRadius: 42
    property real padding: 80

    // Depth is measured away from the bar and takes the content's own size;
    // the padding is spent along the bar, half at each end, which is what
    // leaves room for the fillets.
    readonly property real contentDepth:
        horizontal ? contentItem.childrenRect.height : contentItem.childrenRect.width
    readonly property real contentExtent:
        horizontal ? contentItem.childrenRect.width : contentItem.childrenRect.height

    readonly property real depth: Math.max(contentDepth, 10)
    readonly property real extent: Math.max(
        contentExtent + (smoothBottom ? padding - innerRadius : padding), 10)

    implicitWidth: horizontal ? extent : depth
    implicitHeight: horizontal ? depth : extent

    // Force canvas repaint during animated size changes
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    // ...and when the palette changes
    onBackgroundColorChanged: canvas.requestPaint()
    onBorderColorChanged: canvas.requestPaint()
    onHorizontalChanged: canvas.requestPaint()

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

            // How far the card reaches away from the bar, and how far it runs
            // along it, in canvas units.
            const D = root.horizontal ? h : w;
            const E = root.horizontal ? w : h;

            // (depth, along) -> (x, y). Vertical bars sit on the left, so
            // depth is x. Horizontal bars sit at the bottom, so depth is
            // measured upwards from the bottom edge.
            const point = (u, v) => root.horizontal ? [v, h - u] : [u, v];
            const moveTo = (u, v) => { const p = point(u, v); ctx.moveTo(p[0], p[1]); };
            const lineTo = (u, v) => { const p = point(u, v); ctx.lineTo(p[0], p[1]); };
            const curveTo = (cu, cv, u, v) => {
                const c = point(cu, cv);
                const p = point(u, v);
                ctx.quadraticCurveTo(c[0], c[1], p[0], p[1]);
            };

            ctx.clearRect(0, 0, w, h);
            ctx.beginPath();

            moveTo(0, 0);
            curveTo(0, IR, IR, IR);

            lineTo(D - OR, IR);
            curveTo(D, IR, D, IR + OR);

            if (root.smoothBottom) {
                lineTo(D, E);
                lineTo(0, E);
            } else {
                lineTo(D, E - IR - OR);
                curveTo(D, E - IR, D - OR, E - IR);

                lineTo(IR, E - IR);
                curveTo(0, E - IR, 0, E);
            }

            ctx.fillStyle = root.backgroundColor;
            ctx.strokeStyle = root.borderColor;
            ctx.lineWidth = 1;
            ctx.fill();
            ctx.stroke();

            if (root.smoothBottom) {
                // Hide the border along the screen edge the card is flush with.
                ctx.beginPath();
                ctx.strokeStyle = root.backgroundColor;
                ctx.lineWidth = 2;

                const a = point(0, E);
                const b = point(D, E);
                ctx.moveTo(a[0], a[1]);
                ctx.lineTo(b[0], b[1]);

                ctx.stroke();
            }
        }
    }

    // Safe area inside the curved shape: inset along the bar, where the
    // fillets eat into the card, and not at all across its depth.
    //
    // A plain Item rather than a positioner, so whatever goes in it can anchor
    // itself to the edge the card grows out of -- and because a positioner
    // forbids exactly the anchors that needs.
    Item {
        id: contentItem
        anchors.fill: parent
        anchors.topMargin: root.horizontal ? 0 : root.padding / 2
        anchors.bottomMargin: root.horizontal ? 0 : root.padding / 2
        anchors.leftMargin: root.horizontal ? root.padding / 2 : 0
        anchors.rightMargin: root.horizontal ? root.padding / 2 : 0
    }

    layer.enabled: true
    layer.smooth: true
    layer.samples: 1
}
