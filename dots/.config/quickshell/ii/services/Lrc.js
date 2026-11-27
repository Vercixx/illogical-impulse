.pragma library

function parse(source) {
    const offset = Number(source.match(/^\s*\[offset:([+-]?\d+)\]/im)?.[1] ?? 0);
    const lines = [];
    for (const rawLine of source.split(/\r?\n/)) {
        const line = rawLine.trim();
        const tags = line.match(/^(?:\[\d+:[0-5]?\d(?:\.\d{1,3})?\])+/)?.[0];
        if (!tags)
            continue;
        const text = line.slice(tags.length).trim();
        const timestamps = /\[(\d+):([0-5]?\d)(?:\.(\d{1,3}))?\]/g;
        for (let match = timestamps.exec(tags); match; match = timestamps.exec(tags)) {
            const fraction = (match[3] ?? "").padEnd(3, "0");
            const time = Number(match[1]) * 60000 + Number(match[2]) * 1000 + Number(fraction) - offset;
            lines.push({ time, text });
        }
    }
    return lines.some(line => line.text.length > 0) ? lines.sort((a, b) => a.time - b.time) : [];
}

function activeLine(lines, position) {
    const time = Math.round(position * 1000);
    let index = -1;
    while (index + 1 < lines.length && lines[index + 1].time <= time)
        index++;
    return index;
}
