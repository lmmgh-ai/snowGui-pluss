--[[
    单选按钮组组件 (Radio Button Group)
    用于单选场景，一组中只能选中一个
    作者: 北极企鹅 & AI优化
    时间: 2025
]]

local view = require(lumenGui_path .. ".view.view")

local radio_group = view:new()
radio_group.__index = radio_group

-- 单选按钮类
local RadioButton = {}
RadioButton.__index = RadioButton

function RadioButton:new(parent, options)
    local btn = {
        parent = parent,
        label = options.label or "",
        value = options.value or options.label,
        x = options.x or 0,
        y = options.y or 0,
        width = options.width or 100,
        height = options.height or 30,
        selected = false,
        circleSize = options.circleSize or 16,
        spacing = options.spacing or 8,
        textSize = options.textSize or 14,
        textColor = options.textColor or {0, 0, 0, 1},
        borderColor = options.borderColor or {0.3, 0.3, 0.3, 1},
        selectedColor = options.selectedColor or {0.2, 0.6, 0.9, 1},
        backgroundColor = options.backgroundColor or {1, 1, 1, 1}
    }
    setmetatable(btn, self)
    return btn
end

function RadioButton:draw(gx, gy)
    local x = gx + self.x
    local y = gy + self.y
    
    -- 计算圆形位置
    local circleY = y + (self.height - self.circleSize) / 2
    local circleX = x
    local centerX = circleX + self.circleSize / 2
    local centerY = circleY + self.circleSize / 2
    local radius = self.circleSize / 2
    
    -- 绘制外圆背景
    love.graphics.setColor(self.backgroundColor)
    love.graphics.circle("fill", centerX, centerY, radius)
    
    -- 绘制外圆边框
    love.graphics.setColor(self.borderColor)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", centerX, centerY, radius)
    
    -- 绘制选中标记（内圆）
    if self.selected then
        love.graphics.setColor(self.selectedColor)
        love.graphics.circle("fill", centerX, centerY, radius * 0.5)
    end
    
    -- 绘制标签
    if self.label ~= "" then
        local font = self.parent.gui and self.parent.gui.font_manger and 
                     self.parent.gui.font_manger:get_font(self.parent.font, self.textSize) or 
                     love.graphics.getFont()
        
        love.graphics.setFont(font)
        love.graphics.setColor(self.textColor)
        
        local textX = circleX + self.circleSize + self.spacing
        local textY = y + (self.height - font:getHeight()) / 2
        love.graphics.print(self.label, textX, textY)
    end
end

function RadioButton:isPointInside(px, py, gx, gy)
    local x = gx + self.x
    local y = gy + self.y
    return px >= x and px <= x + self.width and
           py >= y and py <= y + self.height
end

-- 单选按钮组构造函数
function radio_group:new(tab)
    local new_obj = view.new(self, tab)
    new_obj.type = "radio_group"
    
    -- 单选组特有属性
    new_obj.buttons = {}                    -- 按钮列表
    new_obj.selectedIndex = tab.selectedIndex or -1  -- 选中的按钮索引
    new_obj.selectedValue = nil             -- 选中的值
    new_obj.orientation = tab.orientation or "vertical"  -- 排列方向
    new_obj.spacing = tab.spacing or 5      -- 按钮间距
    new_obj.autoLayout = tab.autoLayout ~= false  -- 是否自动布局
    
    -- 默认样式
    if not tab.backgroundColor then
        new_obj.backgroundColor = {1, 1, 1, 0}
    end
    
    -- 从选项创建按钮
    if tab.options then
        for i, option in ipairs(tab.options) do
            new_obj:addButton(option)
        end
    end
    
    return new_obj
end

-- 添加单选按钮
function radio_group:addButton(options)
    if type(options) == "string" then
        options = {label = options, value = options}
    end
    
    -- 设置按钮位置（如果启用自动布局）
    if self.autoLayout then
        if self.orientation == "vertical" then
            options.x = 0
            options.y = #self.buttons * (options.height or 30) + #self.buttons * self.spacing
        else
            options.x = #self.buttons * (options.width or 100) + #self.buttons * self.spacing
            options.y = 0
        end
    end
    
    local button = RadioButton:new(self, options)
    table.insert(self.buttons, button)
    
    -- 更新容器大小
    if self.autoLayout then
        self:updateSize()
    end
    
    return button
end

-- 更新容器大小
function radio_group:updateSize()
    if #self.buttons == 0 then
        return
    end
    
    if self.orientation == "vertical" then
        local maxWidth = 0
        local totalHeight = 0
        
        for i, btn in ipairs(self.buttons) do
            maxWidth = math.max(maxWidth, btn.width)
            totalHeight = totalHeight + btn.height
            if i > 1 then
                totalHeight = totalHeight + self.spacing
            end
        end
        
        self.width = maxWidth
        self.height = totalHeight
    else
        local totalWidth = 0
        local maxHeight = 0
        
        for i, btn in ipairs(self.buttons) do
            totalWidth = totalWidth + btn.width
            maxHeight = math.max(maxHeight, btn.height)
            if i > 1 then
                totalWidth = totalWidth + self.spacing
            end
        end
        
        self.width = totalWidth
        self.height = maxHeight
    end
end

-- 选择按钮
function radio_group:selectButton(index)
    if index < 1 or index > #self.buttons then
        return
    end
    
    -- 取消所有选择
    for _, btn in ipairs(self.buttons) do
        btn.selected = false
    end
    
    -- 选中指定按钮
    self.buttons[index].selected = true
    self.selectedIndex = index
    self.selectedValue = self.buttons[index].value
    
    -- 触发回调
    if self.on_selection_change then
        self:on_selection_change(self.selectedValue, index)
    end
end

-- 通过值选择按钮
function radio_group:selectByValue(value)
    for i, btn in ipairs(self.buttons) do
        if btn.value == value then
            self:selectButton(i)
            return true
        end
    end
    return false
end

-- 获取选中的值
function radio_group:getSelectedValue()
    return self.selectedValue
end

-- 获取选中的索引
function radio_group:getSelectedIndex()
    return self.selectedIndex
end

-- 点击事件
function radio_group:on_click(id, x, y, dx, dy, istouch, pre)
    local gx, gy = self:get_global_position()
    
    -- 检查点击了哪个按钮
    for i, btn in ipairs(self.buttons) do
        if btn:isPointInside(x, y, gx, gy) then
            self:selectButton(i)
            break
        end
    end
end

-- 绘制
function radio_group:draw()
    if not self.visible then return end
    
    local gx, gy = self:get_global_position()
    
    -- 绘制背景（如果需要）
    if self.backgroundColor[4] > 0 then
        love.graphics.setColor(self.backgroundColor)
        love.graphics.rectangle("fill", gx, gy, self.width, self.height)
    end
    
    -- 绘制所有按钮
    for _, btn in ipairs(self.buttons) do
        btn:draw(gx, gy)
    end
    
    -- 绘制子视图
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

-- 选择改变回调（可重写）
function radio_group:on_selection_change(value, index)
    -- 子类可以重写此方法
end

return radio_group
