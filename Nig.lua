local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer

local Egg = {}

-- ========================= GET HWID =========================
local function getHWID()
    local hwid = "Unknown"
    pcall(function()
        if gethwid then hwid = gethwid()
        elseif syn and syn.gethwid then hwid = syn.gethwid()
        elseif Krnl and Krnl.Hwid then hwid = Krnl.Hwid()
        elseif getgenv().gethwid then hwid = getgenv().gethwid()
        elseif getgenv().SecureHardwareID then hwid = getgenv().SecureHardwareID
        end
    end)
    return tostring(hwid or "None")
end

Egg.HWID = getHWID()

-- ========================= BASE64 DECODE =========================
local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function decode(data)
    data = data:gsub("[^" .. b64 .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r,f = "", (b64:find(x)-1)
        for i = 6,1,-1 do
            r = r .. (f % 2^i - f % 2^(i-1) > 0 and "1" or "0")
        end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i=1,8 do
            c = c + (x:sub(i,i) == "1" and 2^(8-i) or 0)
        end
        return string.char(c)
    end))
end

-- ========================= LOAD DATA =========================
function Egg.Load(url, token)
    local ok, resp = pcall(function()
        return request({
            Url = url,
            Method = "GET",
            Headers = {
                ["Authorization"] = "token " .. token,
                ["User-Agent"] = "Roblox"
            }
        }).Body
    end)

    if not ok or not resp then
        lp:Kick("Failed to connect to server")
        return
    end

    local data = HttpService:JSONDecode(resp)
    if not data or data.message then
        lp:Kick("Invalid GitHub token or file not found")
        return
    end

    local decoded = decode(data.content:gsub("\n",""))
    local json = HttpService:JSONDecode(decoded)

    Egg.HWIDS = json.HWIDS or {}
    Egg.KEYS  = json.KEYS  or {}

    -- ===== AUTO CHECK HWID =====
    local valid = false
    for _, v in ipairs(Egg.HWIDS) do
        if v == Egg.HWID then
            valid = true
            break
        end
    end

    if not valid then
        lp:Kick("Your HWID is not whitelisted!\nHWID: "..Egg.HWID)
    end
end

-- ========================= KEY CHECK =========================
function Egg.IsValid(key)
    for _, v in ipairs(Egg.KEYS or {}) do
        if v == key then
            return true
        end
    end
    return false
end

return Egg
