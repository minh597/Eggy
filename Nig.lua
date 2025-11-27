-- EggHWID.lua
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer

local Egg = {}

-- Lấy HWID
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

-- Base64 decode
local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function decode(data)
    data = data:gsub("[^" .. b64 .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (b64:find(x) - 1)
        for i = 6, 1, -1 do
            r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
        end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do
            c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
        end
        return string.char(c)
    end))
end

-- Load danh sách HWID từ GitHub
function Egg.LoadList(url, token)
    local success, resp = pcall(function()
        return request({
            Url = url,
            Method = "GET",
            Headers = {
                ["Authorization"] = "token " .. token,
                ["User-Agent"] = "Roblox"
            }
        }).Body
    end)
    if not success or not resp then
        return false, "Failed to connect"
    end

    local data = HttpService:JSONDecode(resp)
    if not data or data.message then
        return false, "File not found or bad token"
    end

    local content = data.content
    if not content then
        return false, "Empty content"
    end

    local json = decode(content:gsub("\n", ""))
    local list = HttpService:JSONDecode(json)
    Egg.List = list
    return true
end

-- Kiểm tra HWID
function Egg.IsValid()
    if not Egg.List then return false end
    for _, v in ipairs(Egg.List) do
        if (type(v) == "table" and v.HWID == Egg.HWID) or v == Egg.HWID then
            return true
        end
    end
    for _, v in pairs(Egg.List) do
        if v == Egg.HWID then
            return true
        end
    end
    return false
end

return Egg
