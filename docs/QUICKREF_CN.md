# snowGui-pluss 快速参考

一页纸快速查找常用 API 和代码片段。

## 基础设置

```lua
-- 引入框架
local packages = require("packages")
local snowGui = packages.snowGui

-- 创建 GUI
local gui = snowGui:new()

-- Love2D 生命周期
function love.load()
    -- 初始化
end

function love.update(dt)
    gui:update(dt)
end

function love.draw()
    gui:draw()
end

-- 输入事件
function love.mousepressed(x, y, button, istouch, presses)
    gui:mousepressed(button, x, y, nil, nil, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    gui:mousereleased(button, x, y, nil, nil, istouch, presses)
end

function love.keypressed(key)
    gui:keypressed(key)
end

function love.textinput(text)
    gui:textinput(text)
end
```

## 常用组件

### 按钮
```lua
local button = snowGui.button:new({
    x = 100, y = 100, width = 120, height = 40,
    text = "点击我",
    backgroundColor = {0.3, 0.6, 0.9, 1}
})
function button:on_click() print("点击!") end
gui:add_view(button)
```

### 文本标签
```lua
local text = snowGui.text:new({
    x = 100, y = 100, text = "Hello",
    textSize = 16, textColor = {0, 0, 0, 1}
})
gui:add_view(text)
```

### 输入框
```lua
local input = snowGui.input_text:new({
    x = 100, y = 100, width = 200, height = 35,
    text = "输入文本"
})
gui:add_view(input)
```

### 滑块
```lua
local slider = snowGui.slider:new({
    x = 100, y = 100, width = 200, height = 30,
    min = 0, max = 100, value = 50
})
function slider:on_value_change(v) print(v) end
gui:add_view(slider)
```

### 进度条 ⭐
```lua
local progress = snowGui.progress_bar:new({
    x = 100, y = 100, width = 300, height = 30,
    value = 0, animated = true
})
progress:setValue(75)
gui:add_view(progress)
```

### 复选框 ⭐
```lua
local checkbox = snowGui.checkbox:new({
    x = 100, y = 100, label = "同意", checked = true
})
function checkbox:on_toggle(checked) print(checked) end
gui:add_view(checkbox)
```

### 单选组 ⭐
```lua
local radio = snowGui.radio_group:new({
    x = 100, y = 100,
    options = {"选项1", "选项2", "选项3"},
    orientation = "vertical"
})
function radio:on_selection_change(value) print(value) end
gui:add_view(radio)
```

## 布局

### 线性布局
```lua
local layout = snowGui.line_layout:new({
    x = 50, y = 50, width = 300, height = 200,
    orientation = "vertical",  -- 或 "horizontal"
    padding = 10
})
layout:add_view(child1)
layout:add_view(child2)
gui:add_view(layout)
```

### 网格布局
```lua
local grid = snowGui.grid_layout:new({
    x = 50, y = 50, width = 300, height = 200,
    cols = 3, rows = 2
})
gui:add_view(grid)
```

### 帧布局
```lua
local frame = snowGui.frame_layout:new({
    x = 0, y = 0, width = 800, height = 600
})
gui:add_view(frame)
```

## 容器

### 窗口
```lua
local window = snowGui.window:new({
    x = 100, y = 100, width = 400, height = 300,
    text = "窗口标题"
})
gui:add_view(window)
```

### 标签页
```lua
local tabs = snowGui.tab_control:new({
    x = 10, y = 10, width = 600, height = 400
})
tabs:add_tab("标签1", content1)
tabs:add_tab("标签2", content2)
gui:add_view(tabs)
```

### 可折叠面板
```lua
local fold = snowGui.fold_container:new({
    x = 10, y = 10, width = 300, height = 200,
    text = "点击展开"
})
gui:add_view(fold)
```

### 上下文菜单 ⭐
```lua
local menu = snowGui.context_menu:new({
    items = {
        {label = "复制", action = function() end},
        {separator = true},
        {label = "粘贴", action = function() end}
    }
})
menu:show(x, y)
gui:add_view(menu)
```

## 动画 ⭐

```lua
local animation = snowGui.animation

-- 更新动画（在 love.update 中）
function love.update(dt)
    animation.manager:update(dt)
end

-- 滑动
animation.slideTo(view, 300, 200, 0.5, animation.easing.cubicOut)

-- 淡入淡出
animation.fadeIn(view, 0.3)
animation.fadeOut(view, 0.3)

-- 缩放
animation.scaleTo(view, 200, 150, 0.5)

-- 脉冲
animation.pulse(view, 1.2, 0.6)

-- 自定义动画
animation.manager:animate(
    view,      -- 目标
    "x",       -- 属性
    500,       -- 目标值
    1.0,       -- 持续时间
    animation.easing.cubicOut,  -- 缓动
    function() print("完成") end -- 回调
)
```

## 通知 ⭐

```lua
local toast = snowGui.toast_manager

-- 初始化
toast:init(gui)

-- 更新和绘制
function love.update(dt)
    toast:update(dt)
end

function love.draw()
    gui:draw()
    toast:draw()
end

-- 显示通知
toast:info("提示信息")
toast:success("成功!")
toast:warning("警告")
toast:error("错误!")

-- 自定义
toast:show("自定义消息", 3, "info")

-- 设置位置
toast:setPosition("top")  -- top, bottom, center, etc.
```

