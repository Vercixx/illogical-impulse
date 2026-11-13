-- „I'm driftin' here“

local LAYOUT = "lua:drift"
local MIN = { w = 200, h = 120 }
local SCATTER_DISTANCE = 80
local SCATTER_TRIES = 32
local options = { new_width = 60, new_height = 70, recenter_delay = 60, pan_step = 100, nudge_step = 20, resize_step = 20 }
local DIRS = { l = { -1, 0 }, r = { 1, 0 }, u = { 0, -1 }, d = { 0, 1 } }
-- Unset bookmark 1 is the canvas center, where recenter gathers windows
local CENTER_MARK = { x = 0, y = 0 }

-- Called from custom/shell.lua (Settings app) and other custom files
function drift(values)
    for key, value in pairs(values) do
        if type(value) == "number" and options[key] then options[key] = value end
    end
end

local STATE = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-drift-state"

local cams = {}
local world = {}
local placed = {}
local adopt = {}
local order = {} -- Oldest is the master window
local marks = {}

local function marksFor(wsId)
    marks[wsId] = marks[wsId] or {}
    return marks[wsId]
end

local function remember(id)
    for _, o in ipairs(order) do
        if o == id then return end
    end
    order[#order + 1] = id
end

local function loadState(alive)
    local f = io.open(STATE, "r")
    if not f then return end
    for line in f:lines() do
        local kind, key, a, b, c, d = line:match("^(%a) (%S+) ?(%S*) ?(%S*) ?(%S*) ?(%S*)$")
        a, b, c, d = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
        if kind == "c" and tonumber(key) and a and b then
            cams[tonumber(key)] = { x = a, y = b }
        elseif kind == "w" and alive[key] and a and b and c and d then
            world[key] = { x = a, y = b, w = c, h = d }
        elseif kind == "o" and alive[key] then
            remember(key)
        elseif kind == "b" and tonumber(key) and a and b and c then
            marksFor(tonumber(key))[a] = { x = b, y = c }
        end
    end
    f:close()
end

local function saveState()
    local f = io.open(STATE, "w")
    if not f then return end
    for id, cam in pairs(cams) do
        f:write(("c %d %.1f %.1f\n"):format(id, cam.x, cam.y))
    end
    for id, w in pairs(world) do
        f:write(("w %s %.1f %.1f %.1f %.1f\n"):format(id, w.x, w.y, w.w, w.h))
    end
    for _, id in ipairs(order) do
        f:write(("o %s\n"):format(id))
    end
    for wsId, slots in pairs(marks) do
        for slot, m in pairs(slots) do
            f:write(("b %d %d %.1f %.1f\n"):format(wsId, slot, m.x, m.y))
        end
    end
    f:close()
end

do
    local alive = {}
    for _, w in ipairs(hl.get_windows() or {}) do
        alive[w.address] = true
    end
    loadState(alive)
    for id in pairs(alive) do
        if not world[id] then adopt[id] = true end
    end
end

local function camFor(ws)
    local id = ws and ws.id or 0
    cams[id] = cams[id] or { x = 0, y = 0 }
    return cams[id]
end

local function shiftFloating(wsId, dx, dy)
    if dx == 0 and dy == 0 then return end
    for _, w in ipairs(hl.get_windows() or {}) do
        local ws = w.workspace
        if w.floating and not w.pinned and not w.hidden and w.fullscreen == 0 and ws and (ws.id or 0) == wsId then
            hl.dispatch(hl.dsp.window.move({ x = dx, y = dy, relative = true, window = w }))
        end
    end
end

local function toWorld(box, area, cam)
    return {
        x = box.x - area.x + cam.x,
        y = box.y - area.y + cam.y,
        w = math.max(box.w, MIN.w),
        h = math.max(box.h, MIN.h),
    }
end

-- Gaps come from general:gaps_in, which Hyprland applies to every placed box
local function overlaps(a, b)
    return a.x < b.x + b.w - 1 and b.x < a.x + a.w - 1
        and a.y < b.y + b.h - 1 and b.y < a.y + a.h - 1
end

local function firstHit(box, items, skip)
    for _, o in ipairs(items) do
        if o.id ~= skip and overlaps(box, o.box) then return o.box end
    end
end

local function slide(box, dx, dy, items)
    for _ = 1, 100 do
        local hit = firstHit(box, items)
        if not hit then return box end
        if dx > 0 then box.x = hit.x + hit.w
        elseif dx < 0 then box.x = hit.x - box.w
        elseif dy > 0 then box.y = hit.y + hit.h
        else box.y = hit.y - box.h end
    end
    return box
end

-- Calculates the closest free spot next to the anchor in all directions
local function spotNear(anchor, w, h, items, area)
    local cx, cy = anchor.x + anchor.w / 2, anchor.y + anchor.h / 2
    local best, bestDist
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local box = {
            x = d[1] > 0 and anchor.x + anchor.w or d[1] < 0 and anchor.x - w or cx - w / 2,
            y = d[2] > 0 and anchor.y + anchor.h or d[2] < 0 and anchor.y - h or cy - h / 2,
            w = w,
            h = h,
        }
        slide(box, d[1], d[2], items)
        local dist = ((box.x + w / 2 - cx) / area.w) ^ 2 + ((box.y + h / 2 - cy) / area.h) ^ 2
        if not best or dist < bestDist then best, bestDist = box, dist end
    end
    return best
end

-- Pushes overlapping windows apart
local function separate(items, fixed)
    for _ = 1, 50 do
        local moved = false
        for i = 1, #items do
            for j = i + 1, #items do
                local m, o = items[j], items[i]
                if m.id == fixed then m, o = o, m end
                local a, b = m.box, o.box
                if overlaps(a, b) then
                    local right = b.x + b.w - a.x
                    local leftward = a.x + a.w - b.x
                    local down = b.y + b.h - a.y
                    local up = a.y + a.h - b.y
                    local least = math.min(right, leftward, down, up)
                    if least == right then a.x = a.x + right
                    elseif least == leftward then a.x = a.x - leftward
                    elseif least == down then a.y = a.y + down
                    else a.y = a.y - up end
                    moved = true
                end
            end
        end
        if not moved then return end
    end
end

-- Random angle around the master, just clear of it plus up to SCATTER_DISTANCE px.
local function scatterAround(master, w, h, items)
    local cx, cy = master.x + master.w / 2, master.y + master.h / 2
    local clearX, clearY = (master.w + w) / 2, (master.h + h) / 2
    for _ = 1, SCATTER_TRIES do
        local angle = math.random() * 2 * math.pi
        local c, s = math.cos(angle), math.sin(angle)
        local reach = math.min(clearX / math.max(math.abs(c), 1e-6), clearY / math.max(math.abs(s), 1e-6))
        local r = reach + math.random() * SCATTER_DISTANCE
        local box = { x = cx + c * r - w / 2, y = cy + s * r - h / 2, w = w, h = h }
        if not firstHit(box, items) then return box end
    end
end

-- Tries masters from oldest to newest; when every master is crowded, takes the nearest free side of the oldest.
local function placeNew(w, h, items, present, cam, area)
    local oldest
    for _, id in ipairs(order) do
        if present[id] and world[id] then
            oldest = oldest or world[id]
            local box = scatterAround(world[id], w, h, items)
            if box then return box end
        end
    end
    if not oldest then
        return { x = cam.x + (area.w - w) / 2, y = cam.y + (area.h - h) / 2, w = w, h = h }
    end
    return spotNear(oldest, w, h, items, area)
end

-- A tiled window dragged with Super+LMB floats during the drag and re-enters the layout on drop.
local members = {}
local left = {}
local sent = {}

-- Hyprland skips recalculate while a workspace has no tiled windows, so pan announces the camera itself.
local function announceCam(wsId, cam)
    local key = ("%d %.0f %.0f"):format(wsId, cam.x, cam.y)
    if sent[wsId] == key then return end
    sent[wsId] = key
    hl.dispatch(hl.dsp.event("drift>>cam " .. key))
end

-- Sends each bookmark's view center in layout coordinates as if the camera were at 0, 0
local function announceMarks(wsId, area)
    local shown = { [1] = CENTER_MARK }
    for slot, m in pairs(marksFor(wsId)) do shown[slot] = m end
    local parts = {}
    for slot = 0, 9 do
        local m = shown[slot]
        if m then parts[#parts + 1] = ("%d:%.0f:%.0f"):format(slot, area.x + m.x + area.w / 2, area.y + m.y + area.h / 2) end
    end
    local key = ("%d %s"):format(wsId, table.concat(parts, " "))
    if sent["marks" .. wsId] == key then return end
    sent["marks" .. wsId] = key
    hl.dispatch(hl.dsp.event("drift>>marks " .. key))
end

-- Any change to the camera or a window box restarts the idle recenter countdown.
local signatures = {}
local lastChange = os.time()
local recentered = false

local function noteChanges(wsId, cam, items)
    local parts = { ("%.0f %.0f"):format(cam.x, cam.y) }
    for _, it in ipairs(items) do
        parts[#parts + 1] = ("%s %.0f %.0f %.0f %.0f"):format(it.id, it.box.x, it.box.y, it.box.w, it.box.h)
    end
    local signature = table.concat(parts, ";")
    if signatures[wsId] == signature then return end
    signatures[wsId] = signature
    lastChange = os.time()
    recentered = false
end

-- Started from the first layout update: a timer created during config load (config.reloaded
-- included) segfaults `Hyprland --verify-config`.
local idleTimer
local function startIdleTimer()
    if idleTimer then return end
    idleTimer = hl.timer(function()
        if recentered or options.recenter_delay <= 0 or os.time() - lastChange < options.recenter_delay or not drift_active() then return end
        recentered = true
        hl.dispatch(hl.dsp.layout("recenter"))
    end, { timeout = 1000, type = "repeat" })
end

local function recalculate(ctx)
    startIdleTimer()
    local a = ctx.area
    local fresh, items, present = {}, {}, {}
    local cam, wsId

    for _, t in ipairs(ctx.targets) do
        local win = t.window
        if win then
            local id = win.address
            if not cam then
                cam = camFor(win.workspace)
                wsId = win.workspace and win.workspace.id or 0
            end
            present[id] = true
            local w, b = world[id], t.box
            if w and left[id] and b.w > 0 and b.h > 0 then
                w.x = b.x + b.w / 2 - a.x + cam.x - w.w / 2
                w.y = b.y + b.h / 2 - a.y + cam.y - w.h / 2
            elseif not w and adopt[id] and b.w > 0 and b.h > 0 then
                world[id] = toWorld(b, a, cam)
            elseif not w then
                fresh[#fresh + 1] = id
            end
            left[id] = nil
            adopt[id] = nil
            if world[id] then
                remember(id)
                items[#items + 1] = { id = id, box = world[id] }
            end
        end
    end

    if wsId then
        for id in pairs(members[wsId] or {}) do
            if not present[id] then left[id] = true end
        end
        members[wsId] = present
    end

    local camBefore = cam and { x = cam.x, y = cam.y }
    for _, id in ipairs(fresh) do
        local box = placeNew(a.w * options.new_width / 100, a.h * options.new_height / 100, items, present, cam, a)
        world[id] = box
        remember(id)
        items[#items + 1] = { id = id, box = box }
        cam.x = box.x + box.w / 2 - a.w / 2
        cam.y = box.y + box.h / 2 - a.h / 2
    end
    if camBefore then shiftFloating(wsId, camBefore.x - cam.x, camBefore.y - cam.y) end

    local active = hl.get_active_window()
    separate(items, fresh[#fresh] or (active and active.address))

    for _, t in ipairs(ctx.targets) do
        local win = t.window
        local w = win and world[win.address]
        if w then
            local box = { x = a.x + w.x - cam.x, y = a.y + w.y - cam.y, w = w.w, h = w.h }
            t:place(box)
            placed[win.address] = box
        end
    end

    if wsId then
        noteChanges(wsId, cam, items)
        announceCam(wsId, cam)
        announceMarks(wsId, a)
    end
end

local function resizeEdge(w, pos, size, delta, side, min)
    if side > 0 then
        w[size] = math.max(w[size] + delta, min)
        return
    end
    local far = w[pos] + w[size]
    w[size] = math.max(w[size] - delta, min)
    w[pos] = far - w[size]
end

local function msgWorkspace(ctx)
    local first = ctx.targets[1]
    local mon = hl.get_active_monitor()
    return first and first.window and first.window.workspace
        or mon and (mon.active_special_workspace or mon.active_workspace)
end

local function panBy(ctx, dx, dy)
    local ws = msgWorkspace(ctx)
    if not ws or (dx == 0 and dy == 0) then return end
    local cam = camFor(ws)
    cam.x, cam.y = cam.x + dx, cam.y + dy
    shiftFloating(ws.id or 0, -dx, -dy)
    if #ctx.targets == 0 then announceCam(ws.id or 0, cam) end
end

local function tiledBox(win)
    return win and not win.floating and world[win.address]
end

local function screenBox(ctx, win)
    local w = tiledBox(win)
    if not w then return { x = win.at.x, y = win.at.y, w = win.size.x, h = win.size.y } end
    local cam = camFor(win.workspace)
    return { x = ctx.area.x + w.x - cam.x, y = ctx.area.y + w.y - cam.y, w = w.w, h = w.h }
end

local function onMsgWorkspace(ctx, win)
    local ws = msgWorkspace(ctx)
    return win and ws and (win.workspace and win.workspace.id) == ws.id
end

local function activeWindow(ctx)
    local win = hl.get_active_window()
    if onMsgWorkspace(ctx, win) and not win.pinned and win.fullscreen == 0 then return win end
end

-- Pans the least distance that shows the whole window, or centers it
local function showWindow(ctx, win, centered)
    if not win then return end
    local b, a = screenBox(ctx, win), ctx.area
    local function shift(lo, size, areaLo, areaSize)
        if centered then return lo + size / 2 - areaLo - areaSize / 2 end
        if lo < areaLo or size > areaSize then return lo - areaLo end
        return math.max(lo + size - areaLo - areaSize, 0)
    end
    panBy(ctx, shift(b.x, b.w, a.x, a.w), shift(b.y, b.h, a.y, a.h))
end

local function showActive(ctx, centered)
    showWindow(ctx, activeWindow(ctx), centered)
end

-- Places windows first, so the cursor warp on focus lands on the window's new spot
local function focusWindow(ctx, win, centered)
    showWindow(ctx, win, centered)
    recalculate(ctx)
    hl.dispatch(hl.dsp.focus({ window = win }))
end

local function windowsOn(ws)
    local list = {}
    for _, w in ipairs(hl.get_windows() or {}) do
        if not w.hidden and w.workspace and w.workspace.id == ws.id then list[#list + 1] = w end
    end
    return list
end

local function windowByAddress(ctx, address)
    local ws = msgWorkspace(ctx)
    for _, w in ipairs(ws and windowsOn(ws) or {}) do
        if w.address == address and not w.pinned and w.fullscreen == 0 then return w end
    end
end

local function rangeGap(a1, a2, b1, b2)
    return math.max(b1 - a2, a1 - b2, 0)
end

-- Nearest window whose center lies that way; distance across the direction counts double
local function nearestWindow(ctx, from, dir)
    local b = screenBox(ctx, from)
    local best, bestScore
    for _, w in ipairs(windowsOn(from.workspace)) do
        local o = w.address ~= from.address and screenBox(ctx, w)
        if o then
            local ahead, along, across
            if dir[1] ~= 0 then
                ahead = (o.x + o.w / 2 - b.x - b.w / 2) * dir[1]
                along, across = rangeGap(b.x, b.x + b.w, o.x, o.x + o.w), rangeGap(b.y, b.y + b.h, o.y, o.y + o.h)
            else
                ahead = (o.y + o.h / 2 - b.y - b.h / 2) * dir[2]
                along, across = rangeGap(b.y, b.y + b.h, o.y, o.y + o.h), rangeGap(b.x, b.x + b.w, o.x, o.x + o.w)
            end
            local score = along + 2 * across + ahead / 1000
            if ahead > 0 and (not bestScore or score < bestScore) then best, bestScore = w, score end
        end
    end
    return best
end

local function moveWindow(win, dx, dy)
    local w = tiledBox(win)
    if w then
        w.x, w.y = w.x + dx, w.y + dy
    else
        hl.dispatch(hl.dsp.window.move({ x = dx, y = dy, relative = true, window = win }))
    end
end

-- Free space between w and the nearest window ahead that shares its row or column
local function gapAhead(ctx, id, w, dx, dy)
    local best
    for _, t in ipairs(ctx.targets) do
        local o = t.window and t.window.address ~= id and world[t.window.address]
        local gap
        if o and dx ~= 0 and w.y < o.y + o.h - 1 and o.y < w.y + w.h - 1 then
            gap = dx > 0 and o.x - w.x - w.w or w.x - o.x - o.w
        elseif o and dy ~= 0 and w.x < o.x + o.w - 1 and o.x < w.x + w.w - 1 then
            gap = dy > 0 and o.y - w.y - w.h or w.y - o.y - o.h
        end
        if gap and gap > -1 and (not best or gap < best) then best = math.max(gap, 0) end
    end
    return best
end

-- Next spot that way where w touches or lines up with another window's edge, never past a window in its path
local function snapStep(ctx, id, w, dir)
    local pos, size = dir[1] ~= 0 and "x" or "y", dir[1] ~= 0 and "w" or "h"
    local sign = dir[1] ~= 0 and dir[1] or dir[2]
    local limit = gapAhead(ctx, id, w, dir[1], dir[2])
    local best
    for _, t in ipairs(ctx.targets) do
        local o = t.window and t.window.address ~= id and world[t.window.address]
        if o then
            for _, edge in ipairs({ o[pos], o[pos] + o[size] }) do
                for _, stop in ipairs({ edge, edge - w[size] }) do
                    local d = (stop - w[pos]) * sign
                    if d > 0.5 and (not limit or d <= limit) and (not best or d < best) then best = d end
                end
            end
        end
    end
    return best or limit or options.nudge_step
end

local function layoutMsg(ctx, msg)
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    local args, n = {}, {}
    for v in (rest or ""):gmatch("%S+") do args[#args + 1] = v end
    for i, v in ipairs(args) do n[i] = tonumber(v) end
    local dir = DIRS[args[1] or ""]

    if cmd == "sync" then
        sent = {}
        local ws = msgWorkspace(ctx)
        if ws then
            announceCam(ws.id or 0, camFor(ws))
            announceMarks(ws.id or 0, ctx.area)
        end
        return
    end

    if cmd == "recenter" then
        local first = ctx.targets[1]
        if not (first and first.window) then return end
        local boxes = {}
        local x1, y1, x2, y2 = math.huge, math.huge, -math.huge, -math.huge
        for _, t in ipairs(ctx.targets) do
            local w = t.window and world[t.window.address]
            if w then
                boxes[#boxes + 1] = w
                x1, y1 = math.min(x1, w.x), math.min(y1, w.y)
                x2, y2 = math.max(x2, w.x + w.w), math.max(y2, w.y + w.h)
            end
        end
        if #boxes == 0 then return end
        local dx, dy = ctx.area.w / 2 - (x1 + x2) / 2, ctx.area.h / 2 - (y1 + y2) / 2
        for _, w in ipairs(boxes) do
            w.x, w.y = w.x + dx, w.y + dy
        end
        -- World and camera shift together: windows stay put on screen, only the background (pinned to world 0) moves.
        local ws = first.window.workspace
        local cam = camFor(ws)
        cam.x, cam.y = cam.x + dx, cam.y + dy
        for _, m in pairs(marksFor(ws and ws.id or 0)) do
            m.x, m.y = m.x + dx, m.y + dy
        end
        return
    end

    if cmd == "pan" and dir then
        panBy(ctx, dir[1] * options.pan_step, dir[2] * options.pan_step)
        return
    end

    if cmd == "pan" and n[1] and n[2] then
        panBy(ctx, n[1], n[2])
        return
    end

    if cmd == "look" and n[1] and n[2] then
        panBy(ctx, n[1] - ctx.area.x - ctx.area.w / 2, n[2] - ctx.area.y - ctx.area.h / 2)
        return
    end

    if cmd == "page" and dir then
        panBy(ctx, dir[1] * ctx.area.w, dir[2] * ctx.area.h)
        return
    end

    if cmd == "reveal" and args[1] then
        local win = windowByAddress(ctx, args[1])
        if win and (win.floating or world[win.address]) and not overlaps(screenBox(ctx, win), ctx.area) then
            showWindow(ctx, win, true)
        end
        return
    end

    if (cmd == "focus" or cmd == "center") and dir then
        local from = hl.get_active_window()
        local target = onMsgWorkspace(ctx, from) and nearestWindow(ctx, from, dir)
        if target then focusWindow(ctx, target, cmd == "center") end
        return
    end

    if cmd == "cycle" then
        local ws = msgWorkspace(ctx)
        local list = ws and windowsOn(ws) or {}
        if #list == 0 then return end
        local active, at = hl.get_active_window(), 0
        for i, w in ipairs(list) do
            if active and w.address == active.address then at = i end
        end
        local step = args[1] == "prev" and -1 or 1
        focusWindow(ctx, list[(at - 1 + step) % #list + 1])
        return
    end

    if (cmd == "move" or cmd == "nudge") and dir then
        local win = activeWindow(ctx)
        if not win then return end
        local w = tiledBox(win)
        local step = cmd == "move" and w and snapStep(ctx, win.address, w, dir) or options.nudge_step
        moveWindow(win, dir[1] * step, dir[2] * step)
        showActive(ctx)
        return
    end

    if cmd == "carry" and dir then
        local win = activeWindow(ctx)
        if not win then return end
        local dx, dy = dir[1] * ctx.area.w, dir[2] * ctx.area.h
        panBy(ctx, dx, dy)
        moveWindow(win, dx, dy)
        return
    end

    if cmd == "grow" or cmd == "shrink" then
        local win = activeWindow(ctx)
        if not win then return end
        local s = (cmd == "grow" and 1 or -1) * options.resize_step
        local w = tiledBox(win)
        if w then
            resizeEdge(w, "x", "w", s, 1, MIN.w)
            resizeEdge(w, "x", "w", -s, -1, MIN.w)
            resizeEdge(w, "y", "h", s, 1, MIN.h)
            resizeEdge(w, "y", "h", -s, -1, MIN.h)
        else
            hl.dispatch(hl.dsp.window.resize({ x = 2 * s, y = 2 * s, relative = true, window = win }))
            moveWindow(win, -s, -s)
        end
        return
    end

    if cmd == "bookmark" and n[2] then
        local ws = msgWorkspace(ctx)
        if not ws then return end
        local cam, slots, slot = camFor(ws), marksFor(ws.id or 0), n[2]
        local mark = slots[slot] or slot == 1 and CENTER_MARK
        if args[1] == "set" then
            slots[slot] = { x = cam.x, y = cam.y }
            announceMarks(ws.id or 0, ctx.area)
        elseif args[1] == "go" and mark then
            panBy(ctx, mark.x - cam.x, mark.y - cam.y)
            announceMarks(ws.id or 0, ctx.area)
        elseif args[1] == "send" and mark then
            local win = activeWindow(ctx)
            if not win then return end
            local b, a = screenBox(ctx, win), ctx.area
            moveWindow(win, a.x + mark.x - cam.x + (a.w - b.w) / 2 - b.x, a.y + mark.y - cam.y + (a.h - b.h) / 2 - b.y)
        end
        return
    end

    if cmd == "resize" and n[1] and n[2] and n[3] and n[4] then
        local win = hl.get_active_window()
        local w = win and world[win.address]
        if not w then return end
        resizeEdge(w, "x", "w", n[1], n[3], MIN.w)
        resizeEdge(w, "y", "h", n[2], n[4], MIN.h)
        return
    end

    return false
end

hl.layout.register("drift", { recalculate = recalculate, layout_msg = layoutMsg })

-- Hyprland reuses window addresses, and window.destroy only gets nil, so forget on close and on open.
local function forget(w)
    if not w then return end
    world[w.address] = nil
    placed[w.address] = nil
    left[w.address] = nil
    adopt[w.address] = nil
    for i, id in ipairs(order) do
        if id == w.address then
            table.remove(order, i)
            break
        end
    end
end
hl.on("window.close", forget)
hl.on("window.open_early", forget)

-- Dragging the only tiled window empties the layout, which Hyprland never recalculates, so membership misses it.
hl.on("window.update_state", function(w, changes)
    if w and changes and changes.float and world[w.address] then left[w.address] = true end
end)

-- FOCUS_REASON_FFM | FOCUS_REASON_CLICK (Hyprland FocusState.hpp). Mouse focus can hit a window
-- still animating off-screen after a pan, and refocusing the same window (overview closing) keeps the camera.
local MOUSE_FOCUS = 1 | 16
local lastActive
hl.on("window.active", function(w, reason)
    if not w or w.address == lastActive then return end
    lastActive = w.address
    if ((reason or 0) & MOUSE_FOCUS) ~= 0 or not drift_active() then return end
    hl.dispatch(hl.dsp.layout("reveal " .. w.address))
end)

hl.on("config.unload", saveState)

-- Hidden workspaces are unreachable under Drift, so windows landing there join the focused canvas
local function gather(w, ws)
    ws = ws or (w and w.workspace)
    local active = hl.get_active_workspace()
    if not ws or ws.special or ws.visible or not active then return end
    hl.dispatch(hl.dsp.window.move({ workspace = tostring(active.id), follow = false, window = w }))
end

hl.on("window.open", function(w)
    if hl.get_config("general:layout") == LAYOUT then gather(w) end
end)

-- Skips the focused window: a following move switches to its workspace right after
hl.on("window.move_to_workspace", function(w, ws)
    local focused = hl.get_active_window()
    if hl.get_config("general:layout") ~= LAYOUT or (focused and w and focused.address == w.address) then return end
    gather(w, ws)
end)

local function panGesture(e)
    if drift_active() then hl.dispatch(hl.dsp.layout(("pan %.1f %.1f"):format(-e.delta.x, -e.delta.y))) end
end

hl.on("config.reloaded", function()
    if hl.get_config("general:layout") ~= LAYOUT then return end
    hl.config({ gestures = { workspace_swipe_create_new = false } })
    for _, w in ipairs(hl.get_windows() or {}) do
        gather(w)
    end
    -- Replaces the 4-finger workspace and overview swipes from general.lua: any swipe pans, a pinch toggles the overview
    for _, direction in ipairs({ "horizontal", "up", "down" }) do
        hl.gesture({ fingers = 4, direction = direction, action = "unset" })
    end
    hl.gesture({ fingers = 4, direction = "swipe", action = { update = panGesture } })
    hl.gesture({ fingers = 4, direction = "pinch", action = function()
        hl.dispatch(hl.dsp.global("quickshell:overviewWorkspacesToggle"))
    end })
end)

local dragTimer
local function stopDrag()
    if not dragTimer then return end
    dragTimer:set_enabled(false)
    dragTimer = nil
end

local function keyHeld(left, right)
    return function() return hl.is_key_down(left) or hl.is_key_down(right) end
end

local function startDrag(held, onDelta)
    stopDrag()
    local last = hl.get_cursor_pos()
    dragTimer = hl.timer(function()
        if not held() then return stopDrag() end
        local p = hl.get_cursor_pos()
        local dx, dy = math.floor(p.x - last.x), math.floor(p.y - last.y)
        if dx == 0 and dy == 0 then return end
        onDelta(dx, dy)
        last = { x = last.x + dx, y = last.y + dy }
    end, { timeout = 16, type = "repeat" })
end

hl.bind("SUPER + CTRL + mouse:272", function()
    if not drift_active() then return { pass_event = true } end
    startDrag(keyHeld("Control_L", "Control_R"), function(dx, dy)
        hl.dispatch(hl.dsp.layout(("pan %d %d"):format(-dx, -dy)))
    end)
end, { description = "Workspace: Pan Drift canvas (drag)" })
hl.bind("SUPER + CTRL + mouse:272", stopDrag, { release = true })

hl.bind("SUPER + mouse:273", function()
    local win = hl.get_active_window()
    local box = win and placed[win.address]
    if not drift_active() or not box or win.floating then return { pass_event = true } end
    local p = hl.get_cursor_pos()
    local sx = p.x < box.x + box.w / 2 and -1 or 1
    local sy = p.y < box.y + box.h / 2 and -1 or 1
    startDrag(keyHeld("Super_L", "Super_R"), function(dx, dy)
        hl.dispatch(hl.dsp.layout(("resize %d %d %d %d"):format(dx, dy, sx, sy)))
    end)
end)
hl.bind("SUPER + mouse:273", stopDrag, { release = true })
