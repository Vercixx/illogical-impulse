pragma ComponentBehavior: Bound
import QtQuick
import "../../../assets/shaders/WallpaperEffects.js" as WallpaperEffects

Item {
    id: root

    required property string path
    required property string effect
    property string direction: "right"
    property alias duration: animation.duration
    readonly property url requestedSource: {
        if (!path) return "";
        if (path.startsWith("/")) return "file://" + path.split("/").map(encodeURIComponent).join("/");
        return Qt.resolvedUrl(path);
    }
    property Component imageComponent: Component {
        Image {
            anchors.fill: parent
            asynchronous: true
            retainWhileLoading: true
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
        }
    }
    property Image currentImage
    property Image incomingImage
    property real progress: 0
    property string activeEffect: "fade"
    property string activeDirection: "right"
    readonly property real travelX: activeDirection === "left" ? -width : activeDirection === "right" ? width : 0
    readonly property real travelY: activeDirection === "up" ? -height : activeDirection === "down" ? height : 0
    readonly property bool wiping: activeEffect === "wipe"
    readonly property bool sliding: activeEffect === "slide"
    readonly property bool fading: !wiping && !sliding
    readonly property int shaderIndex: WallpaperEffects.names.indexOf(activeEffect)
    readonly property real fadeInEnd: 0.85
    clip: true

    function discard(image) {
        if (image) {
            image.visible = false;
            image.destroy();
        }
    }

    function load() {
        if (!foreground) return;
        if (!path) {
            animation.stop();
            discard(currentImage);
            discard(incomingImage);
            currentImage = null;
            incomingImage = null;
            progress = 0;
            return;
        }
        if (animation.running) return;
        if (incomingImage?.source.toString() === requestedSource.toString()) return;
        discard(incomingImage);
        incomingImage = null;
        if (currentImage?.source.toString() === requestedSource.toString()) return;
        incomingImage = imageComponent.createObject(foreground, { source: requestedSource });
        reveal();
    }

    function reveal() {
        if (incomingImage?.status !== Image.Ready || animation.running) return;
        if (!currentImage || effect === "none" || duration === 0) {
            finish();
            return;
        }
        activeEffect = effect;
        activeDirection = direction;
        animation.start();
    }

    function finish() {
        discard(currentImage);
        currentImage = incomingImage;
        currentImage.parent = background;
        incomingImage = null;
        progress = 0;
    }

    onRequestedSourceChanged: load()
    Component.onCompleted: load()

    Connections {
        target: root.incomingImage
        function onStatusChanged() { root.reveal(); }
    }

    Item {
        clip: !root.fading && root.progress > 0
        x: root.sliding ? root.travelX * root.progress : root.wiping && root.activeDirection !== "left" ? root.width - width : 0
        y: root.sliding ? root.travelY * root.progress : 0
        width: root.width * (root.wiping ? 1 - root.progress : 1)
        height: root.height
        // Clear the old image beneath transparent pixels once the new image is fully visible.
        opacity: root.fading ? Math.min(1, (1 - root.progress) / (1 - root.fadeInEnd)) : 1
        Item { id: background; x: root.wiping ? -parent.x : 0; width: root.width; height: root.height }
    }
    Item {
        clip: !root.fading
        x: root.sliding ? root.travelX * (root.progress - 1) : root.wiping && root.activeDirection === "left" ? root.width - width : 0
        y: root.sliding ? root.travelY * (root.progress - 1) : 0
        width: root.width * (root.wiping ? root.progress : 1)
        height: root.height
        opacity: root.fading ? Math.min(1, root.progress / root.fadeInEnd) : 1
        visible: root.progress > 0
        Item {
            id: foreground
            x: root.wiping ? -parent.x : 0
            width: root.width
            height: root.height
            scale: root.activeEffect === "zoom" ? 1 + 0.35 * (1 - root.progress) : 1
        }
    }
    Loader {
        anchors.fill: parent
        active: root.shaderIndex >= 0 && root.progress > 0 && GraphicsInfo.api !== GraphicsInfo.Software
        sourceComponent: ShaderEffect {
            readonly property int pattern: root.shaderIndex
            readonly property real progress: root.progress
            readonly property size viewport: Qt.size(width, height)
            property var outgoing: ShaderEffectSource {
                sourceItem: background
                hideSource: true
                visible: false
            }
            property var incoming: ShaderEffectSource {
                sourceItem: foreground
                hideSource: true
                visible: false
            }
            fragmentShader: Qt.resolvedUrl("../../../assets/shaders/wallpaper.frag.qsb")
        }
    }
    NumberAnimation {
        id: animation
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: 600
        easing.type: Easing.InOutCubic
        onFinished: {
            root.finish();
            root.load();
        }
    }
}
