--[[
    动画系统 (Animation System)
    提供视图属性的平滑过渡动画
    作者: 北极企鹅 & AI优化
    时间: 2025
]]

local animation = {}

-- 缓动函数 (Easing Functions)
animation.easing = {}

-- 线性
function animation.easing.linear(t)
    return t
end

-- 二次方
function animation.easing.quadIn(t)
    return t * t
end

function animation.easing.quadOut(t)
    return t * (2 - t)
end

function animation.easing.quadInOut(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return -1 + (4 - 2 * t) * t
    end
end

-- 三次方
function animation.easing.cubicIn(t)
    return t * t * t
end

function animation.easing.cubicOut(t)
    local f = t - 1
    return f * f * f + 1
end

function animation.easing.cubicInOut(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        local f = 2 * t - 2
        return 0.5 * f * f * f + 1
    end
end

-- 四次方
function animation.easing.quartIn(t)
    return t * t * t * t
end

function animation.easing.quartOut(t)
    local f = t - 1
    return 1 - f * f * f * f
end

function animation.easing.quartInOut(t)
    if t < 0.5 then
        return 8 * t * t * t * t
    else
        local f = t - 1
        return 1 - 8 * f * f * f * f
    end
end

-- 指数
function animation.easing.expoIn(t)
    return t == 0 and 0 or math.pow(2, 10 * (t - 1))
end

function animation.easing.expoOut(t)
    return t == 1 and 1 or 1 - math.pow(2, -10 * t)
end

function animation.easing.expoInOut(t)
    if t == 0 or t == 1 then
        return t
    end
    
    if t < 0.5 then
        return 0.5 * math.pow(2, 20 * t - 10)
    else
        return 0.5 * (2 - math.pow(2, -20 * t + 10))
    end
end

-- 弹性
function animation.easing.elasticIn(t)
    return math.sin(13 * math.pi / 2 * t) * math.pow(2, 10 * (t - 1))
end

function animation.easing.elasticOut(t)
    return math.sin(-13 * math.pi / 2 * (t + 1)) * math.pow(2, -10 * t) + 1
end

function animation.easing.elasticInOut(t)
    if t < 0.5 then
        return 0.5 * math.sin(13 * math.pi / 2 * (2 * t)) * math.pow(2, 10 * (2 * t - 1))
    else
        return 0.5 * (math.sin(-13 * math.pi / 2 * (2 * t - 1 + 1)) * math.pow(2, -10 * (2 * t - 1)) + 2)
    end
end

-- 回弹
function animation.easing.backIn(t)
    local s = 1.70158
    return t * t * ((s + 1) * t - s)
end

function animation.easing.backOut(t)
    local s = 1.70158
    t = t - 1
    return t * t * ((s + 1) * t + s) + 1
end

function animation.easing.backInOut(t)
    local s = 1.70158 * 1.525
    t = t * 2
    if t < 1 then
        return 0.5 * (t * t * ((s + 1) * t - s))
    else
        t = t - 2
        return 0.5 * (t * t * ((s + 1) * t + s) + 2)
    end
end

-- 弹跳
function animation.easing.bounceOut(t)
    if t < 1 / 2.75 then
        return 7.5625 * t * t
    elseif t < 2 / 2.75 then
        t = t - 1.5 / 2.75
        return 7.5625 * t * t + 0.75
    elseif t < 2.5 / 2.75 then
        t = t - 2.25 / 2.75
        return 7.5625 * t * t + 0.9375
    else
        t = t - 2.625 / 2.75
        return 7.5625 * t * t + 0.984375
    end
end

function animation.easing.bounceIn(t)
    return 1 - animation.easing.bounceOut(1 - t)
end

function animation.easing.bounceInOut(t)
    if t < 0.5 then
        return animation.easing.bounceIn(t * 2) * 0.5
    else
        return animation.easing.bounceOut(t * 2 - 1) * 0.5 + 0.5
    end
end

-- ============================================
-- 动画类 (Animator)
-- ============================================
local Animator = {}
Animator.__index = Animator

-- 创建新动画
function Animator:new(target, property, startValue, endValue, duration, easingFunc, onComplete)
    local anim = {
        target = target,           -- 目标对象
        property = property,       -- 要动画的属性名
        startValue = startValue,   -- 起始值
        endValue = endValue,       -- 结束值
        duration = duration or 1,  -- 持续时间（秒）
        elapsed = 0,               -- 已过时间
        easing = easingFunc or animation.easing.linear,  -- 缓动函数
        onComplete = onComplete,   -- 完成回调
        isPlaying = false,
        isPaused = false,
        isComplete = false
    }
    
    setmetatable(anim, self)
    return anim
end

-- 开始动画
function Animator:play()
    self.isPlaying = true
    self.isPaused = false
    self.elapsed = 0
    self.isComplete = false
end

-- 暂停动画
function Animator:pause()
    self.isPaused = true
end

-- 继续动画
function Animator:resume()
    self.isPaused = false
end

-- 停止动画
function Animator:stop()
    self.isPlaying = false
    self.isPaused = false
end

-- 重置动画
function Animator:reset()
    self.elapsed = 0
    self.isComplete = false
    if self.target and self.property then
        self.target[self.property] = self.startValue
    end
end

-- 更新动画
function Animator:update(dt)
    if not self.isPlaying or self.isPaused or self.isComplete then
        return
    end
    
    self.elapsed = self.elapsed + dt
    
    -- 计算进度
    local t = math.min(self.elapsed / self.duration, 1)
    
    -- 应用缓动函数
    local easedT = self.easing(t)
    
    -- 插值计算当前值
    local currentValue = self.startValue + (self.endValue - self.startValue) * easedT
    
    -- 设置目标属性
    if self.target and self.property then
        self.target[self.property] = currentValue
    end
    
    -- 检查是否完成
    if t >= 1 then
        self.isComplete = true
        self.isPlaying = false
        
        -- 调用完成回调
        if self.onComplete then
            self.onComplete(self.target)
        end
    end
end

-- ============================================
-- 动画管理器 (Animation Manager)
-- ============================================
animation.manager = {
    animations = {},  -- 所有活动的动画
    nextId = 1
}

-- 创建并添加动画
function animation.manager:animate(target, property, endValue, duration, easingFunc, onComplete)
    -- 如果目标属性已有动画，先移除
    self:stopProperty(target, property)
    
    -- 获取起始值
    local startValue = target[property] or 0
    
    -- 创建动画
    local anim = Animator:new(target, property, startValue, endValue, duration, easingFunc, onComplete)
    anim.id = self.nextId
    self.nextId = self.nextId + 1
    
    -- 添加到管理器
    self.animations[anim.id] = anim
    
    -- 开始播放
    anim:play()
    
    return anim
end

-- 创建颜色动画
function animation.manager:animateColor(target, property, endColor, duration, easingFunc, onComplete)
    -- 颜色需要分别为RGBA四个通道创建动画
    local startColor = target[property]
    if not startColor then
        return nil
    end
    
    local anims = {}
    for i = 1, 4 do
        local anim = Animator:new(
            startColor,
            i,
            startColor[i] or 0,
            endColor[i] or 0,
            duration,
            easingFunc,
            i == 4 and onComplete or nil  -- 只在最后一个通道完成时调用回调
        )
        anim.id = self.nextId
        self.nextId = self.nextId + 1
        self.animations[anim.id] = anim
        anim:play()
        table.insert(anims, anim)
    end
    
    return anims
end

-- 停止目标对象的所有动画
function animation.manager:stopTarget(target)
    for id, anim in pairs(self.animations) do
        if anim.target == target then
            anim:stop()
            self.animations[id] = nil
        end
    end
end

-- 停止目标对象特定属性的动画
function animation.manager:stopProperty(target, property)
    for id, anim in pairs(self.animations) do
        if anim.target == target and anim.property == property then
            anim:stop()
            self.animations[id] = nil
        end
    end
end

-- 停止所有动画
function animation.manager:stopAll()
    for _, anim in pairs(self.animations) do
        anim:stop()
    end
    self.animations = {}
end

-- 更新所有动画
function animation.manager:update(dt)
    for id, anim in pairs(self.animations) do
        anim:update(dt)
        
        -- 移除已完成的动画
        if anim.isComplete then
            self.animations[id] = nil
        end
    end
end

-- 获取活动动画数量
function animation.manager:getActiveCount()
    local count = 0
    for _ in pairs(self.animations) do
        count = count + 1
    end
    return count
end

-- ============================================
-- 便捷动画函数
-- ============================================

-- 淡入
function animation.fadeIn(target, duration, onComplete)
    if not target.backgroundColor then
        return nil
    end
    
    return animation.manager:animate(
        target.backgroundColor,
        4,  -- alpha通道
        1,
        duration or 0.3,
        animation.easing.quadOut,
        onComplete
    )
end

-- 淡出
function animation.fadeOut(target, duration, onComplete)
    if not target.backgroundColor then
        return nil
    end
    
    return animation.manager:animate(
        target.backgroundColor,
        4,  -- alpha通道
        0,
        duration or 0.3,
        animation.easing.quadOut,
        onComplete
    )
end

-- 滑动到位置
function animation.slideTo(target, x, y, duration, easingFunc, onComplete)
    local animX = animation.manager:animate(
        target,
        "x",
        x,
        duration or 0.5,
        easingFunc or animation.easing.cubicOut
    )
    
    local animY = animation.manager:animate(
        target,
        "y",
        y,
        duration or 0.5,
        easingFunc or animation.easing.cubicOut,
        onComplete
    )
    
    return {animX, animY}
end

-- 缩放
function animation.scaleTo(target, width, height, duration, easingFunc, onComplete)
    local animW = animation.manager:animate(
        target,
        "width",
        width,
        duration or 0.5,
        easingFunc or animation.easing.cubicOut
    )
    
    local animH = animation.manager:animate(
        target,
        "height",
        height,
        duration or 0.5,
        easingFunc or animation.easing.cubicOut,
        onComplete
    )
    
    return {animW, animH}
end

-- 脉冲效果（放大后缩小）
function animation.pulse(target, scale, duration, onComplete)
    local originalW = target.width
    local originalH = target.height
    
    scale = scale or 1.1
    duration = duration or 0.3
    
    -- 第一阶段：放大
    animation.scaleTo(
        target,
        originalW * scale,
        originalH * scale,
        duration / 2,
        animation.easing.quadOut,
        function()
            -- 第二阶段：缩小回原大小
            animation.scaleTo(
                target,
                originalW,
                originalH,
                duration / 2,
                animation.easing.quadOut,
                onComplete
            )
        end
    )
end

-- 抖动效果
function animation.shake(target, intensity, duration, onComplete)
    local originalX = target.x
    local originalY = target.y
    intensity = intensity or 5
    duration = duration or 0.3
    
    local startTime = love.timer.getTime()
    local shakeTimer
    
    shakeTimer = function()
        local elapsed = love.timer.getTime() - startTime
        if elapsed < duration then
            target.x = originalX + math.random(-intensity, intensity)
            target.y = originalY + math.random(-intensity, intensity)
            -- 需要在下一帧继续
        else
            target.x = originalX
            target.y = originalY
            if onComplete then
                onComplete(target)
            end
        end
    end
    
    -- 注意：这个实现需要在外部循环中调用
    return shakeTimer
end

return animation
