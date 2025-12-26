local view = require (lumenGui_path .. ".view.view")
local frame_layout = view:new()
frame_layout.__index = frame_layout

--[[
帧布局完全用于层级容器 享有原始功能
]]

function frame_layout:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        text            = "frame_layout",
        type            = "frame_layout",
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.8, 0.8, 1, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 0.6, 0.6, 1, 1 },
        borderColor     = { 0, 0, 0, 1 },
        --
        x               = 0,
        y               = 0,
        width           = 200,
        height          = 200,
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

function frame_layout:init()

end

function frame_layout:draw()
    if not self.visible then return end
    -- 绘制按钮背景
    if self.isPressed then
        love.graphics.setColor(self.pressedColor)
    elseif self.isHover then
        love.graphics.setColor(self.borderColor)
    else
        love.graphics.setColor(self.backgroundColor)
    end
    --绘制边框
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    --绘制布局调试线
    love.graphics.line(self.x, self.y, self.x + self.width, self.y + self.height)
    love.graphics.line(self.x + self.width, self.y, self.x, self.y + self.height)
    -- 绘制文本
    love.graphics.setColor(self.textColor)
    local font = self:get_font(self.font, self.textSize)
    local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    love.graphics.print(self.text, self.x, self.y)
end

function frame_layout:on_click(id, x, y, dx, dy, is_touch, pre)
    -- body
    --self:destroy()
    print(self.type, self:get_local_Position(x, y))
end

return frame_layout;
