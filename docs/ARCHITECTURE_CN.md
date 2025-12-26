# snowGui-pluss 架构设计文档

本文档详细介绍 snowGui-pluss 框架的架构设计和实现原理。

## 目录

- [整体架构](#整体架构)
- [核心模块](#核心模块)
- [设计模式](#设计模式)
- [事件流程](#事件流程)
- [渲染流程](#渲染流程)
- [内存管理](#内存管理)
- [扩展开发](#扩展开发)

---

## 整体架构

snowGui-pluss 采用分层架构设计：

```
┌─────────────────────────────────────┐
│      应用层 (Application)            │
│   (用户代码 main.lua)                │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│      GUI 管理器层                    │
│   (gui.lua - 核心管理器)             │
│   - 视图管理                         │
│   - 事件分发                         │
│   - 渲染调度                         │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│      组件层 (Components)             │
├─────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌──────┐│
│  │ Views   │  │Containers│ │Layouts││
│  │视图组件 │  │容器组件   │ │布局  ││
│  └─────────┘  └─────────┘  └──────┘│
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│      基础层 (Foundation)             │
├─────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌──────┐│
│  │ View    │  │ Events  │  │ Utils││
│  │基础视图 │  │事件系统  │ │工具库││
│  └─────────┘  └─────────┘  └──────┘│
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│      LÖVE2D 引擎层                   │
│   (Love2D API)                      │
└─────────────────────────────────────┘
```

---

## 核心模块

### 1. GUI 管理器 (gui.lua)

GUI 管理器是框架的中枢，负责：

**核心职责:**
- **视图生命周期管理**: 创建、添加、移除、销毁视图
- **事件分发**: 将用户输入分发到正确的视图
- **渲染调度**: 按层级顺序渲染所有视图
- **状态管理**: 维护焦点、按压、悬停等全局状态

**关键数据结构:**

```lua
gui = {
    -- 位置和尺寸
    x, y, width, height,
    scale_x, scale_y,           -- 缩放因子
    
    -- 视图管理
    views = {},                  -- 弱引用表，所有视图
    tree_views = {},             -- 按层级组织的视图树 [1-11]
    id_views = {},               -- ID索引的视图映射
    
    -- 输入状态
    input_state = {
        layer = nil,             -- 当前焦点层级
        isPressed = false,       -- 是否有按压
        pressed_views = {},      -- 被按压的视图集合
        isMoved = false,         -- 是否有移动
        hover_view = nil,        -- 悬停视图
        keypressed_view = nil    -- 键盘焦点视图
    },
    
    -- 裁剪管理
    scissors = {},               -- 裁剪栈
    
    -- 外部系统
    events_system,               -- 事件系统实例
    font_manger                  -- 字体管理器
}
```

**核心方法:**

```lua
-- 视图管理
gui:add_view(view)           -- 添加视图
gui:remove_view(view)        -- 移除视图
gui:load_layout(table)       -- 从表加载布局

-- 生命周期
gui:update(dt)               -- 更新循环
gui:draw()                   -- 渲染循环
gui:resize(w, h)             -- 窗口大小变化

-- 事件处理
gui:mousepressed(...)        -- 鼠标按下
gui:mousereleased(...)       -- 鼠标释放
gui:mousemoved(...)          -- 鼠标移动
gui:keypressed(key)          -- 键盘按下
gui:textinput(text)          -- 文本输入
```

---

### 2. 视图基类 (view.lua)

所有UI组件的基类，提供通用功能：

**继承体系:**

```
view (基类)
├── button (按钮)
├── text (文本)
├── input_text (输入框)
├── slider (滑块)
├── line_layout (线性布局)
│   └── (其他布局)
└── window (窗口)
    └── (其他容器)
```

**关键机制:**

1. **原型继承**:
```lua
function view:new(options)
    local new_obj = {}
    -- 复制独立属性
    for k, v in pairs(options or {}) do
        new_obj[k] = v
    end
    setmetatable(new_obj, self)
    new_obj:_init()
    return new_obj
end
```

2. **父子关系**:
```lua
view.parent = nil        -- 父视图
view.children = {}       -- 子视图列表

function view:add_view(child)
    child.parent = self
    table.insert(self.children, child)
    -- 同步到 GUI 管理器
    if self.gui then
        child.gui = self.gui
        self.gui:_register_view(child)
    end
end
```

3. **坐标系统**:
```lua
-- 获取全局坐标
function view:get_global_position()
    local x, y = self.x, self.y
    local parent = self.parent
    while parent do
        x = x + parent.x
        y = y + parent.y
        parent = parent.parent
    end
    return x, y
end

-- 获取局部坐标
function view:get_local_position(global_x, global_y)
    local gx, gy = self:get_global_position()
    return global_x - gx, global_y - gy
end
```

---

### 3. 事件系统 (events_system.lua)

基于观察者模式的事件系统：

**结构:**

```lua
events_system = {
    subscribers = {}  -- { event_name = { callback1, callback2, ... } }
}
```

**实现:**

```lua
-- 订阅事件
function events_system:subscribe(event_name, callback)
    if not self.subscribers[event_name] then
        self.subscribers[event_name] = {}
    end
    table.insert(self.subscribers[event_name], callback)
end

-- 发布事件
function events_system:publish(event_name, data)
    local subscribers = self.subscribers[event_name]
    if subscribers then
        for _, callback in ipairs(subscribers) do
            callback(data)
        end
    end
end

-- 取消订阅
function events_system:unsubscribe(event_name, callback)
    local subscribers = self.subscribers[event_name]
    if subscribers then
        for i, cb in ipairs(subscribers) do
            if cb == callback then
                table.remove(subscribers, i)
                break
            end
        end
    end
end
```

---

### 4. 布局系统

布局系统负责自动计算子视图的位置和尺寸。

**核心布局: LineLayout**

```lua
line_layout = {
    orientation = "vertical",  -- 方向
    gravity = "top|left",      -- 对齐
    padding = 0,               -- 内边距
    padding_top, padding_right, padding_left, padding_bottom
}
```

**布局算法 (垂直方向):**

```lua
function line_layout:layout()
    local available_height = self.height - self.padding_top - self.padding_bottom
    local total_weight = 0
    local fixed_height = 0
    
    -- 第一遍：计算固定高度和总权重
    for _, child in ipairs(self.children) do
        if child.layout_weight > 0 then
            total_weight = total_weight + child.layout_weight
        else
            fixed_height = fixed_height + child.height
            fixed_height = fixed_height + (child.layout_margin_top or 0)
            fixed_height = fixed_height + (child.layout_margin_bottom or 0)
        end
    end
    
    -- 计算剩余空间
    local remaining = available_height - fixed_height
    
    -- 第二遍：分配位置和尺寸
    local current_y = self.padding_top
    for _, child in ipairs(self.children) do
        child.y = current_y + (child.layout_margin_top or 0)
        
        if child.layout_weight > 0 then
            -- 按权重分配
            child.height = (remaining / total_weight) * child.layout_weight
            child.height = child.height - (child.layout_margin_top or 0)
            child.height = child.height - (child.layout_margin_bottom or 0)
        end
        
        current_y = current_y + child.height
        current_y = current_y + (child.layout_margin_top or 0)
        current_y = current_y + (child.layout_margin_bottom or 0)
        
        -- 递归布局子视图
        if child.layout then
            child:layout()
        end
    end
end
```

---

## 设计模式

### 1. 单例模式

字体管理器使用单例模式：

```lua
local font_manger = {
    fonts = {},  -- 缓存已加载字体
    default_font = nil
}

-- 获取字体（自动缓存）
function font_manger:get_font(name, size)
    local key = name .. "_" .. size
    if not self.fonts[key] then
        self.fonts[key] = love.graphics.newFont(name, size)
    end
    return self.fonts[key]
end
```

### 2. 工厂模式

视图加载器使用工厂模式：

```lua
function gui:load_layout(table)
    local type = table.type
    local ViewClass = lumenGui[type]  -- 从 API 获取类
    
    if not ViewClass then
        error("未知视图类型: " .. type)
    end
    
    -- 创建视图
    local view = ViewClass:new(table)
    
    -- 递归创建子视图
    for i, child_table in ipairs(table) do
        if type(child_table) == "table" and child_table.type then
            local child = self:load_layout(child_table)
            view:add_view(child)
        end
    end
    
    return view
end
```

### 3. 观察者模式

事件系统基于观察者模式（见上文）。

### 4. 组合模式

视图树结构使用组合模式：

```lua
-- 统一接口
view:add_view(child)
view:remove_view(child)
view:update(dt)
view:draw()

-- 递归处理
function view:update(dt)
    -- 更新自身
    self:on_update(dt)
    
    -- 更新所有子视图
    for _, child in ipairs(self.children) do
        child:update(dt)
    end
end
```

---

## 事件流程

### 鼠标点击事件流程

```
1. Love2D 触发 love.mousepressed(x, y, button)
   │
2. 调用 gui:mousepressed(button, x, y, ...)
   │
3. GUI 管理器处理
   ├─ 从最高层级开始遍历 (layer 11 → 1)
   ├─ 在每层中按绘制顺序倒序查找
   └─ 调用 view:is_point_inside(x, y)
   │
4. 找到目标视图
   ├─ 设置 view.isPressed = true
   ├─ 记录到 gui.input_state.pressed_views
   └─ 调用 view:on_pressed(...)
   │
5. Love2D 触发 love.mousereleased(x, y, button)
   │
6. 调用 gui:mousereleased(button, x, y, ...)
   │
7. GUI 管理器处理
   ├─ 检查 pressed_views 中的视图
   ├─ 判断释放点是否仍在视图内
   ├─ 设置 view.isPressed = false
   ├─ 调用 view:on_released(...)
   └─ 如果仍在视图内，调用 view:on_click(...)
```

### 键盘输入事件流程

```
1. Love2D 触发 love.keypressed(key) 或 love.textinput(text)
   │
2. 调用 gui:keypressed(key) 或 gui:textinput(text)
   │
3. GUI 管理器检查 input_state.keypressed_view
   │
4. 如果存在焦点视图
   ├─ 调用 view:on_keypressed(key)
   └─ 或 view:on_textinput(text)
   │
5. 如果不存在焦点视图
   └─ 忽略或全局处理
```

---

## 渲染流程

### 渲染顺序

```
1. love.draw() 被调用
   │
2. gui:draw()
   ├─ 清空屏幕 (可选)
   ├─ 按层级顺序渲染 (layer 1 → 11)
   │  │
   │  └─ 在每层中按 _draw_order 排序
   │     │
   │     └─ 调用 view:draw()
   │        ├─ 应用裁剪 (scissors)
   │        ├─ 绘制自身
   │        ├─ 递归绘制子视图
   │        └─ 恢复裁剪
   │
   └─ 绘制调试信息 (可选)
```

### 裁剪栈管理

```lua
function gui:push_scissor(x, y, w, h)
    -- 保存当前裁剪
    table.insert(self.scissors, {love.graphics.getScissor()})
    
    -- 应用新裁剪（与父裁剪相交）
    if #self.scissors > 1 then
        local px, py, pw, ph = unpack(self.scissors[#self.scissors - 1])
        -- 计算交集
        x, y, w, h = intersect_rect(x, y, w, h, px, py, pw, ph)
    end
    
    love.graphics.setScissor(x, y, w, h)
end

function gui:pop_scissor()
    table.remove(self.scissors)
    if #self.scissors > 0 then
        love.graphics.setScissor(unpack(self.scissors[#self.scissors]))
    else
        love.graphics.setScissor()
    end
end
```

---

## 内存管理

### 弱引用表

GUI 使用弱引用表存储视图，允许垃圾回收：

```lua
gui.views = setmetatable({}, { __mode = 'kv' })
```

这意味着如果视图没有其他强引用，会被自动回收。

### 视图销毁

```lua
function view:destroy()
    -- 从父视图移除
    if self.parent then
        self.parent:remove_view(self)
    end
    
    -- 从 GUI 移除
    if self.gui then
        self.gui:remove_view(self)
    end
    
    -- 递归销毁子视图
    for _, child in ipairs(self.children) do
        child:destroy()
    end
    
    -- 清空子视图列表
    self.children = {}
    
    -- 取消事件订阅
    if self.events_system then
        -- 清理订阅
    end
end
```

### 最佳实践

1. **不再需要的视图调用 destroy()**
2. **避免循环引用**
3. **大型列表使用虚拟滚动**
4. **及时取消事件订阅**

---

## 扩展开发

### 创建自定义视图

```lua
-- 1. 继承基类
local MyView = snowGui.view:new()
MyView.__index = MyView

-- 2. 实现构造函数
function MyView:new(options)
    -- 调用父类构造
    local obj = snowGui.view.new(self, options)
    
    -- 设置类型
    obj.type = "my_view"
    
    -- 初始化自定义属性
    obj.custom_prop = options.custom_prop or "default"
    
    return obj
end

-- 3. 重写方法
function MyView:draw()
    if not self.visible then return end
    
    -- 自定义绘制逻辑
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- 绘制子视图
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

function MyView:update(dt)
    -- 自定义更新逻辑
    
    -- 调用父类更新
    snowGui.view.update(self, dt)
end

-- 4. 添加到 API (如果需要解析式支持)
-- 在 API.lua 中添加:
-- my_view = MyView
```

### 创建自定义布局

```lua
local MyLayout = snowGui.view:new()
MyLayout.__index = MyLayout

function MyLayout:new(options)
    local obj = snowGui.view.new(self, options)
    obj.type = "my_layout"
    return obj
end

-- 实现布局算法
function MyLayout:layout()
    -- 计算子视图位置和尺寸
    for i, child in ipairs(self.children) do
        -- 自定义布局逻辑
        child.x = ...
        child.y = ...
        child.width = ...
        child.height = ...
        
        -- 递归布局
        if child.layout then
            child:layout()
        end
    end
end

-- 在更新时触发布局
function MyLayout:update(dt)
    self:layout()
    snowGui.view.update(self, dt)
end
```

### 插件系统

可以通过修改 API.lua 添加插件：

```lua
-- plugins/my_plugin.lua
local MyPlugin = {}

function MyPlugin:init(gui)
    -- 初始化插件
    self.gui = gui
end

function MyPlugin:update(dt)
    -- 插件更新
end

return MyPlugin

-- 在应用中使用
local MyPlugin = require("plugins.my_plugin")
local plugin = MyPlugin:init(gui)
```

---

## 性能优化建议

### 1. 视图池复用

```lua
local viewPool = {}

function getView(type)
    if #viewPool[type] > 0 then
        return table.remove(viewPool[type])
    else
        return snowGui[type]:new()
    end
end

function recycleView(view)
    view.visible = false
    table.insert(viewPool[view.type], view)
end
```

### 2. 脏标记机制

```lua
view.dirty = true  -- 标记需要重新布局

function view:set_width(w)
    if self.width ~= w then
        self.width = w
        self:mark_dirty()
    end
end

function view:mark_dirty()
    self.dirty = true
    if self.parent then
        self.parent:mark_dirty()
    end
end

function view:layout()
    if not self.dirty then return end
    
    -- 执行布局
    -- ...
    
    self.dirty = false
end
```

### 3. 批量绘制

```lua
-- 收集相同材质的视图一起绘制
function gui:draw_batched()
    local batches = {}  -- { material = {view1, view2, ...} }
    
    -- 收集
    for _, view in ipairs(self.views) do
        local key = view.material or "default"
        batches[key] = batches[key] or {}
        table.insert(batches[key], view)
    end
    
    -- 批量绘制
    for material, views in pairs(batches) do
        -- 设置材质
        for _, view in ipairs(views) do
            view:draw_simple()
        end
    end
end
```

---

## 调试技巧

### 1. 可视化调试

```lua
function view:debug_draw()
    -- 绘制边界框
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    
    -- 绘制层级信息
    love.graphics.print(
        string.format("L:%d O:%d", self._layer, self._draw_order),
        self.x, self.y - 15
    )
end
```

### 2. 性能分析

```lua
function gui:profile_update(dt)
    local start = love.timer.getTime()
    self:update(dt)
    local elapsed = love.timer.getTime() - start
    print(string.format("Update: %.2fms", elapsed * 1000))
end
```

---

## 总结

snowGui-pluss 采用清晰的分层架构和经典设计模式，提供了：

- **灵活的组件系统**: 易于扩展和定制
- **强大的布局引擎**: 自动计算视图位置
- **高效的事件处理**: 精确的事件分发
- **良好的性能**: 合理的内存管理和渲染优化

通过理解这些核心概念，您可以更有效地使用框架，并根据需求进行扩展开发。

---

**参考文档:**
- [API 参考](API_CN.md)
- [使用示例](EXAMPLES_CN.md)
- [主文档](../README_CN.md)
