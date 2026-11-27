pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "Lrc.js" as Lrc

Singleton {
    id: root

    property var results: ({})
    property var users: new Map()
    property var request: null
    property string requesting: ""
    property double nextRequestAt: 0

    function trackQuery(player) {
        const title = player?.trackTitle?.trim();
        const artist = player?.trackArtist?.trim();
        if (!title || !artist)
            return "";

        const album = player.trackAlbum?.trim();
        const duration = Math.round(player.length);
        let query = `track_name=${encodeURIComponent(title)}&artist_name=${encodeURIComponent(artist)}`;
        if (album)
            query += `&album_name=${encodeURIComponent(album)}`;
        if (player.lengthSupported && duration >= 1 && duration <= 3600)
            query += `&duration=${duration}`;
        return query;
    }

    function retain(key) {
        root.users.set(key, (root.users.get(key) ?? 0) + 1);
        wake.restart();
    }

    function release(key) {
        const count = root.users.get(key) - 1;
        if (count > 0) {
            root.users.set(key, count);
            return;
        }
        root.users.delete(key);
        const result = root.results[key];
        if (result)
            root.store(key, result.status === "ready" ? result : null);
        wake.restart();
    }

    function store(key, result) {
        const updated = Object.assign({}, root.results);
        if (result)
            updated[key] = result;
        else
            delete updated[key];
        const unused = Object.keys(updated).filter(entry => !root.users.has(entry));
        for (const entry of unused.slice(0, Math.max(0, unused.length - 32)))
            delete updated[entry];
        root.results = updated;
    }

    function fetchNext() {
        if (root.request) {
            if (!root.users.has(root.requesting)) {
                const xhr = root.request;
                root.finish(null);
                xhr.abort();
            }
            return;
        }
        const key = Array.from(root.users.keys()).find(key => !root.results[key]);
        if (!key)
            return;
        const delay = root.nextRequestAt - Date.now();
        if (delay > 0) {
            cooldown.interval = Math.min(delay, 2147483647);
            cooldown.restart();
            return;
        }

        const xhr = new XMLHttpRequest();
        root.requesting = key;
        root.request = xhr;
        xhr.open("GET", `https://lrclib.net/api/get?${key}`);
        xhr.setRequestHeader("User-Agent", "illogical-impulse (https://github.com/Vercixx/illogical-impulse)");
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE && root.request === xhr)
                root.handleResponse(xhr);
        };
        timeout.restart();
        xhr.send();
    }

    function handleResponse(xhr) {
        if (xhr.status === 429 || xhr.status === 503) {
            const header = xhr.getResponseHeader("Retry-After");
            const wait = /^\d+$/.test(header) ? Number(header) * 1000 : Date.parse(header) - Date.now();
            const delay = Number.isFinite(wait) ? Math.max(300, wait) : 1000;
            root.nextRequestAt = Date.now() + delay * (1 + Math.random() * 0.3);
        }
        if (xhr.status === 404) {
            root.finish({ status: "unavailable" });
            return;
        }
        if (xhr.status === 200) {
            try {
                const lyrics = JSON.parse(xhr.responseText);
                const lines = typeof lyrics.syncedLyrics === "string" ? Lrc.parse(lyrics.syncedLyrics) : [];
                const plain = typeof lyrics.plainLyrics === "string" ? lyrics.plainLyrics.trim() : "";
                root.finish(!lyrics.instrumental && (lines.length || plain.length)
                    ? { status: "ready", lines, plain }
                    : { status: "unavailable" });
                return;
            } catch (error) {
                root.finish({ status: "error" });
                return;
            }
        }
        root.finish({ status: "error" });
    }

    function finish(result) {
        const key = root.requesting;
        root.request.onreadystatechange = null;
        root.request = null;
        root.requesting = "";
        root.nextRequestAt = Math.max(root.nextRequestAt, Date.now() + 300);
        timeout.stop();
        if (result && root.users.has(key))
            root.store(key, result);
        wake.restart();
    }

    Timer {
        id: wake
        interval: 0
        onTriggered: root.fetchNext()
    }

    Timer {
        id: cooldown
        onTriggered: root.fetchNext()
    }

    Timer {
        id: timeout
        interval: 8000
        onTriggered: {
            const xhr = root.request;
            root.finish({ status: "error" });
            xhr.abort();
        }
    }
}
