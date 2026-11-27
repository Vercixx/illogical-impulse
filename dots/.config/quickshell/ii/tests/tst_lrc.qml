import QtTest
import "../services/Lrc.js" as Lrc

TestCase {
    name: "Lrc"

    function test_parse() {
        const lines = Lrc.parse("[00:10.2]Second\r\n[ar:Artist]\r\n[00:02.010][00:15]First\r\n[00:20.25]\r\n[offset:+100]");
        compare(lines.map(line => line.time), [1910, 10100, 14900, 20150]);
        compare(lines.map(line => line.text), ["First", "Second", "First", ""]);
        compare(Lrc.parse("[offset:invalid]\n[00:70]Bad seconds\n[bad]No time\n[00:20]"), []);
    }

    function test_activeLine() {
        const lines = Lrc.parse("[00:02]First\n[00:04]Second\n[00:06]");
        compare(Lrc.activeLine(lines, 0), -1);
        compare(Lrc.activeLine(lines, 2), 0);
        compare(Lrc.activeLine(lines, 4), 1);
        compare(Lrc.activeLine(lines, 8), 2);
        compare(Lrc.activeLine(lines, 3), 0);
    }
}
