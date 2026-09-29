-- Usage: lua find_conflicts.lua <shell.lua> <other.lua>...  prints "key<TAB>file<TAB>fileValue<TAB>shellValue"
--        lua find_conflicts.lua --dump <shell.lua>          prints "key<TAB>value"

local dummy = setmetatable({}, {})
getmetatable(dummy).__index = function() return dummy end
getmetatable(dummy).__call = function() return dummy end
getmetatable(dummy).__concat = function() return "" end
getmetatable(dummy).__tostring = function() return "" end

local function serialize(value)
    if type(value) == "boolean" then return value and "1" or "0" end
    if type(value) ~= "table" then return tostring(value) end
    local parts = {}
    for _, v in ipairs(value) do parts[#parts + 1] = serialize(v) end
    return "[" .. table.concat(parts, ", ") .. "]"
end

local function flatten(tbl, prefix, out)
    for k, v in pairs(tbl) do
        local key = prefix and (prefix .. ":" .. tostring(k)) or tostring(k)
        if type(v) == "table" and v[1] == nil then
            flatten(v, key, out)
        else
            out[key] = serialize(v)
        end
    end
end

local function collect(path)
    local options = {}
    local hl = setmetatable({
        config = function(tbl)
            if type(tbl) == "table" then flatten(tbl, nil, options) end
        end,
    }, { __index = function() return dummy end })
    local env = setmetatable({
        hl = hl,
        HOME = os.getenv("HOME"),
        os = setmetatable({ getenv = os.getenv, time = os.time, date = os.date, clock = os.clock },
            { __index = function() return dummy end }),
        require = function() return dummy end,
        print = function() end,
    }, {
        __index = function(_, name)
            local builtin = _G[name]
            if builtin ~= nil and name ~= "io" and name ~= "dofile" and name ~= "loadfile" then
                return builtin
            end
            return dummy
        end,
    })
    local chunk = loadfile(path, "t", env)
    if chunk then pcall(chunk) end
    return options
end

if arg[1] == "--dump" then
    for key, value in pairs(collect(arg[2])) do
        print(key .. "\t" .. value)
    end
    return
end

local shellPath = arg[1]
local shellOptions = collect(shellPath)
for i = 2, #arg do
    if arg[i] ~= shellPath then
        for key, value in pairs(collect(arg[i])) do
            local shellValue = shellOptions[key]
            if shellValue ~= nil and shellValue ~= value then
                print(key .. "\t" .. arg[i] .. "\t" .. value .. "\t" .. shellValue)
            end
        end
    end
end
