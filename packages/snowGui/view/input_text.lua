local view = require(lumenGui_path .. ".view.view")
local utf8 = require("utf8")
utf8.sub = function(str, start_pos, end_pos)
    local len = utf8.len(str)
    if not len then
        error("Invalid UTF-8 string")
    end

    start_pos = start_pos or 1
    end_pos = end_pos or len

    -- 处理负数索引
    if start_pos < 0 then
        start_pos = len + start_pos + 1
    end
    if end_pos < 0 then
        end_pos = len + end_pos + 1
    end

    -- 边界检查
    start_pos = math.max(1, math.min(start_pos, len + 1))
    end_pos = math.max(0, math.min(end_pos, len))

    if start_pos > end_pos then
        return ""
    end

    local start_byte = utf8.offset(str, start_pos)
    local end_byte = utf8.offset(str, end_pos + 1)

    if not start_byte then
        return ""
    end

    if not end_byte then
        return string.sub(str, start_byte)
    else
        return string.sub(str, start_byte, end_byte - 1)
    end
end


local input_text = view:new()
input_text.__index = input_text
function input_text:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type            = "input_text", --类型
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.9, 0.9, 0.9, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 255, 255, 255, 1 },
        borderColor     = { 0, 0, 0, 1 },
        text            = text or "Hello World",          -- 输入的文本内容
        isActive        = false,                          -- 是否处于激活状态（正在输入）
        cursorPos       = string.len(defaultValue or ""), -- 光标位置
        scrollX         = 0,                              -- 文本水平滚动偏移
        cursorColor     = { 0, 0, 1, 1 },                 -- 光标颜色
        cursorBlinkTime = 0,                              -- 光标闪烁计时器
        onSelectAll     = false,                          -- 是否全选状态
        visible         = true,                           --是否可见
        ------
        x               = 0,
        y               = 0,
        width           = 100,
        height          = 30,
        --
        parent          = nil, --父视图
        name            = "",  --以自己内存地址作为唯一标识
        id              = "",  --自定义索引
        children        = {},  -- 子视图列表
        _layer          = 1,   --图层
        _draw_order     = 1,   --默认根据 数值越大在当前图层越在前(目前视图在图层1起作用)
        gui             = nil, --管理器索引
    }
    --扫描 将属性挪移到 新对象
    for i, c in pairs(tab or {}) do
        new_obj[i] = c;
    end
    --继承视图
    new_obj.__index = new_obj;
    setmetatable(new_obj, self)
    --执行初始属性函数
    new_obj:_init()
    --返回新对象
    return new_obj;
end

-- 查找单词开头位置
function input_text:findWordStart(pos)
    local i = pos
    -- 跳过空白字符
    while i > 0 and utf8.sub(self.text, i, i):match("%s") do
        i = i - 1
    end
    -- 跳过非空白字符
    while i > 0 and not utf8.sub(self.text, i, i):match("%s") do
        i = i - 1
    end
    return i
end

-- 查找单词结尾位置
function input_text:findWordEnd(pos)
    local i = pos + 1
    local len = utf8.len(self.text)
    -- 跳过空白字符
    while i <= len and utf8.sub(self.text, i, i):match("%s") do
        i = i + 1
    end
    -- 跳过非空白字符
    while i <= len and not utf8.sub(self.text, i, i):match("%s") do
        i = i + 1
    end
    return i - 1
end

-- 获取输入框文本
function input_text:getValue()
    return self.text
end

-- 设置输入框文本
function input_text:setValue(value)
    self.text = value or ""
    self.cursorPos = utf8.len(self.text) --光标位置
    self.isActive = false                --取消输入状态
end

-- 检查输入框是否处于激活状态
function input_text:isFocused()
    return self.isActive
end

function input_text:draw()
    if not self.visible then return end
    --[[
    -- 绘制按钮背景
    if self.isPressed then
        love.graphics.setColor(self.pressedColor)
    elseif self.hover then
        love.graphics.setColor(self.hoverColor)
    else
        love.graphics.setColor(self.backgroundColor)
    end]]

    -- 保存当前图形状态
    local r, g, b, a = love.graphics.getColor()
    local font = self:get_font(self.font, self.textSize)

    -- 绘制背景
    if self.isActive then
        love.graphics.setColor(self.pressedColor)
    else
        love.graphics.setColor(self.borderColor)
    end
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    -- 绘制内边框（创建边框效果）
    if self.hover then
        love.graphics.setColor(self.hoverColor)
    else
        love.graphics.setColor(self.backgroundColor)
    end
    love.graphics.rectangle("fill", self.x + 2, self.y + 2, self.width - 4, self.height - 4)

    -- 设置文本颜色和字体
    love.graphics.setColor(self.textColor)


    -- 计算可见文本区域
    local textX = self.x + 5 - self.scrollX
    local textY = self.y + (self.height - font:getHeight()) / 2

    -- 绘制文本
    love.graphics.print(self.text, textX, textY)

    -- 如果输入框处于激活状态，绘制光标
    if self.isActive then
        -- 计算光标位置
        local cursorText = utf8.sub(self.text, 1, self.cursorPos)
        local cursorX = textX + font:getWidth(cursorText)

        -- 处理文本滚动，确保光标始终可见
        if cursorX < self.x + 5 then
            self.scrollX = self.scrollX - (self.x + 5 - cursorX)
        elseif cursorX > self.x + self.width - 5 then
            self.scrollX = self.scrollX + (cursorX - (self.x + self.width - 5))
        end

        -- 重置光标位置（滚动后需要重新计算）
        cursorText = utf8.sub(self.text, 1, self.cursorPos)
        cursorX = textX + font:getWidth(cursorText)

        -- 绘制光标（闪烁效果）
        if self.cursorBlinkTime % 1 < 0.5 then
            love.graphics.setColor(self.cursorColor)
            local text_height = font:getHeight() / 2
            love.graphics.line(cursorX, self.y + text_height, cursorX, self.y + self.height - text_height)
        end
    end
    -- 恢复之前的图形状态
    love.graphics.setColor(r, g, b, a)
