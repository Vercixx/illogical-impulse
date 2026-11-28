import QtQuick
import QtTest
import "../modules/common/widgets"

TestCase {
    id: testCase
    name: "WallpaperTransition"
    when: windowShown
    visible: true
    width: 120
    height: 80

    function solid(color) {
        return "data:image/svg+xml," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="4" height="4"><rect width="4" height="4" fill="' + color + '"/></svg>');
    }

    Rectangle { anchors.fill: parent; color: "lime" }
    WallpaperTransition {
        id: view
        anchors.fill: parent
        path: ""
        effect: "none"
    }
    SignalSpy { id: progressChanges; target: view; signalName: "progressChanged" }

    function show(color) {
        view.path = solid(color);
        tryVerify(() => view.currentImage?.source.toString() === view.requestedSource.toString());
    }

    function cleanup() {
        view.path = "";
        view.duration = 600;
        view.direction = "right";
        compare(view.currentImage, null);
        compare(view.incomingImage, null);
    }

    function test_configurableDuration() {
        view.effect = "wipe";
        view.duration = 1500;
        show("red");
        view.path = solid("blue");
        tryVerify(() => view.progress > 0);
        wait(700);
        verify(view.progress > 0 && view.progress < 1);
        show("blue");

        view.duration = 0;
        progressChanges.clear();
        show("red");
        compare(progressChanges.count, 0);
    }

    function test_render_data() {
        return ["fade", "zoom"].map(effect => ({ tag: effect, effect }));
    }

    function test_render(row) {
        view.effect = row.effect;
        show("red");
        view.path = solid("blue");
        tryVerify(() => view.progress > 0.25 && view.progress < 0.75);
        const frame = grabImage(view);
        verify(frame.red(60, 40) > 0 && frame.blue(60, 40) > 0);
        verify(Math.abs(frame.red(60, 40) + frame.blue(60, 40) - 255) <= 2);
        verify((view.incomingImage.mapToItem(view, 0, 0).x < 0) === (row.effect === "zoom"));
        show("blue");
        compare(grabImage(view).blue(60, 40), 255);
    }

    function test_direction_data() {
        const rows = [];
        for (const [direction, dx, dy] of [["left", -1, 0], ["right", 1, 0], ["up", 0, -1], ["down", 0, 1]]) {
            for (const effect of dy === 0 ? ["wipe", "slide"] : ["slide"]) {
                rows.push({ tag: effect + "-" + direction, effect, direction, dx, dy });
            }
        }
        return rows;
    }

    function test_direction(row) {
        view.effect = row.effect;
        view.direction = row.direction;
        show("red");
        view.path = solid("blue");
        tryVerify(() => view.progress > 0.25 && view.progress < 0.75);
        view.direction = row.direction === "left" ? "right" : "left";
        const frame = grabImage(view);
        const x = view.width / 2 - row.dx * (view.width / 2 - 4);
        const y = view.height / 2 - row.dy * (view.height / 2 - 4);
        compare(frame.blue(x, y), 255);
        compare(frame.red(view.width - x, view.height - y), 255);
        const incoming = view.incomingImage.mapToItem(view, 0, 0);
        const outgoing = view.currentImage.mapToItem(view, 0, 0);
        compare(Math.sign(incoming.x), row.effect === "slide" ? -row.dx : 0);
        compare(Math.sign(incoming.y), row.effect === "slide" ? -row.dy : 0);
        compare(Math.sign(outgoing.x), row.effect === "slide" ? row.dx : 0);
        compare(Math.sign(outgoing.y), row.effect === "slide" ? row.dy : 0);
        show("blue");
        compare(grabImage(view).blue(60, 40), 255);
    }

    function test_rapidChangesAndClear() {
        view.effect = "fade";
        show("red");
        view.path = solid("blue");
        tryVerify(() => view.progress > 0);
        view.path = solid("yellow");
        show("green");
        compare(grabImage(view).green(60, 40), 128);
        view.path = solid("red");
        tryVerify(() => view.progress > 0);
        view.path = "";
        compare(view.currentImage, null);
        compare(view.incomingImage, null);
        compare(view.progress, 0);
    }

    function test_transparentWipe_data() {
        return [{ tag: "right", x: 4 }, { tag: "left", x: 116 }];
    }

    function test_transparentWipe(row) {
        view.effect = "wipe";
        view.direction = row.tag;
        show("red");
        view.path = solid("none");
        tryVerify(() => view.progress > 0.25 && view.progress < 0.75);
        const frame = grabImage(testCase);
        compare(frame.green(row.x, 40), 255);
        compare(frame.red(view.width - row.x, 40), 255);
    }

    function test_failedReplacement() {
        view.effect = "none";
        show("red");
        const original = view.currentImage;
        ignoreWarning(/.*Cannot open.*/);
        view.path = "/missing-wallpaper-test.png";
        tryVerify(() => view.incomingImage?.status === Image.Error);
        compare(view.currentImage, original);
        compare(grabImage(view).red(60, 40), 255);
        show("blue");
        compare(view.progress, 0);
    }
}
