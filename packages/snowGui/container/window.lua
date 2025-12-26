local view = require(lumenGui_path .. ".view.view")
local window = view:new()
window.__index = window
function window:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type              = "window",
        title             = "window",               -- 窗口标题
        is_title_Dragging = false,                  -- 是否正在拖拽

        isResizable       = true,                   -- 是否可调整大小
        isMinimized       = false,                  -- 是否最小化
        isMaximized       = false,                  -- 是否最大化
        --
        min_width         = 0,                      --调整窗口最小宽度
        min_height        = 25,                     --调整窗口最小高度
        originalX         = 100,                    -- 原始X坐标（用于还原）
        originalY         = 100,                    -- 原始Y坐标（用于还原）
        originalWidth     = 300,                    -- 原始宽度（用于还原）
        originalHeight    = 200,                    -- 原始高度（用于还原）
        titleBarHeight    = 25,                     -- 标题栏高度
        borderWidth       = 10,                     -- 边框宽度（用于调整大小）
        --
        backgroundColor   = { 0.9, 0.9, 0.9, 0.9 }, -- 背景颜色
        titleBarColor     = { 0.2, 0.4, 0.8, 1 },   -- 标题栏颜色
        borderColor       = { 0.1, 0.1, 0.1, 1 },   -- 边框颜色
        textColor         = { 1, 1, 1, 1 },         -- 文字颜色
        buttons           = {},                     -- 窗口按钮集合
        content           = "window",               -- 窗口内容
        visible           = true,                   -- 窗口是否可见
        --
        x                 = 0,
        y                 = 0,
        width             = 100,
        height            = 100,
        --
        parent            = nil, --父视图
        name              = "",  --以自己内存地址作为唯一标识
        id                = "",  --自定义索引
        children          = {},  -- 子视图列表
        _layer            = 1,   --图层
        --因为是弹窗类比默认高一等级
        _draw_order       = 2,   --默认根据 数值越大在当前图层越在前(目前视图在图层1起作用)
        gui               = nil, --管理器索引
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

function window:init()
    --初始化窗口按钮
    self:createButtons()

    --更新窗口按钮
    self:updateButtons()
end

