local view = require (lumenGui_path .. ".view.view")
local switch_button = view:new()
switch_button.__index = switch_button
--
function switch_button:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type              = "switch_button", --类型
        text              = "switch_button",
        textColor         = { 0, 0, 0, 1 },
        hoverColor        = { 0.8, 0.8, 1, 1 },
        pressedColor      = { 0.6, 1, 1, 1 },
        backgroundColor   = { 0.6, 0.6, 1, 1 },
        borderColor       = { 0, 0, 0, 1 },
        --
        state             = false,                -- 默认关闭状态
        animationProgress = 0,                    -- 动画进度 (0-1)
        animationSpeed    = 0.3,                  -- 动画速度
        on_color          = { 0.2, 0.8, 0.3, 1 }, -- 开启状态颜色 (绿色)
        off_color         = { 0.8, 0.2, 0.2, 1 }, -- 关闭状态颜色 (红色)
        knob_color        = { 1, 1, 1, 1 },       -- 滑块颜色 (白色)
        radius            = 50,                   -- 圆角半径
        knob_padding      = 4,                    -- 滑块内边距
        knob_width        = 50,                   -- 滑块宽度

        --
        x                 = 0,
        y                 = 0,
        width             = 50,
        height            = 25,
        --
        parent            = nil, --父视图
        name              = "",  --以自己内存地址作为唯一标识
        id                = "",  --自定义索引
        children          = {},  -- 子视图列表
        _layer            = 1,   --图层
        _draw_order       = 1,   --默认根据 数值越大在当前图层越在前(目前视图在图层1起作用)
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

function switch_button:init()
    self.radius     = self.height * 0.5                   -- 圆角半径
    self.knob_width = self.height - self.knob_padding * 2 -- 滑块宽度
end

-- 更新按钮状态和动画
function switch_button:update(dt)
    local targetProgress = self.state and 1 or 0
    if self.animationProgress > 0 or self.animationProgress < 1 then
        self.animationProgress = math.min(1, math.max(0, self.animationProgress +
            (targetProgress - self.animationProgress) * (self.animationSpeed * dt * 60)))
    end
    --print(self.animationProgress)
end

-- 绘制按钮
function switch_button:draw()
    -- 绘制背景
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, self.radius, self.radius)

    -- 绘制状态底色 (根据当前动画进度混合颜色)
    local r, g, b = self:getCurrentColor()
    love.graphics.setColor(r, g, b, 0.3) -- 半透明状态底色
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, self.radius, self.radius)

    -- 计算滑块位置 (带动画过渡)
    local knobX = self.x + self.knob_padding +
        (self.width - self.knob_width - self.knob_padding * 2) * self.animationProgress

    -- 绘制滑块
    love.graphics.setColor(self.knob_color)
    love.graphics.rectangle("fill", knobX, self.y + self.knob_padding, self.knob_width,
        self.height - self.knob_padding * 2, self.knob_width * 0.5)

    -- 可选: 绘制状态文本
    local text = self.state and "ON" or "OFF"
    -- 绘制文本
    love.graphics.setColor(self.textColor)
    local font = self:get_font(self.font, self.textSize)
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, self.x + (self.width - textWidth) / 2, self.y + (self.height - textHeight) / 2)
end

-- 获取当前颜色 (根据动画进度混合开启和关闭状态颜色)
function switch_button:getCurrentColor()
    local r = self.off_color[1] + (self.on_color[1] - self.off_color[1]) * self.animationProgress
    local g = self.off_color[2] + (self.on_color[2] - self.off_color[2]) * self.animationProgress
    local b = self.off_color[3] + (self.on_color[3] - self.off_color[3]) * self.animationProgress
    return r, g, b
end

-- 检查是否点击了按钮
function switch_button:on_click()
    --切换按钮状态
    self:toggle()
    --print(self.animationProgress)
end

-- 切换按钮状态
function switch_button:toggle(state)
    self.state = state or not self.state
    self:change_state(self.state)
    return true
end

-- 切换按钮状态回调
function switch_button:change_state(state)
    -- body
    print(self.type, self.state)
end

return switch_button
