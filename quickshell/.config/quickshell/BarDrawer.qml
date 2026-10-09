// BarDrawer.qml -- the surface the launcher and the clipboard history open in.
//
// Everything opened from a bar icon grows out of the bar: ExpandableItem puts
// it in a RoundedPopupCard, whose two concave fillets along the attached edge
// make a volume slider read as the bar unfolding rather than as a panel that
// happened to land nearby. The launcher and the clipboard were the two things
// that did not -- centred slabs over a 45% black wash, in radii (10 and 18)
// that matched neither the bar nor each other. The wash covered the bar too,
// so the shell dimmed itself in order to show its own menu.
//
// This is that same card, opened by a keybind instead of by a pointer. The
// window still has to take the whole screen -- a keyboard-driven panel wants
// exclusive focus, and a click anywhere outside it should mean "never mind" --
// but all it *draws* is the card and a wash that stops at the bar.
//
// What goes inside is the panel's business; this owns the shape, where it
// sits, and how it opens. The content is handed a box of a size this works
// out, so it can simply fill its parent.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "modules" as Modules

Scope {
    id: root

    default property alias drawerContent: body.data

    // Distinguishes the two drawers to the compositor, the same way each bar
    // popup's namespace does.
    property string layerNamespace: "quickshell:drawer"

    property bool open: false
    property var targetScreen: null

    // The card is measured in the bar's own terms, as RoundedPopupCard is:
    // `depth` reaches away from the bar, `extent` runs along it. Both are
    // capped so the drawer stays a drawer on a big monitor, and shrink to fit
    // on one too small for the cap. Deeper than the 760 the centred launcher
    // used to be wide, because a drawer is read down its length and wants the
    // rows to be the long dimension.
    property real maxDepth: 720
    property real maxExtent: 1040

    // The card is pulled one pixel into the bar, so the bar's edge line runs
    // *behind* it instead of up against it. Butted together, the line reads as
    // a seam between two surfaces; hidden under the card, the bar and the
    // drawer are one surface for as far as the card reaches, and the line
    // picks up again above and below it. One pixel because that is what the
    // bar draws its edge at.
    property real barOverlap: 1

    // How far the desktop behind the card falls back. Theme.background rather
    // than black: in the light palette a black wash is a hole in the screen,
    // where this one only sets the desktop back into the shell's own colour.
    property real washOpacity: 0.42

    // The output the drawer opens on, and how big it is.
    //
    // Measured off the screen rather than off `overlay`, even though the window
    // covers exactly that screen. A PanelWindow reports a placeholder size
    // until the compositor first maps it -- 100x100, then briefly 0x0 -- and
    // the card is a good deal smaller than its screen, so a box measured off
    // that placeholder comes out *negative*. A QtQuick layout handed a negative
    // box lays nothing out, and whether it ever recovers depends on which frame
    // the real size arrives in: at login, with the outputs still coming up, it
    // did not, and the clipboard drawer opened as a card with its contents
    // collapsed into a heap at the middle. `show()` resolves the screen before
    // the window is told to appear, so measured this way the box is the right
    // size on the very first pass and never changes afterwards.
    readonly property var drawerScreen: root.targetScreen || overlay.screen

    readonly property bool horizontal: Modules.Shell.barIsHorizontal(root.drawerScreen)

    readonly property real screenDepth:
        root.drawerScreen ? (root.horizontal ? root.drawerScreen.height : root.drawerScreen.width) : 0
    readonly property real screenExtent:
        root.drawerScreen ? (root.horizontal ? root.drawerScreen.width : root.drawerScreen.height) : 0

    // Clamped at both ends: a screen too small for the caps shrinks the card,
    // and one too small for the bar and the margins leaves nothing rather than
    // less than nothing.
    readonly property real depth: Math.max(0, Math.min(
        root.screenDepth - Modules.Shell.barThickness - 80, root.maxDepth))
    readonly property real extent: Math.max(0, Math.min(
        root.screenExtent - 80, root.maxExtent))

    // The content box.
    //
    // RoundedPopupCard keeps `padding` clear along the bar, but that is room
    // for the fillets to be cut out of rather than margin, and the card's flat
    // face does not begin until `innerRadius`. Content inset to the card's own
    // padding/2 therefore lands two pixels *outside* the shape at either end --
    // near enough for a volume slider, but it is what sat the launcher's hint
    // row on the card's bottom edge. Measured off the flat face instead, with
    // a margin of its own.
    readonly property real endInset: card.innerRadius + 16

    readonly property real contentDepth: Math.max(0, root.depth - 44)
    readonly property real contentExtent: Math.max(0, root.extent - 2 * root.endInset)

    function show() {
        // Resolved before the window is told to show itself, so it never maps
        // on one output and then moves to another.
        root.targetScreen = Modules.Shell.focusedScreen();
        root.open = true;
    }

    function hide() {
        root.open = false;
    }

    PanelWindow {
        id: overlay
        visible: root.open
        color: "transparent"
        screen: root.targetScreen

        anchors { top: true; left: true; right: true; bottom: true }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: root.layerNamespace
        exclusionMode: ExclusionMode.Ignore

        // A click that lands anywhere but the card is "never mind" -- the bar
        // included, which this window covers even though it does not wash it.
        MouseArea {
            anchors.fill: parent
            onClicked: root.hide()
        }

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: root.horizontal ? 0 : Modules.Shell.barThickness
            anchors.bottomMargin: root.horizontal ? Modules.Shell.barThickness : 0
            color: Modules.Theme.background
            opacity: root.washOpacity
        }

        // Swallows clicks over the card so they do not reach the layer above.
        // Matched to the card rather than to its contents, because the strips
        // the fillets are cut out of are part of the card too -- clicking one
        // should not dismiss it.
        MouseArea {
            x: card.x
            y: card.y
            width: card.width
            height: card.height
        }

        RoundedPopupCard {
            id: card
            horizontal: root.horizontal

            // Over the bar's edge line, centred along the bar.
            anchors.left: root.horizontal ? undefined : parent.left
            anchors.leftMargin: Modules.Shell.barThickness - root.barOverlap
            anchors.verticalCenter: root.horizontal ? undefined : parent.verticalCenter
            anchors.bottom: root.horizontal ? parent.bottom : undefined
            anchors.bottomMargin: Modules.Shell.barThickness - root.barOverlap
            anchors.horizontalCenter: root.horizontal ? parent.horizontalCenter : undefined

            // Opens by growing out of the bar, in the 200ms the bar's own
            // popups take. What animates is the depth; which axis that is
            // depends on which edge the bar is on, and the other is set
            // outright. Closing is not animated, for the same reason the bar's
            // popups do not animate theirs: the window is gone by then.
            width: root.horizontal ? root.extent : (overlay.visible ? root.depth : 0)
            height: root.horizontal ? (overlay.visible ? root.depth : 0) : root.extent

            Behavior on width {
                enabled: !root.horizontal
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                enabled: root.horizontal
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Item {
                id: body

                // Pinned to the edge the card grows from -- the margin measured
                // off the animating edge, so the contents stay put by the bar
                // while the shape opens around them -- and centred on the other
                // axis.
                //
                // Placed rather than anchored, because which anchors those are
                // depends on the bar's edge, and swapping a set of anchors for
                // another set is not the single step it reads as: for the frame
                // in between, a drawer opening on the rotated monitor had both
                // `verticalCenter` and `bottom` attached, which is enough for
                // the anchor system to take `height` over from the binding
                // above and keep whatever value it had mid-animation. The
                // drawer then stood a couple of hundred pixels taller than its
                // own card, with the search field and the first rows of the
                // list up past the top edge where nothing draws.
                x: root.horizontal
                 ? (parent.width - width) / 2
                 : 22 + root.barOverlap
                y: root.horizontal
                 ? parent.height - height - (22 + root.barOverlap)
                 : (parent.height - height) / 2

                width: root.horizontal ? root.contentExtent : root.contentDepth
                height: root.horizontal ? root.contentDepth : root.contentExtent
            }
        }
    }
}
