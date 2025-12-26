--[[
    性能优化工具库
    提供视图池、脏标记、空间分区等优化功能
    作者: 北极企鹅 & AI优化
    时间: 2025
]]

local performance = {}

-- ============================================
-- 视图对象池 (View Pool)
-- 用于复用视图对象，减少GC压力
-- ============================================
performance.viewPool = {
    pools = {},  -- 按类型分类的对象池 { type = {view1, view2, ...} }
    maxPoolSize = 100  -- 每种类型最大池大小
}

-- 从池中获取视图
function performance.viewPool:get(viewType)
    if not self.pools[viewType] then
        self.pools[viewType] = {}
    end
    
    local pool = self.pools[viewType]
    if #pool > 0 then
        local view = table.remove(pool)
        view.visible = true
        view._pooled = false
        return view
    end
    
    return nil  -- 池中没有可用对象
end

-- 回收视图到池中
function performance.viewPool:recycle(view)
    if not view or view._pooled then
        return false
    end
    
    local viewType = view.type
    if not self.pools[viewType] then
        self.pools[viewType] = {}
    end
    
    local pool = self.pools[viewType]
    if #pool < self.maxPoolSize then
        -- 重置视图状态
        view.visible = false
        view.isHover = false
        view.isPressed = false
        view.isDragging = false
        view._pooled = true
        view.parent = nil
        
        table.insert(pool, view)
        return true
    end
    
    return false  -- 池已满
end

-- 清空对象池
function performance.viewPool:clear(viewType)
    if viewType then
        self.pools[viewType] = {}
    else
        self.pools = {}
    end
end

-- 获取池统计信息
function performance.viewPool:getStats()
    local stats = {}
    local totalCount = 0
    
    for viewType, pool in pairs(self.pools) do
        stats[viewType] = #pool
        totalCount = totalCount + #pool
    end
    
    stats.total = totalCount
    return stats
end

-- ============================================
-- 脏标记系统 (Dirty Flag)
-- 避免不必要的布局重计算
-- ============================================
performance.dirtyFlag = {}

-- 标记视图为脏
function performance.dirtyFlag.markDirty(view, flag)
    flag = flag or "layout"
    
    if not view._dirty then
        view._dirty = {}
    end
    
    view._dirty[flag] = true
    
    -- 向上传播到父视图
    if view.parent and flag == "layout" then
        performance.dirtyFlag.markDirty(view.parent, flag)
    end
end

-- 检查视图是否脏
function performance.dirtyFlag.isDirty(view, flag)
    flag = flag or "layout"
    return view._dirty and view._dirty[flag] == true
end

-- 清除脏标记
function performance.dirtyFlag.clearDirty(view, flag)
    if not view._dirty then
        return
    end
    
    if flag then
        view._dirty[flag] = false
    else
        view._dirty = {}
    end
end

-- ============================================
-- 空间分区 (Spatial Partitioning)
-- 使用简单网格加速碰撞检测
-- ============================================
performance.spatialGrid = {
    cellSize = 100,  -- 网格大小
    grid = {},       -- 网格数据
    bounds = {x = 0, y = 0, width = 800, height = 600}
}

-- 初始化网格
function performance.spatialGrid:init(width, height, cellSize)
    self.bounds.width = width or 800
    self.bounds.height = height or 600
    self.cellSize = cellSize or 100
    self:clear()
end

-- 清空网格
function performance.spatialGrid:clear()
    self.grid = {}
end

-- 计算网格坐标
function performance.spatialGrid:getCellCoords(x, y)
    local cellX = math.floor(x / self.cellSize)
    local cellY = math.floor(y / self.cellSize)
    return cellX, cellY
end

-- 获取网格键
function performance.spatialGrid:getCellKey(cellX, cellY)
    return cellX .. "," .. cellY
end

-- 添加视图到网格
function performance.spatialGrid:insert(view)
    if not view.visible then
        return
    end
    
    -- 计算视图占据的网格范围
    local gx, gy
    if view.get_global_position then
        gx, gy = view:get_global_position()
    else
        gx, gy = view.x or 0, view.y or 0
    end
    local x1, y1 = self:getCellCoords(gx, gy)
    local x2, y2 = self:getCellCoords(gx + view.width, gy + view.height)
    
    -- 将视图添加到所有相关网格
    for cx = x1, x2 do
        for cy = y1, y2 do
            local key = self:getCellKey(cx, cy)
            if not self.grid[key] then
                self.grid[key] = {}
            end
            table.insert(self.grid[key], view)
        end
    end
end

-- 查询点所在的视图
function performance.spatialGrid:query(x, y)
    local cellX, cellY = self:getCellCoords(x, y)
    local key = self:getCellKey(cellX, cellY)
    return self.grid[key] or {}
end

-- 更新网格（重建）
function performance.spatialGrid:rebuild(views)
    self:clear()
    
    for _, view in pairs(views) do
        if view.visible and view.width and view.height then
            self:insert(view)
        end
    end
