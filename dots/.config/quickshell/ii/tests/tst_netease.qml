import QtTest
import "../services/NetEase.js" as NetEase

TestCase {
    name: "NetEase"

    readonly property var track: ({ track_name: "Time & Space", artist_name: "Second, First", album_name: "Original", duration: 180 })

    function song(id, name, duration, artists, album) {
        return { id, name, duration, artists: artists.map(name => ({ name })), album: { name: album } };
    }

    function test_matchTrack() {
        const compilation = song(1, "Time & Space", 180100, ["First", "Second"], "Compilation");
        const original = song(2, "Ｔｉｍｅ & Space", 181000, ["First", "Second"], "ORIGINAL");
        compare(NetEase.matchTrack([compilation, original], track), 2);
        compare(NetEase.matchTrack([original, compilation], { track_name: track.track_name, artist_name: track.artist_name, duration: 180 }), 1);
    }

    function test_skipWrongRecording() {
        const songs = [
            song(1, "Time & Space (Live)", 180000, ["First", "Second"], "Original"),
            song(2, "Time & Space", 180000, ["First"], "Original"),
            song(3, "Time & Space", 183001, ["First", "Second"], "Original"),
            song("../../other", "Time & Space", 180000, ["First", "Second"], "Original"),
            song(4, 5, 180000, ["First", "Second"], "Original"),
            null
        ];
        compare(NetEase.matchTrack(songs, track), null);
        compare(NetEase.matchTrack(null, track), null);
    }
}
