--[[
Dialog/Popup 控件 for lmgui3.1
作者：你的名字
用法示例见底部
]]

local view = require(lumenGui_path .. ".view.view")

local dialog = view:new()
dialog.__index = dialog

function dialog:new(tab)
    local new_obj = {
        type              = "dialog",
        x                 = 100,
        y                 = 100,
        width             = 300,
        height            = 180,
        title             = "提示", --头部标记
        title_height      = 50, --头部高度
        bottom_bar_height = 50, --底栏高度
        text              = "",
        modal             = false, -- 是否模态遮罩 遮蔽后弹窗占领屏幕
        buttons           = {}, --按钮合集
        button_width      = 50, --按钮宽度
        button_height     = 20, --按钮高度
        button_gap        = 10, --按钮间隙
        --
        parent            = nil, --父视图
        name              = "", --以自己内存地址作为唯一标识
        id                = "", --自定义索引
        children          = {}, -- 子视图列表
        _layer            = 1, --图层
        _draw_order       = 1, --默认根据 数值越大在当前图层越在前(目前视图在图层1起作用)
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

function dialog:init()
    self:init_buttons()
end

function dialog:on_create()
    --将对话框居中
    local ww, wh = self:get_window_wh()
    self.x = (ww - self.width) / 2
    self.y = (wh - self.height) / 2
    --print(self.x)
end

function dialog:init_buttons()
    --按钮采用局部坐标
    local gap = self.button_gap --间隔
    local btn_w = self.button_width
    local btn_h = self.button_height
    local btn_y = self.height - btn_h - gap
    local total = #self.buttons
    --
    for i, btn in ipairs(self.buttons) do
        local btn_x = self.width - i * btn_w - gap
        -- 独立按钮对象
        --为按钮初始化一些属性
        btn.x = btn_x
        btn.y = btn_y
        btn.width = btn_w
        btn.height = btn_h
        btn.hovered = false
        btn.pressed = false
    end
end

function dialog:draw()
    if not self.visible then return end
    -- 绘制模态遮罩
    if self.modal then
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
    -- 绘制文本
    love.graphics.setColor(self.textColor)
    local font = self:get_font(self.font, self.textSize)
    local textHeight = font:getHeight()
    -- 绘制弹窗
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.printf(self.title, self.x, self.y + 8, self.width, "center")
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.printf(self.text, self.x + 16, self.y + 40, self.width - 32, "left")
    --print(#self.buttons)
    --给继承者绘图接口
    self:content_draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    -- 绘制按钮
    for _, btn in ipairs(self.buttons) do
        -- print(123)
        -- 按钮背景
        if btn.pressed then
            love.graphics.setColor(0.6, 1, 1, 1)
        elseif btn.hovered then
            love.graphics.setColor(0.8, 0.8, 1, 1)
        else
            love.graphics.setColor(0.6, 0.6, 1, 1)
        end

        love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height)
        -- 按钮文字
        local textWidth = font:getWidth(btn.text)
        love.graphics.setColor(self.textColor)
        love.graphics.print(btn.text, btn.x + (btn.width - textWidth) / 2, btn.y + (btn.height - textHeight) / 2)
        --love.graphics.printf(btn.text, btn.x, btn.y + (btn.height - 20) / 2, btn.width, "center")
    end
    love.graphics.pop()
end

function dialog:content_draw()
    -- body
end

function dialog:update(dt)
    -- 可加入动画等
end

function dialog:mousepressed(id, x, y, dx, dy, istouch, pre)
    local x1, y1 = self:get_local_Position(x, y)
    --按钮确认
    for _, btn in ipairs(self.buttons) do
        if self.point_in_rect(x1, y1, btn.x, btn.y, btn.width, btn.height) then
            btn.pressed = true
            if not btn:on_click(btn, self, self.gui) then
                self:_on_click_button(button)
            end
        end
    end
end

function dialog:mousereleased(id, x, y, dx, dy, istouch, pre)
    if not self.visible then return end
    for _, btn in ipairs(self.buttons) do
        if btn.pressed and self.point_in_rect(x, y, btn.x, btn.y, btn.width, btn.height) then
            btn.pressed = false
            if btn.on_click then btn.on_click(self) end
            self:close()
        else
            btn.pressed = false
        end
    end
end

function dialog:mousemoved(id, x, y, dx, dy, istouch, pre)
    local x1, y1 = self:get_local_Position(x, y)
    for _, btn in ipairs(self.buttons) do
        btn.hovered = self.point_in_rect(x1, y1, btn.x, btn.y, btn.width, btn.height)
    end
end

--点击任何一个按钮回调
--如果按钮自定义函数返回true 则不执行此回调
--模板函数
function dialog:_on_click_button(button)
    self:on_click_button(button)
    self:destroy()
end

function dialog:on_click_button(button)

end

return dialog
