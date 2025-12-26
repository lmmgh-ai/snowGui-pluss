--[[
    复选框组件 (Checkbox)
    用于多选场景
    作者: 北极企鹅 & AI优化
    时间: 2025
]]

local view = require(lumenGui_path .. ".view.view")

local checkbox = view:new()
checkbox.__index = checkbox

-- 构造函数
function checkbox:new(tab)
    local new_obj = view.new(self, tab)
    new_obj.type = "checkbox"
    
    -- 复选框特有属性
    new_obj.checked = tab.checked or false       -- 是否选中
    new_obj.label = tab.label or tab.text or ""  -- 标签文本
    new_obj.boxSize = tab.boxSize or 20          -- 复选框大小
    new_obj.spacing = tab.spacing or 8           -- 框与文本间距
    new_obj.checkColor = tab.checkColor or {0.2, 0.7, 0.3, 1}  -- 勾选颜色
    new_obj.disabledColor = tab.disabledColor or {0.6, 0.6, 0.6, 1}  -- 禁用颜色
    new_obj.disabled = tab.disabled or false     -- 是否禁用
    
    -- 默认样式
    if not tab.backgroundColor then
        new_obj.backgroundColor = {1, 1, 1, 1}
    end
    if not tab.borderColor then
        new_obj.borderColor = {0.3, 0.3, 0.3, 1}
    end
    if not tab.textColor then
        new_obj.textColor = {0, 0, 0, 1}
    end
    
    -- 自动计算宽高
    if not tab.width then
        new_obj.width = new_obj.boxSize + new_obj.spacing + 100
    end
    if not tab.height then
        new_obj.height = math.max(new_obj.boxSize, new_obj.textSize or 14) + 4
    end
    
    return new_obj
end

-- 切换选中状态
function checkbox:toggle()
    if self.disabled then
        return
    end
    
    self.checked = not self.checked
    
    -- 触发回调
    if self.on_toggle then
        self:on_toggle(self.checked)
    end
    if self.on_change then
        self:on_change(self.checked)
    end
end

-- 设置选中状态
function checkbox:setChecked(checked)
    if self.disabled then
        return
    end
    
    if self.checked ~= checked then
        self.checked = checked
        
        if self.on_change then
            self:on_change(self.checked)
        end
    end
end

-- 点击事件
function checkbox:on_click(id, x, y, dx, dy, istouch, pre)
    self:toggle()
end

-- 绘制
function checkbox:draw()
    if not self.visible then return end
    
    local gx, gy = self:get_global_position()
    
    -- 计算复选框位置（居中对齐）
    local boxY = gy + (self.height - self.boxSize) / 2
    
    -- 绘制复选框背景
    local bgColor = self.disabled and self.disabledColor or self.backgroundColor
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", gx, boxY, self.boxSize, self.boxSize)
    
    -- 绘制边框
    local borderColor = self.disabled and self.disabledColor or 
                        (self.isHover and self.hoverColor or self.borderColor)
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", gx, boxY, self.boxSize, self.boxSize)
    
    -- 绘制勾选标记
    if self.checked then
        love.graphics.setColor(self.checkColor)
        love.graphics.setLineWidth(3)
        
        -- 绘制勾号
        local padding = 4
        local x1 = gx + padding
        local y1 = boxY + self.boxSize / 2
        local x2 = gx + self.boxSize / 2 - 1
        local y2 = boxY + self.boxSize - padding
        local x3 = gx + self.boxSize - padding
        local y3 = boxY + padding
        
        love.graphics.line(x1, y1, x2, y2, x3, y3)
    end
    
    -- 绘制标签文本
    if self.label and self.label ~= "" then
        local font = self.gui and self.gui.font_manger and 
                     self.gui.font_manger:get_font(self.font, self.textSize) or 
                     love.graphics.getFont()
        
        love.graphics.setFont(font)
        local textColor = self.disabled and self.disabledColor or self.textColor
        love.graphics.setColor(textColor)
        
        local textX = gx + self.boxSize + self.spacing
        local textY = gy + (self.height - font:getHeight()) / 2
        love.graphics.print(self.label, textX, textY)
    end
    
    -- 绘制子视图
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

-- 选中状态改变回调（可重写）
function checkbox:on_toggle(checked)
    -- 子类可以重写此方法
end

function checkbox:on_change(checked)
    -- 子类可以重写此方法
end

return checkbox
