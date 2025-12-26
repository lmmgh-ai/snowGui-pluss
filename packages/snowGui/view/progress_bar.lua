--[[
    进度条组件 (Progress Bar)
    显示任务或加载进度
    作者: 北极企鹅 & AI优化
    时间: 2025
]]

local view = require(lumenGui_path .. ".view.view")

local progress_bar = view:new()
progress_bar.__index = progress_bar

-- 构造函数
function progress_bar:new(tab)
    local new_obj = view.new(self, tab)
    new_obj.type = "progress_bar"
    
    -- 进度条特有属性
    new_obj.value = tab.value or 0              -- 当前值 (0-100)
    new_obj.min = tab.min or 0                  -- 最小值
    new_obj.max = tab.max or 100                -- 最大值
    new_obj.showText = tab.showText ~= false    -- 是否显示文本
    new_obj.textFormat = tab.textFormat or "%.0f%%"  -- 文本格式
    new_obj.barColor = tab.barColor or {0.2, 0.7, 0.3, 1}  -- 进度条颜色
    new_obj.borderWidth = tab.borderWidth or 2  -- 边框宽度
    new_obj.animated = tab.animated ~= false    -- 是否使用动画
    new_obj._displayValue = new_obj.value       -- 用于动画的显示值
    
    -- 默认样式
    if not tab.backgroundColor then
        new_obj.backgroundColor = {0.9, 0.9, 0.9, 1}
    end
    if not tab.borderColor then
        new_obj.borderColor = {0.5, 0.5, 0.5, 1}
    end
    if not tab.width then
        new_obj.width = 200
    end
    if not tab.height then
        new_obj.height = 30
    end
    
    return new_obj
end

-- 设置进度值
function progress_bar:setValue(value)
    value = math.max(self.min, math.min(self.max, value))
    
    if self.animated and self.gui and self.gui.animation then
        -- 使用动画平滑过渡
        self.gui.animation.manager:animate(
            self,
            "_displayValue",
            value,
            0.3,
            self.gui.animation.easing.quadOut
        )
    else
        self._displayValue = value
    end
    
    self.value = value
    
    -- 触发回调
    if self.on_value_change then
        self:on_value_change(value)
    end
end

-- 获取进度百分比
function progress_bar:getPercent()
    return (self.value - self.min) / (self.max - self.min) * 100
end

-- 增加进度
function progress_bar:increment(amount)
    self:setValue(self.value + (amount or 1))
end

-- 减少进度
function progress_bar:decrement(amount)
    self:setValue(self.value - (amount or 1))
end

-- 重置进度
function progress_bar:reset()
    self:setValue(self.min)
end

-- 完成进度
function progress_bar:complete()
    self:setValue(self.max)
end

-- 更新
function progress_bar:update(dt)
    -- 父类更新
    view.update(self, dt)
end

-- 绘制
function progress_bar:draw()
    if not self.visible then return end
    
    local gx, gy = self:get_global_position()
    
    -- 绘制背景
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", gx, gy, self.width, self.height)
    
    -- 绘制边框
    if self.borderWidth > 0 then
        love.graphics.setColor(self.borderColor)
        love.graphics.setLineWidth(self.borderWidth)
        love.graphics.rectangle("line", gx, gy, self.width, self.height)
    end
    
    -- 计算进度条宽度
    local percent = (self._displayValue - self.min) / (self.max - self.min)
    local barWidth = (self.width - self.borderWidth * 2) * percent
    
    -- 绘制进度条
    if barWidth > 0 then
        love.graphics.setColor(self.barColor)
        love.graphics.rectangle(
            "fill",
            gx + self.borderWidth,
            gy + self.borderWidth,
            barWidth,
            self.height - self.borderWidth * 2
        )
    end
    
    -- 绘制文本
    if self.showText then
        local displayPercent = percent * 100
        local text = string.format(self.textFormat, displayPercent)
        
        -- 获取字体
        local font = self.gui and self.gui.font_manger and 
                     self.gui.font_manger:get_font(self.font, self.textSize) or 
                     love.graphics.getFont()
        
        love.graphics.setFont(font)
        love.graphics.setColor(self.textColor)
        
        -- 居中文本
        local textWidth = font:getWidth(text)
        local textHeight = font:getHeight()
        local textX = gx + (self.width - textWidth) / 2
        local textY = gy + (self.height - textHeight) / 2
        
        love.graphics.print(text, textX, textY)
    end
    
    -- 绘制子视图
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

-- 值改变回调（可重写）
function progress_bar:on_value_change(value)
    -- 子类可以重写此方法
end

return progress_bar
