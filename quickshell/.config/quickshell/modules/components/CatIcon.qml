// CatIcon.qml -- the cat at the top of the bar.
//
// Generated from `icon/cat.svg` with Qt's own converter and then given two
// properties, so the drawing is real geometry rather than a picture of one:
// `color` fills its lines, and `lineWidth` sets how thick they are.
//
//     /usr/lib/qt6/bin/svgtoqml icon/cat.svg CatIcon.qml
//
// After regenerating, reapply the three substitutions below -- the black the
// SVG was drawn in becomes `root.color`, and the exported stroke width becomes
// `root.localLineWidth`:
//
//     strokeColor: "#ff000000"  ->  strokeColor: root.color
//     fillColor:   "#ff000000"  ->  fillColor: root.color
//     strokeWidth: 1.44         ->  strokeWidth: root.localLineWidth
//
// Krita exported the lines at 1.44 units in a 345.6 viewBox -- 0.4% of the
// icon's width, which at bar size is a tenth of a pixel and renders as nothing
// at all. Rather than redrawing it thicker, `lineWidth` is stated in screen
// pixels and converted back into the drawing's own units here, so the cat
// keeps the same weight of line whatever size it is drawn at.
import QtQuick
import QtQuick.Shapes
// TransformGroup and PlanarTransform, which the converter's output is built
// from; both are ordinary Qt modules, nothing is being vendored here.
import QtQuick.VectorImage.Helpers
import "../" as Modules

