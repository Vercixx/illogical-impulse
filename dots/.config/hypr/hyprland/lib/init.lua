HOME = os.getenv("HOME")

function is_file_exists(name)
   local f = io.open(name, "r")
   if f ~= nil then
      io.close(f)
      return true
   else
      return false
   end
end

function create_if_not_exists(path)
   if not is_file_exists(path) then
      os.execute("mkdir -p \"$(dirname \"" .. path .. "\")\"")
      os.execute("echo '-- This file will not be overwritten across dots-hyprland updates.\n-- The file name is for the sake of organization and does not matter\n-- See the corresponding files in ~/.config/hypr/hyprland for examples' > \"" .. path .. "\"")
      return true
   end
   return false
end

function drift_active()
    local ws = hl.get_active_workspace()
    return ws ~= nil and ws.tiled_layout == "lua:drift"
end

function unless_drift(action)
    return function()
        if drift_active() then return end
        if type(action) == "function" then action() else hl.dispatch(action) end
    end
end

function drift_or(msg, fallback)
    return function()
        if drift_active() then
            hl.dispatch(hl.dsp.layout(msg))
        elseif fallback then
            hl.dispatch(fallback)
        end
    end
end

function workspace_in_group(i)
    local curr = hl.get_active_workspace().id
    local newVal = math.floor((curr - 1) / workspaceGroupSize) * workspaceGroupSize + i
    -- hl.notification.create({ text = "curr " .. curr .. " floor " .. math.floor(curr / 10) .. " new " .. newVal, duration = 5000 })
    return newVal
end
