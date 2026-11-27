.pragma library

function normalize(text) {
    return typeof text === "string" ? text.normalize("NFKC").trim().toLowerCase().replace(/\s+/g, " ") : "";
}

function artistCredit(artists) {
    return normalize(artists).split(/\s*,\s*/).sort().join(",");
}

function matchTrack(songs, track) {
    if (!Array.isArray(songs))
        return null;
    const title = normalize(track.track_name);
    const artists = artistCredit(track.artist_name);
    const album = normalize(track.album_name);
    const duration = Number(track.duration) * 1000;
    let best = null;
    let bestAlbumMatch = false;
    let bestDifference = Infinity;

    for (const song of songs) {
        if (!Number.isSafeInteger(song?.id) || song.id <= 0 || normalize(song.name) !== title || !Array.isArray(song.artists))
            continue;
        if (artistCredit(song.artists.map(artist => normalize(artist?.name)).join(",")) !== artists)
            continue;
        const difference = duration ? Math.abs(song.duration - duration) : 0;
        if (!Number.isFinite(difference) || difference > 3000)
            continue;

        const albumMatch = album !== "" && normalize(song.album?.name) === album;
        if (!best || (albumMatch && !bestAlbumMatch) || (albumMatch === bestAlbumMatch && difference < bestDifference)) {
            best = song;
            bestAlbumMatch = albumMatch;
            bestDifference = difference;
        }
    }
    return best?.id ?? null;
}