## 性能优化 ⭐

```lua
local performance = snowGui.performance

-- 对象池
local view = performance.viewPool:get("button")
if not view then view = snowGui.button:new() end
performance.viewPool:recycle(view)

-- 脏标记
performance.dirtyFlag.markDirty(view, "layout")
if performance.dirtyFlag.isDirty(view, "layout") then
    -- 重新布局
    performance.dirtyFlag.clearDirty(view, "layout")
end

-- 空间分区
local grid = performance.spatialGrid
grid:init(800, 600, 100)
grid:rebuild(gui.views)
local candidates = grid:query(mouseX, mouseY)

-- 视图剔除
local visible = performance.culling.getVisibleViews(
    gui.views, 0, 0, screenW, screenH
)

-- 性能监控
local monitor = performance.monitor
monitor:startTimer("update")
-- ... 操作 ...
monitor:recordMetric("updateTime", monitor:endTimer("update"))
monitor:printReport()
```

## 验证 ⭐

```lua
local validator = snowGui.validator

-- 类型检查
validator.isNumber(value)
validator.isString(value)
validator.isColor(color)

-- 范围检查
validator.inRange(value, 0, 100)
validator.isPositive(value)

-- 断言
validator.assert(condition, "错误消息")
validator.assertType(value, "number", "参数名")
validator.assertRange(value, 0, 100, "参数名")

-- 错误日志
validator.warn("警告")
validator.error("错误")
validator.printErrorStats()
```

## 事件系统

```lua
local events = gui.events_system

-- 订阅事件
events:subscribe("custom_event", function(data)
    print("收到:", data)
end)

-- 发布事件
events:publish("custom_event", {value = 123})

-- 取消订阅
events:unsubscribe("custom_event", callback)
```

## 颜色

```lua
local Color = snowGui.Color

-- HEX 转 RGBA
local rgba = Color.HEX_To_RGBA("#FF5733")

-- RGBA 转 HEX
local hex = Color.RGBA_To_HEX({1, 0.34, 0.2, 1})

-- 预定义颜色
Color.red   -- {1, 0, 0, 1}
Color.green -- {0, 1, 0, 1}
Color.blue  -- {0, 0, 1, 1}
Color.white -- {1, 1, 1, 1}
Color.black -- {0, 0, 0, 1}
```

## 调试

```lua
-- 调试图表
local debugGraph = snowGui.debugGraph
debugGraph:load()
function love.update(dt) debugGraph:update(dt) end
function love.draw() debugGraph:draw() end

-- 自定义打印
local CustomPrint = snowGui.CustomPrint
CustomPrint:load()
CustomPrint:add_message("调试信息")
function love.update(dt) CustomPrint:update(dt) end
function love.draw() CustomPrint:draw() end
```

## 常用属性

### 位置和尺寸
```lua
view.x = 100
view.y = 100
view.width = 200
view.height = 100
```

### 颜色
```lua
view.backgroundColor = {0.6, 0.6, 1, 1}
view.borderColor = {0, 0, 0, 1}
view.textColor = {0, 0, 0, 1}
view.hoverColor = {0.8, 0.8, 1, 1}
view.pressedColor = {0.6, 0.6, 1, 0.8}
```

### 状态
```lua
view.visible = true
view.isHover = false
view.isPressed = false
view.isDragging = false
```

### 文本
```lua
view.text = "文本"
view.textSize = 14
view.font = "default"
```

### 布局
```lua
child.layout_weight = 1
child.layout_margin = 5
child.layout_margin_top = 5
child.layout_margin_bottom = 5
child.layout_margin_left = 5
child.layout_margin_right = 5
```

## 百分比尺寸

```lua
view.width = "50%pw"   -- 父视图宽度的50%
view.height = "100%ph" -- 父视图高度的100%
view.width = "30%ww"   -- 窗口宽度的30%
view.height = "80%wh"  -- 窗口高度的80%
view.width = "fill"    -- 填充父视图
```

## 快捷键参考

| 功能 | 代码 |
|------|------|
| 创建视图 | `snowGui.TYPE:new({})` |
| 添加到GUI | `gui:add_view(view)` |
| 移除视图 | `gui:remove_view(view)` |
| 点击事件 | `function view:on_click() end` |
| 值改变 | `function view:on_value_change(v) end` |
| 添加子视图 | `parent:add_view(child)` |
| 获取位置 | `view:get_global_position()` |
| 设置位置 | `view:setPosition(x, y)` |
| 设置尺寸 | `view:set_wh(w, h)` |

---

**提示**: 
- 所有新功能标记为 ⭐
- 完整文档见 [docs/](../docs/)
- 示例代码见 [experiment/](../experiment/)

**性能建议**:
- 使用对象池复用视图
- 启用脏标记避免重复布局
- 使用空间分区优化碰撞
- 监控 FPS 和内存使用

**常见问题**: 见 [TROUBLESHOOTING_CN.md](TROUBLESHOOTING_CN.md)
