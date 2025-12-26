--加载全局字体
local ChineseFont = ChineseFont

local FontManager = {
    fonts = {}, -- 主字体表，格式为 fonts[fontName][size] = fontObject
    defaultFont = nil,
    defaultSize = 12
}

-- 初始化字体管理器
function FontManager:init()
    -- 可以在这里预加载一些默认字体

    FontManager.defaultFont = "default"
    startSize               = 1
    endSize                 = 20

    -- 确保字体表存在
    self.fonts["default"]   = {}

    -- 初始化默认字体
    for size = startSize, endSize do
        if not self.fonts["default"][size] then
            self.fonts["default"][size] = love.graphics.newFont(ChineseFont, size)
        end
    end
    --
    return self
end

-- 预加载单个字体
-- @param fontPath 字体文件路径
-- @param fontName 字体标识名
-- @param startSize 起始大小(默认1)
-- @param endSize 结束大小(默认100)
function FontManager:load_Font(fontPath, fontName, startSize, endSize)
    startSize            = startSize or 1
    endSize              = endSize or 100

    -- 确保字体表存在
    self.fonts[fontName] = self.fonts[fontName] or {}

    -- 预加载指定范围内的字体大小
    for size = startSize, endSize do
        if not self.fonts[fontName][size] then
            local success, font = pcall(love.graphics.newFont, fontPath, size)
            local font = font or love.graphics.newFont(size)
            if success then
                self.fonts[fontName][size] = font
            else
                print("Failed to load font " .. fontName .. " size " .. size .. ": " .. font)
                -- 如果加载失败，使用默认字体作为后备
                self.fonts[fontName][size] = love.graphics.newFont(size)
            end
        end
    end
    self.defaultFont = fontName
end

-- 获取字体对象
-- @param fontName 字体标识名
-- @param size 字体大小
-- @return 字体对象，如果不存在则返回默认字体
function FontManager:get_font(fontName, size)
    size = size or self.defaultSize

    -- 确保大小在合理范围内
    size = math.max(1, math.min(100, math.floor(size)))

    -- 检查请求的字体是否存在
    if self.fonts[fontName] and self.fonts[fontName][size] then
        return self.fonts[fontName][size]
    end
    assert(self.fonts["default"], "error:default font nil")
    return self.fonts["default"][size]
end

-- 清理所有字体资源
function FontManager:clear()
    for fontName, sizes in pairs(self.fonts) do
        for size, font in pairs(sizes) do
            font:release()
        end
    end
    self.fonts = {}
end

function FontManager:get_default_fonts(size)
    --  print(size)
    return self.fonts[self.defaultFont][size or 10]
end

--单例模式
return FontManager:init()