end

-- ============================================
-- 视图剔除 (View Culling)
-- 剔除屏幕外的视图
-- ============================================
performance.culling = {}

-- 检查视图是否在视口内
function performance.culling.isInViewport(view, viewportX, viewportY, viewportW, viewportH)
    if not view.visible then
        return false
    end
    
    local gx, gy
    if view.get_global_position then
        gx, gy = view:get_global_position()
    else
        gx, gy = view.x or 0, view.y or 0
    end
    
    -- AABB碰撞检测
    return not (gx + view.width < viewportX or
                gx > viewportX + viewportW or
                gy + view.height < viewportY or
                gy > viewportY + viewportH)
end

-- 获取可见视图列表
function performance.culling.getVisibleViews(views, viewportX, viewportY, viewportW, viewportH)
    local visibleViews = {}
    
    for _, view in pairs(views) do
        if performance.culling.isInViewport(view, viewportX, viewportY, viewportW, viewportH) then
            table.insert(visibleViews, view)
        end
    end
    
    return visibleViews
end

-- ============================================
-- 批量渲染 (Batch Rendering)
-- 按材质/纹理分组渲染
-- ============================================
performance.batchRender = {}

-- 收集相同渲染状态的视图
function performance.batchRender.groupByState(views)
    local batches = {}
    
    for _, view in ipairs(views) do
        -- 根据背景色作为批次键（简化示例）
        local key = "default"
        if view.backgroundColor then
            key = table.concat(view.backgroundColor, ",")
        end
        
        if not batches[key] then
            batches[key] = {
                color = view.backgroundColor,
                views = {}
            }
        end
        
        table.insert(batches[key].views, view)
    end
    
    return batches
end

-- ============================================
-- 性能监控 (Performance Monitor)
-- ============================================
performance.monitor = {
    metrics = {
        updateTime = 0,
        drawTime = 0,
        viewCount = 0,
        drawCalls = 0,
        culledViews = 0
    },
    history = {
        updateTimes = {},
        drawTimes = {},
        maxHistory = 60
    }
}

-- 开始计时
function performance.monitor:startTimer(name)
    if not self.timers then
        self.timers = {}
    end
    self.timers[name] = love.timer.getTime()
end

-- 结束计时
function performance.monitor:endTimer(name)
    if not self.timers or not self.timers[name] then
        return 0
    end
    
    local elapsed = love.timer.getTime() - self.timers[name]
    self.timers[name] = nil
    return elapsed
end

-- 记录指标
function performance.monitor:recordMetric(name, value)
    self.metrics[name] = value
    
    -- 记录历史
    if name == "updateTime" or name == "drawTime" then
        local historyKey = name .. "s"
        if not self.history[historyKey] then
            self.history[historyKey] = {}
        end
        
        table.insert(self.history[historyKey], value)
        if #self.history[historyKey] > self.maxHistory then
            table.remove(self.history[historyKey], 1)
        end
    end
end

-- 获取平均值
function performance.monitor:getAverage(name)
    local historyKey = name .. "s"
    local history = self.history[historyKey]
    
    if not history or #history == 0 then
        return 0
    end
    
    local sum = 0
    for _, v in ipairs(history) do
        sum = sum + v
    end
    
    return sum / #history
end

-- 获取性能报告
function performance.monitor:getReport()
    return {
        fps = love.timer.getFPS(),
        updateTime = self.metrics.updateTime * 1000,  -- 转换为毫秒
        drawTime = self.metrics.drawTime * 1000,
        avgUpdateTime = self:getAverage("updateTime") * 1000,
        avgDrawTime = self:getAverage("drawTime") * 1000,
        viewCount = self.metrics.viewCount,
        drawCalls = self.metrics.drawCalls,
        culledViews = self.metrics.culledViews,
        memoryMB = collectgarbage("count") / 1024
    }
end

-- 打印性能报告
function performance.monitor:printReport()
    local report = self:getReport()
    print("=== Performance Report ===")
    print(string.format("FPS: %d", report.fps))
    print(string.format("Update: %.2fms (avg: %.2fms)", report.updateTime, report.avgUpdateTime))
    print(string.format("Draw: %.2fms (avg: %.2fms)", report.drawTime, report.avgDrawTime))
    print(string.format("Views: %d (culled: %d)", report.viewCount, report.culledViews))
    print(string.format("Draw Calls: %d", report.drawCalls))
    print(string.format("Memory: %.2f MB", report.memoryMB))
    print("========================")
end

-- ============================================
-- 实用工具函数
-- ============================================

-- 深度复制表
function performance.deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[performance.deepCopy(orig_key)] = performance.deepCopy(orig_value)
        end
        setmetatable(copy, performance.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- 限制值在范围内
function performance.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- 线性插值
function performance.lerp(a, b, t)
    return a + (b - a) * t
end

return performance
