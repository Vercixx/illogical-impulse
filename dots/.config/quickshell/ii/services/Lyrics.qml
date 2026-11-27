pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "Lrc.js" as Lrc
import "NetEase.js" as NetEase

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

        root.requesting = key;
        root.sendRequest(`https://lrclib.net/api/get?${key}`, root.handleLrclib);
    }

    function sendRequest(url, handleBody) {
        if (root.request)
            root.request.onreadystatechange = null;
        const xhr = new XMLHttpRequest();
        root.request = xhr;
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", "illogical-impulse (https://github.com/Vercixx/illogical-impulse)");
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE && root.request === xhr)
                root.handleResponse(xhr, handleBody);
        };
        timeout.restart();
        xhr.send();
    }

    function handleResponse(xhr, handleBody) {
        if (!root.users.has(root.requesting)) {
            root.finish(null);
            return;
        }
        if (xhr.status === 429 || xhr.status === 503) {
            const header = xhr.getResponseHeader("Retry-After");
            const wait = /^\d+$/.test(header) ? Number(header) * 1000 : Date.parse(header) - Date.now();
            const delay = Number.isFinite(wait) ? Math.max(300, wait) : 1000;
            root.nextRequestAt = Date.now() + delay * (1 + Math.random() * 0.3);
        }
        if (xhr.status === 404) {
            handleBody(null);
        } else if (xhr.status === 200) {
            let body;
            try {
                body = JSON.parse(xhr.responseText);
            } catch (error) {
                root.finish({ status: "error" });
                return;
            }
            handleBody(body);
        } else {
            root.finish({ status: "error" });
        }
    }

    function handleLrclib(lyrics) {
        const lines = typeof lyrics?.syncedLyrics === "string" ? Lrc.parse(lyrics.syncedLyrics) : [];
        const plain = typeof lyrics?.plainLyrics === "string" ? lyrics.plainLyrics.trim() : "";
        if (lyrics?.instrumental) {
            root.finish({ status: "unavailable" });
        } else if (lines.length || plain.length) {
            root.finish({ status: "ready", lines, plain });
        } else {
            root.searchNetEase();
        }
    }

    function searchNetEase() {
        const track = {};
        for (const field of root.requesting.split("&")) {
            const [name, value] = field.split("=");
            track[name] = decodeURIComponent(value);
        }
        const search = encodeURIComponent(`${track.track_name} ${track.artist_name}`);
        root.sendRequest(`https://music.163.com/api/search/get?type=1&limit=10&s=${search}`, response => {
            if (response && response.code !== 200) {
                root.finish({ status: "error" });
                return;
            }
            const id = NetEase.matchTrack(response?.result?.songs, track);
            if (id)
                root.sendRequest(`https://music.163.com/api/song/lyric?id=${id}&lv=1`, root.handleNetEaseLyrics);
            else
                root.finish({ status: "unavailable" });
        });
    }

    function handleNetEaseLyrics(response) {
        if (response && response.code !== 200) {
            root.finish({ status: "error" });
            return;
        }
        const lrc = response?.lrc?.lyric;
        const lines = !response?.nolyric && typeof lrc === "string" ? Lrc.parse(lrc) : [];
        root.finish(lines.length ? { status: "ready", lines, plain: "" } : { status: "unavailable" });
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
