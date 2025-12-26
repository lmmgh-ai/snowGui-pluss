# snowGui-pluss 故障排除指南

本指南帮助您解决使用 snowGui-pluss 时可能遇到的常见问题。

## 目录

- [安装问题](#安装问题)
- [运行时错误](#运行时错误)
- [性能问题](#性能问题)
- [布局问题](#布局问题)
- [事件处理问题](#事件处理问题)
- [动画问题](#动画问题)
- [调试技巧](#调试技巧)

---

## 安装问题

### 问题: LÖVE2D 版本不兼容

**症状**: 运行时出现函数未定义错误

**解决方案**:
```bash
# 检查 LÖVE2D 版本
love --version

# 确保版本 >= 11.4
```

如果版本过低，请从 [love2d.org](https://love2d.org/) 下载最新版本。

### 问题: 找不到模块

**症状**: `module 'packages.snowGui' not found`

**解决方案**:
```lua
-- 确保正确的目录结构
-- 项目根目录/
--   main.lua
--   packages/
--     snowGui/
--       init.lua
--       ...

-- 在 main.lua 中正确引入
local packages = require("packages")
local snowGui = packages.snowGui
```

---

## 运行时错误

### 问题: 视图不显示

**可能原因及解决方案**:

1. **视图未添加到 GUI**
```lua
-- 错误
local button = snowGui.button:new()

-- 正确
local button = snowGui.button:new()
gui:add_view(button)
```

2. **visible 属性为 false**
```lua
button.visible = true
```

3. **位置或尺寸问题**
```lua
-- 检查视图是否在屏幕内
print("Position:", button.x, button.y)
print("Size:", button.width, button.height)

-- 确保尺寸不为0
if button.width == 0 or button.height == 0 then
    button.width = 100
    button.height = 40
end
```

4. **层级问题**
```lua
-- 确保视图在正确的层级
button._layer = 1  -- 1-11, 数字越大越靠前
```

### 问题: 事件不触发

**解决方案**:

1. **确保事件回调已定义**
```lua
function button:on_click(id, x, y, dx, dy, istouch, pre)
    print("按钮被点击!")
end
```

2. **检查事件是否正确绑定到 GUI**
```lua
function love.mousepressed(x, y, button, istouch, presses)
    gui:mousepressed(button, x, y, nil, nil, istouch, presses)
end
```

3. **检查视图是否可交互**
```lua
-- 视图必须可见且有尺寸
button.visible = true
button.width > 0 and button.height > 0
```

### 问题: 内存泄漏

**症状**: 内存持续增长

**解决方案**:

1. **正确移除视图**
```lua
-- 不要只清空引用
button = nil  -- 错误

-- 使用 GUI 的移除方法
gui:remove_view(button)
```

2. **使用对象池**
```lua
local performance = snowGui.performance

-- 回收而不是销毁
performance.viewPool:recycle(view)
```

3. **定期运行 GC**
```lua
local gcTimer = 0
function love.update(dt)
    gcTimer = gcTimer + dt
    if gcTimer >= 1.0 then
        gcTimer = 0
        collectgarbage("collect")
    end
end
```

---

## 性能问题

### 问题: FPS 低

**诊断**:
```lua
local performance = snowGui.performance
local monitor = performance.monitor

function love.update(dt)
    monitor:startTimer("update")
    gui:update(dt)
    monitor:recordMetric("updateTime", monitor:endTimer("update"))
end

-- 打印性能报告
monitor:printReport()
```

**优化方案**:

1. **启用视图剔除**
```lua
local visibleViews = performance.culling.getVisibleViews(
    gui.views,
    0, 0, screenW, screenH
)
```

2. **使用空间分区**
```lua
local grid = performance.spatialGrid
grid:init(800, 600, 100)
grid:rebuild(gui.views)
```

3. **减少视图数量**
```lua
-- 使用列表虚拟化
-- 只渲染可见的列表项
```

4. **使用脏标记**
```lua
-- 避免不必要的布局计算
if not performance.dirtyFlag.isDirty(layout, "layout") then
    return
end
```

### 问题: 卡顿

**可能原因**:

1. **频繁的垃圾回收**
```lua
-- 使用对象池减少 GC
local view = performance.viewPool:get("button")
```

2. **复杂的绘制操作**
```lua
-- 简化 draw 函数
-- 避免在 draw 中进行复杂计算
```

3. **太多动画**
```lua
-- 限制同时运行的动画数量
if animation.manager:getActiveCount() < 10 then
    animation.slideTo(view, x, y)
end
```

---

## 布局问题

### 问题: 子视图位置不正确

**解决方案**:

1. **检查布局属性**
```lua
local layout = snowGui.line_layout:new({
    orientation = "vertical",  -- 或 "horizontal"
    padding = 10
})
```

2. **检查子视图的布局参数**
```lua
child.layout_weight = 1  -- 权重分配
child.layout_margin = 5  -- 外边距
```

3. **手动触发布局**
```lua
layout:layout()  -- 强制重新布局
```

### 问题: 百分比尺寸不工作

**确保**:
```lua
-- 视图已添加到 GUI
gui:add_view(view)

-- 字符串格式正确
view.width = "50%pw"  -- 父视图宽度的50%
view.height = "100%wh"  -- 窗口高度的100%
```

---

## 事件处理问题

### 问题: 点击穿透

**症状**: 点击前景视图时，后面的视图也响应

**解决方案**:
```lua
function view:on_click(...)
    -- 处理点击
    
    -- 阻止事件继续传播
    return true
end
```

### 问题: 触摸事件不工作 (Android)

**检查**:
```lua
-- 确保使用了正确的触摸事件
function love.touchpressed(id, x, y, dx, dy, pressure)
    gui:touchpressed(id, x, y, dx, dy, true, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    gui:touchmoved(id, x, y, dx, dy, true, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    gui:touchreleased(id, x, y, dx, dy, true, pressure)
end
```

---

## 动画问题

### 问题: 动画不播放

**检查清单**:

1. **动画管理器已更新**
```lua
function love.update(dt)
    snowGui.animation.manager:update(dt)
    gui:update(dt)
end
```

2. **动画已启动**
```lua
local anim = animation.manager:animate(view, "x", 100, 1.0)
-- 动画会自动播放
```

3. **属性存在且可动画**
```lua
-- 确保属性存在
view.x = 0  -- 初始值

-- 数值属性可以动画
-- 非数值属性（如字符串）不能动画
```

### 问题: 动画卡顿

**解决方案**:

1. **使用合适的缓动函数**
```lua
-- 平滑的缓动
animation.easing.cubicOut  -- 推荐
animation.easing.quadOut

-- 避免过于复杂的缓动
-- animation.easing.elasticOut  -- 可能在低端设备上卡顿
```

2. **减少动画时长**
```lua
-- 短动画更流畅
animation.slideTo(view, x, y, 0.3)  -- 而不是 2.0
```

---

## 调试技巧

### 启用详细日志

```lua
local validator = snowGui.validator

-- 启用错误日志
validator.errorLog.enabled = true

-- 记录警告
validator.warn("这是一个警告")

-- 记录错误
validator.error("这是一个错误")

-- 查看错误日志
local errors = validator.errorLog:getEntries()
for _, entry in ipairs(errors) do
    print(entry.level, entry.message)
end

-- 打印错误统计
validator.printErrorStats()
```

### 可视化调试

```lua
-- 绘制视图边界
function view:debug_draw()
    local gx, gy = self:get_global_position()
    
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("line", gx, gy, self.width, self.height)
    
    love.graphics.print(
        string.format("L:%d %s", self._layer, self.type),
        gx, gy - 15
    )
end

-- 在 draw 循环中调用
for _, view in pairs(gui.views) do
    view:debug_draw()
end
```

### 性能分析

```lua
local monitor = snowGui.performance.monitor

-- 分析特定操作
monitor:startTimer("my_operation")
-- ... 执行操作 ...
local elapsed = monitor:endTimer("my_operation")
print("操作耗时:", elapsed * 1000, "ms")

-- 获取完整报告
local report = monitor:getReport()
for key, value in pairs(report) do
    print(key, value)
end
```

### 使用调试图表

```lua
local debugGraph = snowGui.debugGraph

function love.load()
    debugGraph:load()
end

function love.update(dt)
    debugGraph:update(dt)
end

function love.draw()
    gui:draw()
    debugGraph:draw()  -- 显示 FPS 图表
end
```

### 使用自定义打印

```lua
local CustomPrint = snowGui.CustomPrint

function love.load()
    CustomPrint:load()
end

function love.update(dt)
    CustomPrint:update(dt)
    
    -- 添加调试消息
    CustomPrint:add_message("当前 FPS: " .. love.timer.getFPS())
end

function love.draw()
    gui:draw()
    CustomPrint:draw()  -- 显示消息
end
```

---

## 常见错误消息

### "attempt to index a nil value"

**可能原因**:
- 视图未初始化
- GUI 未设置
- 属性不存在

**解决**:
```lua
-- 检查 nil
if view and view.gui then
    view.gui:add_view(child)
end
```

### "bad argument #1 to 'rectangle' (number expected, got nil)"

**原因**: 绘制参数为 nil

**解决**:
```lua
-- 确保所有绘制参数有效
if self.x and self.y and self.width and self.height then
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end
```

### "stack overflow"

**原因**: 递归调用过深

**解决**:
```lua
-- 检查循环引用
-- 避免在事件回调中触发同样的事件
```

---

## 获取帮助

如果问题仍未解决:

1. **检查文档**: 
   - [API 参考](API_CN.md)
   - [架构设计](ARCHITECTURE_CN.md)
   - [性能优化指南](PERFORMANCE_CN.md)

2. **查看示例**: 
   - `experiment/test3.lua` - 综合示例
   - `experiment/test1.lua` - 基础示例

3. **提交 Issue**: 
   - 在 GitHub 仓库提交问题
   - 包含错误消息、代码片段和系统信息

4. **社区支持**: 
   - 加入 LÖVE2D 社区
   - 寻求其他开发者帮助

---

## 最佳实践

为避免常见问题，请遵循以下最佳实践:

1. **初始化检查**
```lua
assert(gui, "GUI 未初始化")
assert(view.width > 0, "视图宽度必须大于0")
```

2. **使用类型检查**
```lua
local validator = snowGui.validator

if validator.isNumber(value) then
    -- 安全使用
end
```

3. **错误恢复**
```lua
local success, error = pcall(function()
    gui:add_view(view)
end)

if not success then
    print("添加视图失败:", error)
end
```

4. **资源清理**
```lua
function love.quit()
    -- 清理资源
    gui:quit()
    collectgarbage("collect")
end
```

---

**记住**: 大多数问题都可以通过仔细阅读错误消息和检查代码逻辑来解决。保持代码简洁、注释清晰，有助于快速定位问题！