function window:on_create()
    -- body
    local font          = self:get_font(self.font, self.textSize)
    local textWidth     = font:getWidth(self.title)
    --local textHeight = font:getHeight()
    --
    self.min_width      = (#self.buttons) * self.titleBarHeight + textWidth --调整窗口最小宽度
    self.min_height     = self.titleBarHeight * 2                           --调整窗口最小高度
    --
    self.width          = math.max(self.min_width, self.width)
    self.height         = math.max(self.min_height, self.height)
    local width, height = self:get_window_wh()
    --self.x              = (width - self.width) / 2
    --self.y              = (height - self.height) / 2
    --更新窗口按钮
    self:updateButtons()
end

--如果返回值为true 则通知父视图与子视图
--默认不通知 只有需要响应手动通知
function window:change_from_self(child_view)
    --
    --更新窗口按钮
    self:updateButtons()
    --返回两个参数 true通知父布局更新 true通知子视图更新
    return false, true;
end

--额外带标题栏需要重写绘图函数
function window:_draw()
    if self.visible then
        local font = self:get_font(self.font, self.textSize)
        love.graphics.setFont(font)
        self:draw()
        -- 绘制子视图
        love.graphics.push()
        --额外增加标题的偏移
        love.graphics.translate(self.x, self.y + self.titleBarHeight)
        --local x, y = self:get_world_Position(0, 0)
        --开启剪裁
        --love.graphics.setScissor(x, y, self.width, self.height)
        for i, child in pairs(self.children) do
            --print(i)
            child:_draw()
        end
        --关闭剪裁
        -- love.graphics.setScissor()
        love.graphics.pop()
        -- 绘制调整大小手柄
        if self.isResizable and not self.isMaximized and not self.isMinimized then
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.polygon("fill",
                self.x + self.width - 10, self.y + self.height,
                self.x + self.width, self.y + self.height - 10,
                self.x + self.width, self.y + self.height)
        end
    end
end

--额外带标题栏需要重写传递给子视图的位置
--全局点转换相对点
function window:get_local_Position(x, y, child)
    local parent = self.parent
    local x1, y1 = x - self.x, y - self.y
    if child then
        y1 = y - self.y - self.titleBarHeight
    end
    if parent then
        return parent:get_local_Position(x1, y1)
    else
        return x1, y1;
    end
end

--相对点转换全局点
function window:get_world_Position(x, y, child)
    local parent = self.parent
    local x1, y1 = x + self.x, y + self.y
    if child then
        y1 = y + self.y + self.titleBarHeight
    end
    if parent then
        return parent:get_world_Position(x1, y1)
    else
        return x1, y1;
    end
end

--重写获取高度函数
function window:get_wh(child)
    if child then
        return self.width, self.height - self.titleBarHeight
    else
        return self.width, self.height
    end
end

-- 检测点全局点是否在视图内
function window:containsPoint(x, y)
    local absX, absY = self:get_world_Position(0, 0)
    --print(x >= absX and x <= absX + self.width andy >= absY and y <= absY + self.height)
    return x >= absX and x <= absX + self.width and
        y >= absY and y <= absY + self.height
end

--事件拦截机制 如果此函数返回false 则输入事件不会传递给子视图
--通常用于 点击父视图区域外将不会触发子视图情况
function window:_event_intercept(x, y, child)
    --判断按钮 高优先级
    -- 检查是否点击了调整大小区域
    if self:isMouseInResizeArea(x, y) and not self.isMaximized and not self.isMinimized then
        -- print(self.isMaximized)
        return false
    end

    --print(123)
    --默认向下传递
    return true
end

function window:draw()
    if not self.visible then return end

    -- 保存当前的绘图状态
    love.graphics.push()

    -- 绘制窗口背景
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    -- 绘制标题栏
    love.graphics.setColor(self.titleBarColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.titleBarHeight)

    -- 绘制窗口边框
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.titleBarHeight)

    -- 绘制文本
    love.graphics.setColor(self.textColor)
    local font = self:get_font(self.font, self.textSize)
    --local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    love.graphics.print(self.title, self.x + 10, self.y + (self.titleBarHeight - textHeight) / 2)
    -- 绘制窗口按钮
    for i, button in ipairs(self.buttons) do
        -- 绘制按钮背景
        --love.graphics.setColor(0.7, 0.7, 0.7, 1)
        -- love.graphics.rectangle("fill", self.x + button.x, self.y + button.y, button.width, button.height)

        -- 绘制按钮边框
        --love.graphics.setColor(0.3, 0.3, 0.3, 1)
        --love.graphics.rectangle("line", self.x + button.x, self.y + button.y, button.width, button.height)
        love.graphics.setColor(self.textColor)
        -- 绘制按钮文字
        if button.text == "--" then
            local cy = self.y + button.y + button.height / 2
            love.graphics.line(self.x + button.x + 10, cy, self.x + button.x + button.width - 10, cy)
        elseif button.text == "X" then
            local ox = self.x + button.x + 10
            local oy = self.y + button.y + 10
            local ox1 = self.x + button.x + button.width - 10
            local oy1 = self.y + button.y + button.height - 10
            love.graphics.line(ox, oy, ox1, oy1)
            love.graphics.line(ox1, oy, ox, oy1)
        elseif button.text == "[_]" then
            local cy = self.y + button.y + button.height / 2
            local cx = self.x + button.x + button.width / 2
            if self.isMaximized then
                love.graphics.rectangle("line", self.x + button.x + 5, cy - 5, button.width / 2 - 3,
                    button.height / 2 - 3)
                love.graphics.rectangle("line", cx - 5, self.y + button.y + 5, button.width / 2 - 2,
                    button.height / 2 - 2)
            else
                local ox = self.x + button.x + 10
                local oy = self.y + button.y + 10
                local ow = button.width - 20
                local oh = button.height - 20
                love.graphics.rectangle("line", ox, oy, ow, oh)
            end
        end
    end



    -- 绘制窗口内容（如果窗口没有最小化）
    if not self.isMinimized then
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf(self.content,
            self.x + 10,
            self.y + self.titleBarHeight + 10,
            self.width - 20,
            "left")
    end

    -- 恢复之前的绘图状态
    love.graphics.pop()
end

