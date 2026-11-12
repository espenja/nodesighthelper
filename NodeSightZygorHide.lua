local secret = issecretvalue
if type(secret) ~= "function" then
    print("NodeSightZygorHide: secret-value checks unavailable; hiding not installed.")
    return
end

local function Public(value, kind)
    if secret(value) then return false end
    return type(value) == kind
end

local function Object(value)
    if secret(value) then return false end
    return type(value) == "table" or type(value) == "userdata"
end

local active, disabled = false, false
local saved = {}
local setterWarning, deferredWarning = false, false

local function Read(frame, name)
    local method = frame[name]
    if not Public(method, "function") then return nil end
    local ok, value = pcall(method, frame)
    if not ok then return nil end
    if secret(value) then return nil end
    return value
end

local function SafeParent(frame)
    if not Object(frame) then return nil end
    local forbidden = Read(frame, "IsForbidden")
    if not Public(forbidden, "boolean") then return nil end
    if forbidden then return nil end
    local protected = Read(frame, "IsProtected")
    if not Public(protected, "boolean") then return nil end
    if protected then
        local combat = InCombatLockdown()
        if not Public(combat, "boolean") then return nil end
        if combat then return nil end
    end
    local parent = Read(frame, "GetParent")
    if not Object(parent) then return nil end
    return parent
end

local function SetAlpha(frame, alpha)
    local method = frame.SetAlpha
    if not Public(method, "function") then return false end
    local ok = pcall(method, frame, alpha)
    if not ok and not setterWarning then
        setterWarning = true
        print("NodeSightZygorHide: unexpected SetAlpha error; original alpha retained for restoration. Further setter errors suppressed until reload.")
    end
    return ok
end

local function HideFrame(frame, seen)
    local parent = SafeParent(frame)
    if parent == nil then return end
    if parent ~= Minimap then return end
    if seen[frame] then return end
    seen[frame] = true
    if saved[frame] == nil then
        local alpha = Read(frame, "GetAlpha")
        if not Public(alpha, "number") then return end
        if alpha ~= alpha or alpha < 0 or alpha > 1 then return end
        saved[frame] = alpha
    end
    SetAlpha(frame, 0)
end

local function HideMarker(marker, seen)
    if not Public(marker, "table") then return end
    HideFrame(rawget(marker, "frame_minimap"), seen)
    HideFrame(rawget(marker, "frame_minimapfar"), seen)
end

local function Restore()
    local remaining = 0
    for frame, alpha in next, saved do
        if SafeParent(frame) ~= nil and SetAlpha(frame, alpha) then
            saved[frame] = nil
        else
            remaining = remaining + 1
        end
    end
    if remaining > 0 then
        if not deferredWarning then
            deferredWarning = true
            print("NodeSightZygorHide: restoration deferred for " .. remaining .. " frame(s). Originals retained; retry when out of combat, on the next positive icon scale, or with /nszgh restore.")
        end
    else
        deferredWarning = false
    end
    return remaining
end

SLASH_NODESIGHTZYGORHIDE1 = "/nszgh"
SlashCmdList.NODESIGHTZYGORHIDE = function(message)
    if not Public(message, "string") then return end
    if message:match("^%s*(.-)%s*$"):lower() ~= "restore" then
        print("NodeSightZygorHide: /nszgh restore disables hiding until reload and restores saved alphas.")
        return
    end
    disabled, active = true, false
    print("NodeSightZygorHide: further hiding disabled until reload.")
    if Restore() == 0 then
        print("NodeSightZygorHide: saved alphas restored.")
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_LEAVING_WORLD")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function(_, event)
    if not Public(event, "string") then return end
    if event == "PLAYER_REGEN_ENABLED" then
        if not active then Restore() end
    else
        active = false
        Restore()
    end
end)

local pointer
if Public(ZGV, "table") then pointer = rawget(ZGV, "Pointer") end
if not Public(pointer, "table") or not Object(Minimap)
    or not Public(Minimap.SetIconScale, "function")
    or not Public(rawget(pointer, "MakeMarkerFrames"), "function") then
    print("NodeSightZygorHide: required Minimap/ZGV.Pointer APIs unavailable; hiding not installed.")
    return
end

local function Collect(name, pooled, seen)
    local collection = rawget(pointer, name)
    if not Public(collection, "table") then return end
    for key, marker in next, collection do
        if pooled then
            HideMarker(key, seen)
        else
            HideMarker(marker, seen)
        end
    end
end

hooksecurefunc(pointer, "MakeMarkerFrames", function(_, marker)
    if active and not disabled then HideMarker(marker, {}) end
end)

hooksecurefunc(Minimap, "SetIconScale", function(_, scale)
    if not Public(scale, "number") then return end
    if scale ~= scale or scale == math.huge or scale == -math.huge then return end
    if scale == 0 then
        if disabled then return end
        active = true
        local seen = {}
        Collect("waypoints", false, seen)
        Collect("waypoints_ants", false, seen)
        Collect("unusedMarkers", true, seen)
    elseif scale > 0 then
        active = false
        Restore()
    end
end)