end

function input_text:update(dt)
    self.cursorBlinkTime = self.cursorBlinkTime + dt --更新光标闪烁计时器
end

function input_text:keypressed(key)          --键盘按下
    if self.isActive then
        local text_len = utf8.len(self.text) --文字长度
        if key == "backspace" then
            -- 处理全选删除
            if self.onSelectAll then
                self.text = ""
                self.cursorPos = 0
                self.onSelectAll = false
            elseif self.cursorPos > 0 then
                -- 删除光标前一个字符
                local before = utf8.sub(self.text, 1, self.cursorPos - 1)
                local after = utf8.sub(self.text, self.cursorPos + 1, text_len)
                self.text = before .. after
                self.cursorPos = self.cursorPos - 1
            end
            self.cursorBlinkTime = 0
            return true
        elseif key == "delete" then
            -- 删除光标后一个字符
            if self.cursorPos < utf8.len(self.text) then
                local before = utf8.sub(self.text, 1, self.cursorPos)
                local after = utf8.sub(self.text, self.cursorPos + 2, text_len)
                self.text = before .. after
            end
            self.cursorBlinkTime = 0
            return true
        elseif key == "left" then
            -- 光标左移
            if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
                -- Ctrl+Left: 移动到单词开头
                self.cursorPos = self:findWordStart(self.cursorPos)
            else
                self.cursorPos = math.max(0, self.cursorPos - 1)
            end
            self.cursorBlinkTime = 0
            return true
        elseif key == "right" then
            -- 光标右移
            if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
                -- Ctrl+Right: 移动到单词结尾
                self.cursorPos = self:findWordEnd(self.cursorPos)
            else
                self.cursorPos = math.min(utf8.len(self.text), self.cursorPos + 1)
            end
            self.cursorBlinkTime = 0
            return true
        elseif key == "home" then
            -- 移动到行首
            self.cursorPos = 0
            self.cursorBlinkTime = 0
            return true
        elseif key == "end" then
            -- 移动到行尾
            self.cursorPos = utf8.len(self.text)
            self.cursorBlinkTime = 0
            return true
        elseif key == "a" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
            -- Ctrl+A: 全选
            self.onSelectAll = true
            return true
        elseif key == "c" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
            -- Ctrl+C: 复制（这里简化处理）
            return true
        elseif key == "v" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
            -- Ctrl+V: 粘贴（这里简化处理）
            return true
        end
    end
    return false
end

function input_text:_loss_keypressed()       --失去输入权限时执行回调
    self.isActive = false                    --取消输入状态
    if love.system.getOS() == "Android" then --安卓手动关闭输入法
        love.keyboard.setTextInput(false)
    end
    return self:loss_keypressed() --失去输入权限时执行回调
end

function input_text:textinput(text) --文字输入
    -- print(text)
    --print(love.window.getDesktopDimensions())
    if self.isActive then
        -- 如果是全选状态，先清除文本
        if self.onSelectAll then
            self.text = ""
            self.cursorPos = 0
            self.onSelectAll = false
        end

        -- 在光标位置插入字符
        local before = utf8.sub(self.text, 1, self.cursorPos) --光标前
        local after = ""                                      --光标后
        local text_len = utf8.len(self.text)
        if text_len ~= self.cursorPos then
            --print("插入")
            after = utf8.sub(self.text, self.cursorPos, text_len)
            -- print(after)
        end

        self.text = before .. text .. after
        self.cursorPos = self.cursorPos + utf8.len(text) --设置光标位置
        self.cursorBlinkTime = 0                         -- 重置光标闪烁
        --print(before, after, self.cursorPos, utf8.len(self.text))
        self:on_change_text(self.text)
        return true
    end
    return false
end

function input_text:mousepressed(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击
    if love.system.getOS() == "Android" then                     --安卓手动启动输入法
        love.keyboard.setTextInput(true)
    end
    local font = self:get_font(self.font, self.textSize)
    --print(x, y)
    local x1, y1 = self:get_local_Position(x, y) --获取相对点击位置
    self.isActive = true
    self.cursorBlinkTime = 0                     -- 重置光标闪烁

    -- 计算点击位置对应的光标位置
    local textX = 5 - self.scrollX --+self.x
    local relativeX = x1 - textX

    -- 找到最接近点击位置的字符位置
    local minDist = math.huge
    local bestPos = 0
    --print(textX, relativeX)
    for i = 0, utf8.len(self.text) do
        local charX = font:getWidth(utf8.sub(self.text, 1, i))
        local dist = math.abs(relativeX - charX)
        if dist < minDist then
            minDist = dist
            bestPos = i
        end
    end

    self.cursorPos = bestPos
end

function input_text:on_click(...)
    -- body
end

--当文本被改变时
function input_text:on_change_text(text)

end

return input_text;