-- 创建窗口控制按钮
function window:createButtons()
    local buttonSize = self.titleBarHeight --按钮大小
    --local rightOffset = self.width - buttonSpacing
    --[[]]
    local W_width = self.width;
    local titleBarHeight = self.titleBarHeight --标题栏高度
    -- 关闭按钮
    table.insert(self.buttons, {
        x = 0,
        y = 0,
        width = buttonSize,
        height = buttonSize,
        text = "X", --大写x
        action = function(self)
            --self.visible = false
            self:set_visible(false) --隐藏
        end
    })

    -- 最大化浮窗切换按钮
    table.insert(self.buttons, {
        x = 0,
        y = 0,
        width = buttonSize,
        height = buttonSize,
        text = "[_]",
        action = function(self)
            --最大化
            if not self.isMaximized then
                self.originalX      = self.x
                self.originalY      = self.y
                self.originalWidth  = self.width
                self.originalHeight = self.height
                self.x              = 0
                self.y              = 0
                --self.width          = love.graphics.getWidth()
                -- self.height         = love.graphics.getHeight()
                self:set_wh(self:get_window_wh())
                self.isMaximized = true
                self.isMinimized = false
            else --浮窗化
                self.x = self.originalX
                self.y = self.originalY
                -- self.width       = self.originalWidth
                -- self.height      = self.originalHeight
                self:set_wh(self.originalWidth, self.originalHeight)
                self.isMaximized = false
                self.isMinimized = false
            end
        end
    })

    -- 最小化按钮
    table.insert(self.buttons, {
        x = 0,
        y = 0,
        width = buttonSize,
        height = buttonSize,
        text = "--",
        action = function(self)
            if self.isMinimized then --关闭最小
                --self.height = self.originalHeight
                --self.width = self.originalWidth
                self:set_wh(self.originalHeight, self.originalWidth)
                --
                self.isMinimized = false
                self.isMaximized = false
            else --最小化
                local value = (#self.buttons + 1) * self.titleBarHeight


                self.originalWidth  = math.max(value, self.width)
                self.originalHeight = math.max(value, self.height)
                --
                self.x              = self.originalX
                self.y              = self.originalY
                --self.height         = self.titleBarHeight
                --self.width          = self.min_width
                self:set_wh(self.min_width, self.titleBarHeight)
                --
                self.isMinimized = true
                self.isMaximized = false
            end
        end
    })

    --设置窗口可调整最小宽度
    self.min_width = #self.buttons * titleBarHeight
end

-- 更新按钮位置（当窗口大小改变时）
function window:updateButtons()
    -- 更新按钮的Y坐标（居中）
    local x = self.width
    for i, button in ipairs(self.buttons) do
        button.x = x - i * self.titleBarHeight
        button.y = 0
    end
end

-- 检查鼠标是否在标题栏内
function window:isMouseInTitleBar(x, y)
    local mx, my = self:get_local_Position(x, y)
    return mx >= 0 and mx <= self.width and
        my >= 0 and my <= self.titleBarHeight
end

-- 检查鼠标是否在调整大小区域
function window:isMouseInResizeArea(x, y)
    if not self.isResizable then return false end
    -- print(x, y)
    local mx, my = self:get_local_Position(x, y)
    local borderWidth = self.borderWidth

    return (mx >= self.width - borderWidth and mx <= self.width and
        my >= self.height - borderWidth and my <= self.height)
end

--处理鼠标点击事件
function window:mousepressed(id, x, y, dx, dy, istouch, pre)
    if not self.visible then return false end

    -- 检查是否点击了调整大小区域
    if self:isMouseInResizeArea(x, y) and not self.isMaximized and not self.isMinimized then
        -- print(self.isMaximized)
        self.isResizing    = true
        self.resizeOffsetX = x - (self.x + self.width)
        self.resizeOffsetY = y - (self.y + self.height)
        return true
    end

    -- 检查是否点击了按钮
    for i, btn in ipairs(self.buttons) do
        if x >= self.x + btn.x and x <= self.x + btn.x + btn.width and
            y >= self.y + btn.y and y <= self.y + btn.y + btn.height then
            --按钮点击事件
            btn.action(self)
            --更新窗口按钮
            self:updateButtons()
            return true
        end
    end

    -- 检查是否点击了标题栏（用于拖拽）
    if self:isMouseInTitleBar(x, y) and not self.isMaximized then
        self.is_title_Dragging = true
        return true
    end



    return false
end

-- 处理鼠标释放事件
function window:mousereleased(id, x, y, dx, dy, istouch, pre)
    self.is_title_Dragging = false
    self.isResizing = false
end

-- 处理鼠标移动事件
function window:mousemoved(id, x, y, dx, dy, istouch, pre)
    if not self.visible then return end

    -- 处理窗口调整大小
    if self.isResizing and not self.isMaximized and not self.isMinimized then
        local value = (#self.buttons + 1) * self.titleBarHeight
        local width = math.max(self.min_width, self.width + dx)
        local height = math.max(self.min_height, self.height + dy)
        self:set_wh(width, height)
        -- 更新按钮位置
        self:updateButtons()
        return --拦截拖动
    end

    -- 处理窗口拖拽
    if self.is_title_Dragging then
        self.x = self.x + dx
        self.y = self.y + dy
        self.isMinimized = false
        self.isMaximized = false
    end
end

-- 设置窗口内容
function window:setContent(content)
    self.content = content or ""
end

-- 显示窗口
function window:show()
    self.visible = true
end

-- 隐藏窗口
function window:hide()
    self.visible = false
end

-- 切换窗口可见性
function window:toggle()
    self.visible = not self.visible
end

return window;
