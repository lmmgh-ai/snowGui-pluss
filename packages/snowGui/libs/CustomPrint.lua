--加载全局字体
local ChineseFont = ChineseFont
--
local CustomPrint = {
    messages = {},         -- 存储所有消息
    maxDisplayTime = 1,    -- 默认显示5秒
    fadeTime = 0.5,        -- 淡出时间1秒
    lastMessageTime = 0,   -- 最后一条消息的时间
    debounceTimer = 0,     -- 防抖动计时器
    debounceThreshold = 0, -- 防抖动阈值(秒)
    visible = false,       -- 当前是否可见
    boxWidth = 150,        -- 对话框宽度
    boxHeight = 200,       -- 对话框高度
    padding = 10,          -- 内边距
    fontSize = 10,         -- 字体大小
    maxLines = 10          -- 最大显示行数
}

-- 初始化函数
function CustomPrint:load()
    --加载字体
    --local path = "YeZiGongChangTangYingHei-2.ttf"
    local font = love.graphics.newFont(ChineseFont)
    --love.graphics.setFont(font)
    self.font = font or love.graphics.newFont(CustomPrint.fontSize)
    --love.graphics.setFont(CustomPrint.font)
    --local font = love.graphics.getFont()           -- 获取当前字体（默认字体或已设置的字体）
    -- 获取文本宽度和高度
    local text_height = tonumber(font:getHeight()) -- 获取字体行高（单行高度）
    self.boxHeight = self.maxLines * text_height + self.padding * 2

    if love.system.getOS() == "Android" then
        _G.print = function(...)
            if _G.CustomPrint then
                _G.CustomPrint:printf(...)
            end
        end
    end
end

-- 自定义打印函数
function CustomPrint:printf(...)
    local currentTime = love.timer.getTime()

    -- 防抖动处理
    if currentTime - self.lastMessageTime < self.debounceThreshold then
        self.debounceTimer = currentTime
        --print(currentTime, self.debounceThreshold)
        return
    end

    -- 获取所有参数并拼接为字符串
    local args = { ... }
    local message = ""
    for i, v in ipairs(args) do
        message = message .. tostring(v) .. (i < #args and "\t" or "")
    end

    -- 添加时间戳
    local timestamp = string.format("[%.2f]  ", currentTime)
    message = timestamp .. message

    -- 添加到消息列表
    table.insert(self.messages, {
        text = message,
        time = currentTime,
        alpha = 1
    })

    -- 限制消息数量
    if #self.messages > self.maxLines then
        table.remove(self.messages, 1)
    end

    self.lastMessageTime = currentTime
    self.visible = true
end

-- 更新函数
function CustomPrint:update(dt)
    local currentTime = love.timer.getTime()

    -- 检查是否需要隐藏
    if self.visible and currentTime - self.lastMessageTime > self.maxDisplayTime then
        -- 开始淡出
        local fadeProgress = (currentTime - self.lastMessageTime - self.maxDisplayTime) /
            self.fadeTime
        if fadeProgress >= 1 then
            self.visible = false
        end
    end

    -- 更新消息透明度
    for _, msg in ipairs(self.messages) do
        if currentTime - msg.time > self.maxDisplayTime then
            msg.alpha = 1 - math.min(1, (currentTime - msg.time - self.maxDisplayTime) / self.fadeTime)
        end
    end
end

-- 绘制函数
function CustomPrint:draw()
    if not self.visible or #self.messages == 0 then return end
    love.graphics.setFont(self.font)
    -- 计算对话框位置(右上角)
    local screenWidth = love.graphics.getWidth()
    local x = 0 --screenWidth - self.boxWidth - 20
    local y = 0

    -- 绘制对话框背景
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle("fill", x, y, self.boxWidth, self.boxHeight, 5)

    -- 绘制边框
    love.graphics.setColor(0.4, 0.4, 0.4, 0.9)
    love.graphics.rectangle("line", x, y, self.boxWidth, self.boxHeight, 5)

    -- 绘制消息
    local lineHeight = self.font:getHeight()
    local startY = y + self.padding

    -- 从最新消息开始显示
    local displayCount = math.min(#self.messages, self.maxLines)
    for i = 1, displayCount do
        local msg = self.messages[#self.messages - displayCount + i]
        love.graphics.setColor(1, 1, 1, msg.alpha)
        love.graphics.print(msg.text, x + self.padding, startY + (i - 1) * lineHeight)
    end
end

-- 设置显示时间
function CustomPrint:setDisplayTime(seconds)
    self.maxDisplayTime = seconds
end

return CustomPrint
