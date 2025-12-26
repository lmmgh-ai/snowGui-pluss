local color = {}
function color.HEX_To_RGBA(hex)
    hex = hex:gsub("#", "") -- 移除#号
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    local a = 1
    if #hex > 6 then
        a = tonumber(hex:sub(7, 8), 16) / 255
    end
    return { r, g, b, a }
end

--[[
-- 示例：转换 "rgba(255, 87, 51, 1)" 为RGB
local r, g, b = hexToRGB("rgba(0, 0, 0, 1)")
print(r, g, b) -- 输出 1.0, 0.34, 0.2
]]
function color.RGBA_To_HEX(RGB)
    local r = RGB[1] or 0
    local g = RGB[2] or 0
    local b = RGB[3] or 0
    local a = RGB[4] or 255
    if r <= 1 then
        r = r * 255
    end
    if g <= 1 then
        g = g * 255
    end
    if b <= 1 then
        b = b * 255
    end
    if a <= 1 then
        a = a * 255
    end
    --print(r, g, b, a)
    --local r = math.floor(r) -- 四舍五入并转换到0-255
    --local g = math.floor(g)
    --local b = math.floor(b)
    --local a = math.floor(a)
    return string.format("#%02X%02X%02X%02X", r, g, b, a)
end

--[[
-- 示例：转换 (1.0, 0.34, 0.2) 为16进制
local hex = rgbToHex(1.0, 0.34, 0.2)
print(hex) -- 输出 "#FF5733"
]]

--print(color.RGBA_To_HEX({ 0.6, 0.6, 1, 1 }))
--print(dump(color.HEX_To_RGBA("#9999FFFF")))
return color;