Item {
    id: root

    // Defaults to whichever way round the theme currently is, so the cat is
    // light on the dark palette and dark on the light one, and cross-fades
    // between them with everything else.
    property color color: Modules.Theme.foreground

    // Line thickness in screen pixels, independent of how big the icon is.
    property real lineWidth: 1.6

    readonly property real viewBoxSize: 345.6
    readonly property real localLineWidth:
        root.width > 0 ? root.lineWidth * root.viewBoxSize / root.width : 1.44

    implicitWidth: 345
    implicitHeight: 345
    transform: [
        Scale { xScale: width / 345.6; yScale: height / 345.6 }
    ]
    transformOrigin: Item.TopLeft
    Shape {
        objectName: "shape0"
        id: _qt_node1
        transformOrigin: Item.TopLeft
        transform: TransformGroup {
            id: _qt_node1_transform_base_group
            Translate { x: 60.4511; y: 78.942}
        }
        ShapePath {
            id: _qt_node1_fill_stroke
            objectName: "svg_path:shape0"
            strokeColor: root.color
            strokeWidth: root.localLineWidth
            capStyle: ShapePath.SquareCap
            joinStyle: ShapePath.BevelJoin
            miterLimit: 4
            fillColor: "#00000000"
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 84.5389 22.038 C 77.6989 9.61797 69.5989 2.86797 60.2389 1.78797 C 46.1989 0.167974 5.15886 55.788 1.37886 117.618 C -2.40114 179.448 -0.540189 184.308 34.8589 203.208 C 54.4581 213.672 93.9136 211.512 125.088 209.435 C 150.218 205.148 176.056 188.738 177.149 187.818 C 188.354 189.993 198.299 190.098 206.984 188.133 C 234.144 179.937 246.908 163.482 245.279 138.768 C 243.119 106.008 230.399 95.268 207.119 106.548 C 199.559 115.008 201.539 124.008 213.059 133.548 C 230.339 147.858 206.849 166.218 201.719 166.488 C 198.299 166.668 193.979 166.938 188.759 167.298 C 191.993 105.696 184.793 59.4964 167.159 28.698 C 157.807 12.3656 149.606 2.80816 142.553 0.0255293 C 134.447 -0.472811 125.369 6.32467 115.319 20.418 C 110.34 20.2314 108.871 18.0311 99.0322 18.0705 L 93.7795 18.722 L 84.5389 22.038 " }
        }
    }
    Shape {
        objectName: "shape1"
        id: _qt_node2
        transformOrigin: Item.TopLeft
        transform: TransformGroup {
            id: _qt_node2_transform_base_group
            Translate { x: 181.44; y: 135.36}
        }
        ShapePath {
            id: _qt_node2_fill_stroke
            objectName: "svg_path:shape1"
            strokeColor: root.color
            strokeWidth: root.localLineWidth
            capStyle: ShapePath.SquareCap
            joinStyle: ShapePath.BevelJoin
            miterLimit: 4
            fillColor: root.color
            fillRule: ShapePath.OddEvenFill
            PathSvg { path: "M 17.28 14.4 C 17.28 22.3529 13.4117 28.8 8.64 28.8 C 3.86826 28.8 0 22.3529 0 14.4 C 0 6.4471 3.86826 0 8.64 0 C 13.4117 0 17.28 6.4471 17.28 14.4 " }
        }
    }
    Shape {
        objectName: "shape2"
        id: _qt_node3
        transformOrigin: Item.TopLeft
        transform: TransformGroup {
            id: _qt_node3_transform_base_group
            Translate { x: 113.58; y: 132.12}
        }
        ShapePath {
            id: _qt_node3_fill_stroke
            objectName: "svg_path:shape2"
            strokeColor: root.color
            strokeWidth: root.localLineWidth
            capStyle: ShapePath.SquareCap
            joinStyle: ShapePath.BevelJoin
            miterLimit: 4
            fillColor: root.color
            fillRule: ShapePath.OddEvenFill
            PathSvg { path: "M 17.37 14.76 C 17.37 22.9117 13.4816 29.52 8.685 29.52 C 3.88841 29.52 0 22.9117 0 14.76 C 0 6.60828 3.88841 0 8.685 0 C 13.4816 0 17.37 6.60828 17.37 14.76 " }
        }
    }
    Shape {
        objectName: "shape01"
        id: _qt_node4
        transformOrigin: Item.TopLeft
        transform: TransformGroup {
            id: _qt_node4_transform_base_group
            Matrix4x4 { matrix: PlanarTransform.fromAffineMatrix(0.521559, 0.853215, -0.853215, 0.521559, 217.442, 156.147)}
        }
        ShapePath {
            id: _qt_node4_fill_stroke
            objectName: "svg_path:shape01"
            strokeColor: root.color
            strokeWidth: root.localLineWidth
            capStyle: ShapePath.SquareCap
            joinStyle: ShapePath.BevelJoin
            miterLimit: 4
            fillColor: root.color
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 7.07138 7.59589 C 7.07138 11.791 5.4884 15.1918 3.53569 15.1918 C 1.58298 15.1918 0 11.791 0 7.59589 C 0 3.4008 1.58298 0 3.53569 0 C 5.4884 0 7.07138 3.4008 7.07138 7.59589 " }
        }
    }
    Shape {
        objectName: "shape02"
        id: _qt_node5
        transformOrigin: Item.TopLeft
        transform: TransformGroup {
            id: _qt_node5_transform_base_group
            Matrix4x4 { matrix: PlanarTransform.fromAffineMatrix(-0.0804174, 0.996761, -0.996761, -0.0804174, 224.427, 170.639)}
        }
        ShapePath {
            id: _qt_node5_fill_stroke
            objectName: "svg_path:shape02"
            strokeColor: root.color
            strokeWidth: root.localLineWidth
            capStyle: ShapePath.SquareCap
            joinStyle: ShapePath.BevelJoin
            miterLimit: 4
            fillColor: root.color
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 7.07138 7.59589 C 7.07138 11.791 5.4884 15.1918 3.53569 15.1918 C 1.58298 15.1918 0 11.791 0 7.59589 C 0 3.4008 1.58298 0 3.53569 0 C 5.4884 0 7.07138 3.4008 7.07138 7.59589 " }
        }
    }
    Shape {
        objectName: "shape03"
        id: _qt_node6
        transformOrigin: Item.TopLeft
        transform: TransformGroup {
            id: _qt_node6_transform_base_group
            Matrix4x4 { matrix: PlanarTransform.fromAffineMatrix(-0.566474, 0.853215, 0.926692, 0.521559, 90.7012, 151.083)}
        }
        ShapePath {
            id: _qt_node6_fill_stroke
            objectName: "svg_path:shape03"
            strokeColor: root.color
            strokeWidth: root.localLineWidth
            capStyle: ShapePath.SquareCap
            joinStyle: ShapePath.BevelJoin
            miterLimit: 4
            fillColor: root.color
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 6.51461 7.29432 C 6.51461 11.3229 5.05626 14.5886 3.25731 14.5886 C 1.45835 14.5886 0 11.3229 0 7.29432 C 0 3.26578 1.45835 0 3.25731 0 C 5.05626 0 6.51461 3.26578 6.51461 7.29432 " }
        }
    }
    Shape {
        objectName: "shape011"
        id: _qt_node7
        transformOrigin: Item.TopLeft
        transform: TransformGroup {
            id: _qt_node7_transform_base_group
            Matrix4x4 { matrix: PlanarTransform.fromAffineMatrix(0.298604, 0.954986, 1.04032, -0.310206, 86.1992, 169.718)}
        }
        ShapePath {
            id: _qt_node7_fill_stroke
            objectName: "svg_path:shape011"
            strokeColor: root.color
            strokeWidth: root.localLineWidth
            capStyle: ShapePath.SquareCap
            joinStyle: ShapePath.BevelJoin
            miterLimit: 4
            fillColor: root.color
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 7.07138 7.59589 C 7.07138 11.791 5.4884 15.1918 3.53569 15.1918 C 1.58298 15.1918 0 11.791 0 7.59589 C 0 3.4008 1.58298 0 3.53569 0 C 5.4884 0 7.07138 3.4008 7.07138 7.59589 " }
        }
    }
}
