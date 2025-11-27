--gay
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
        local r, f = "", (b64:find(x)-1)
        for i = 6, 1, -1 do
            r = r .. (f % 2^i - f % 2^(i-1) > 0 and "1" or "0")
        end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do
            c = c + (x:sub(i,i)=="1" and 2^(8-i) or 0)
        end
        return string.char(c)
    end))
end

-- ========================= LOAD FILE =========================
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
        lp:Kick("Failed to connect server")
        return
    end

    local data = HttpService:JSONDecode(resp)
    if not data or data.message then
        lp:Kick("GitHub token or file invalid")
        return
    end

    local decoded = decode(data.content:gsub("\n",""))
    Egg.List = HttpService:JSONDecode(decoded) -- List dạng bạn đưa

    -- ========================= AUTO CHECK HWID =========================
    local okHWID = false

    for _, entry in ipairs(Egg.List) do
        if entry.HWID == Egg.HWID then
            okHWID = true
            break
        end
    end

    if not okHWID then
        lp:Kick("HWID not whitelisted!\nHWID: " .. Egg.HWID)
    end
end

-- ========================= KEY CHECK =========================
function Egg.IsValid(key)
    for _, entry in ipairs(Egg.List or {}) do
        if entry.Key == key then
            return true
        end
    end
    return false
end

return Egg
