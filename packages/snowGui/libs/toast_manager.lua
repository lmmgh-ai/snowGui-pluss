--[[
    消息通知系统 (Toast/Notification System)
    显示临时提示消息
    作者: 北极企鹅 & AI优化
    时间: 2025
]]

local view = require(lumenGui_path .. ".view.view")

-- 单个通知类
local Toast = {}
Toast.__index = Toast

function Toast:new(options)
    local toast = {
        text = options.text or "",
        duration = options.duration or 3,
        type = options.type or "info",  -- info, success, warning, error
        x = 0,
        y = 0,
        width = options.width or 300,
        height = options.height or 60,
        padding = 15,
        textSize = 14,
        alpha = 0,
        targetAlpha = 1,
        lifetime = 0,
        state = "fadein",  -- fadein, showing, fadeout, dead
        fadeTime = 0.3
    }
    
    -- 根据类型设置颜色
    if toast.type == "success" then
        toast.backgroundColor = {0.2, 0.8, 0.3, 1}
        toast.textColor = {1, 1, 1, 1}
    elseif toast.type == "warning" then
        toast.backgroundColor = {1, 0.7, 0.2, 1}
        toast.textColor = {0.1, 0.1, 0.1, 1}
    elseif toast.type == "error" then
        toast.backgroundColor = {0.9, 0.2, 0.2, 1}
        toast.textColor = {1, 1, 1, 1}
    else  -- info
        toast.backgroundColor = {0.3, 0.6, 0.9, 1}
        toast.textColor = {1, 1, 1, 1}
    end
    
    setmetatable(toast, self)
    return toast
end

function Toast:update(dt)
    self.lifetime = self.lifetime + dt
    
    if self.state == "fadein" then
        self.alpha = math.min(1, self.alpha + dt / self.fadeTime)
        if self.alpha >= 1 then
            self.state = "showing"
        end
    elseif self.state == "showing" then
        if self.lifetime >= self.duration - self.fadeTime then
            self.state = "fadeout"
        end
    elseif self.state == "fadeout" then
        self.alpha = math.max(0, self.alpha - dt / self.fadeTime)
        if self.alpha <= 0 then
            self.state = "dead"
        end
    end
end

function Toast:draw(font)
    if self.state == "dead" then
        return
    end
    
    -- 绘制阴影
    love.graphics.setColor(0, 0, 0, 0.3 * self.alpha)
    love.graphics.rectangle("fill", self.x + 3, self.y + 3, self.width, self.height, 5, 5)
    
    -- 绘制背景
    local bgColor = {
        self.backgroundColor[1],
        self.backgroundColor[2],
        self.backgroundColor[3],
        self.backgroundColor[4] * self.alpha
    }
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
    
    -- 绘制文本
    love.graphics.setFont(font)
    local textColor = {
        self.textColor[1],
        self.textColor[2],
        self.textColor[3],
        self.textColor[4] * self.alpha
    }
    love.graphics.setColor(textColor)
    
    -- 文本换行
    local wrappedText, wrappedHeight = font:getWrap(
        self.text,
        self.width - self.padding * 2
    )
    
    local textY = self.y + (self.height - wrappedHeight[1] * #wrappedText) / 2
    
    for i, line in ipairs(wrappedText) do
        local lineY = textY + (i - 1) * wrappedHeight[1]
        love.graphics.print(line, self.x + self.padding, lineY)
    end
end

function Toast:isDead()
    return self.state == "dead"
end

-- 通知管理器
local toast_manager = {
    toasts = {},
    position = "top",  -- top, bottom, topleft, topright, bottomleft, bottomright, center
    spacing = 10,
    margin = 20,
    maxToasts = 5,
    gui = nil
}

-- 显示通知
function toast_manager:show(text, duration, type)
    -- 限制通知数量
    if #self.toasts >= self.maxToasts then
        table.remove(self.toasts, 1)
    end
    
    local toast = Toast:new({
        text = text,
        duration = duration or 3,
        type = type or "info"
    })
    
    table.insert(self.toasts, toast)
    self:updatePositions()
    
    return toast
end

-- 便捷方法
function toast_manager:info(text, duration)
    return self:show(text, duration, "info")
end

function toast_manager:success(text, duration)
    return self:show(text, duration, "success")
end

function toast_manager:warning(text, duration)
    return self:show(text, duration, "warning")
end

function toast_manager:error(text, duration)
    return self:show(text, duration, "error")
end

-- 更新通知位置
function toast_manager:updatePositions()
    if not self.gui then
        return
    end
    
    local screenW, screenH = self.gui:get_window_wh()
    
    for i, toast in ipairs(self.toasts) do
        local index = i - 1
        
        if self.position == "top" then
            toast.x = (screenW - toast.width) / 2
            toast.y = self.margin + index * (toast.height + self.spacing)
        elseif self.position == "bottom" then
            toast.x = (screenW - toast.width) / 2
            toast.y = screenH - self.margin - (index + 1) * toast.height - index * self.spacing
        elseif self.position == "topleft" then
            toast.x = self.margin
            toast.y = self.margin + index * (toast.height + self.spacing)
        elseif self.position == "topright" then
            toast.x = screenW - toast.width - self.margin
            toast.y = self.margin + index * (toast.height + self.spacing)
        elseif self.position == "bottomleft" then
            toast.x = self.margin
            toast.y = screenH - self.margin - (index + 1) * toast.height - index * self.spacing
        elseif self.position == "bottomright" then
            toast.x = screenW - toast.width - self.margin
            toast.y = screenH - self.margin - (index + 1) * toast.height - index * self.spacing
        elseif self.position == "center" then
            toast.x = (screenW - toast.width) / 2
            toast.y = (screenH - toast.height) / 2
        end
    end
end

-- 设置位置
function toast_manager:setPosition(position)
    self.position = position
    self:updatePositions()
end

-- 更新
function toast_manager:update(dt)
    -- 更新所有通知
    for i = #self.toasts, 1, -1 do
        local toast = self.toasts[i]
        toast:update(dt)
        
        -- 移除死亡的通知
        if toast:isDead() then
            table.remove(self.toasts, i)
        end
    end
    
    -- 更新位置（处理移除后的重新排列）
    self:updatePositions()
end

-- 绘制
function toast_manager:draw()
    if not self.gui then
        return
    end
    
    local font = self.gui.font_manger and 
                 self.gui.font_manger:get_font("default", 14) or 
                 love.graphics.getFont()
    
    for _, toast in ipairs(self.toasts) do
        toast:draw(font)
    end
end

-- 清除所有通知
function toast_manager:clear()
    self.toasts = {}
end

-- 获取活动通知数量
function toast_manager:getCount()
    return #self.toasts
end

-- 初始化（与 GUI 关联）
function toast_manager:init(gui)
    self.gui = gui
end

return toast_manager
