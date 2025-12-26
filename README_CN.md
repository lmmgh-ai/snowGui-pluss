# snowGui-pluss 中文技术文档

> 用于纪念2025年即将到来和终将逝去的冬天

## 项目简介

snowGui-pluss 是一个基于 LÖVE2D (Love2D) 游戏引擎开发的跨平台 GUI 框架。该框架提供了丰富的UI组件和灵活的布局系统，支持 Windows 和 Android 平台。

**框架原名**: lumenGui (简称 lmGui)  
**作者**: 北极企鹅  
**时间**: 2025

## 主要特性

- 🎨 **丰富的UI组件**: 按钮、文本框、滑块、列表、图片等常用控件
- 📐 **灵活的布局系统**: 线性布局、网格布局、重力布局、帧布局
- 🎯 **容器组件**: 窗口、对话框、标签页、可折叠面板等高级容器
- 📱 **跨平台支持**: 支持Windows桌面和Android移动平台
- 🎮 **事件系统**: 完善的事件订阅发布机制
- 🖱️ **触摸与鼠标**: 统一的触摸和鼠标输入处理
- 🎨 **主题定制**: 支持颜色、字体等样式自定义
- 📝 **中文支持**: 内置中文字体支持

## 系统要求

- **LÖVE2D 版本**: 11.4+
- **支持平台**: Windows, Android
- **Lua 版本**: 5.1+

## 快速开始

### 安装

1. 安装 LÖVE2D 11.4 或更高版本
2. 克隆本仓库：
```bash
git clone https://github.com/lmmgh-ai/snowGui-pluss.git
cd snowGui-pluss
```

3. 运行示例：
```bash
love .
```

### 基础示例

```lua
-- 引入框架
local packages = require("packages")
local snowGui = packages.snowGui

-- 创建GUI管理器
local gui = snowGui:new()

-- Love2D 生命周期函数
function love.load()
    -- 创建一个按钮
    local button = snowGui.button:new({
        x = 100,
        y = 100,
        width = 120,
        height = 40,
        text = "点击我"
    })
    
    -- 添加按钮点击事件
    function button:on_click(id, x, y, dx, dy, istouch, pre)
        print("按钮被点击了!")
    end
    
    -- 将按钮添加到GUI
    gui:add_view(button)
end

function love.update(dt)
    gui:update(dt)
end

function love.draw()
    love.graphics.clear(1, 1, 1) -- 白色背景
    gui:draw()
end

-- 鼠标事件绑定
function love.mousepressed(x, y, button, istouch, presses)
    gui:mousepressed(button, x, y, nil, nil, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    gui:mousereleased(button, x, y, nil, nil, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
    gui:mousemoved(nil, x, y, dx, dy, istouch, nil)
end

-- 键盘事件
function love.keypressed(key)
    gui:keypressed(key)
end

function love.textinput(text)
    gui:textinput(text)
end
```

## 核心概念

### 1. GUI 管理器

GUI 管理器是框架的核心，负责管理所有视图的生命周期、事件分发和渲染。

```lua
local gui = snowGui:new({
    x = 0,
    y = 0,
    width = 800,
    height = 600
})
```

### 2. 视图 (View)

所有UI组件的基类，提供基础属性和方法：

- **位置和尺寸**: `x`, `y`, `width`, `height`
- **可见性**: `visible`
- **状态**: `isHover`, `isPressed`, `isDragging`
- **样式**: `backgroundColor`, `borderColor`, `textColor`
- **层级**: `_layer`, `_draw_order`

### 3. 视图添加方式

#### 方式一：解析式（声明式）

```lua
local layout = {
    type = "line_layout",
    x = 50,
    y = 50,
    {
        type = "button",
        text = "按钮1"
    },
    {
        type = "text",
        text = "文本标签"
    }
}
gui:add_view(gui:load_layout(layout))
```

#### 方式二：面向对象式

```lua
local layout = snowGui.line_layout:new({ 
    x = 50, 
    y = 50 
})

local button = snowGui.button:new({
    text = "按钮1"
})

layout:add_view(button)
gui:add_view(layout)
```

## 核心组件

### 视图组件 (Views)

| 组件 | 说明 | 主要用途 |
|------|------|----------|
| `view` | 基础视图类 | 所有组件的基类 |
| `button` | 按钮 | 可点击的交互按钮 |
| `text` | 文本标签 | 显示静态文本 |
| `edit_text` | 可编辑文本 | 多行文本编辑器 |
| `input_text` | 输入框 | 单行文本输入 |
| `slider` | 滑块 | 数值选择器 |
| `switch_button` | 开关按钮 | 布尔值切换 |
| `select_button` | 选择按钮 | 单选/多选按钮 |
| `select_menu` | 下拉菜单 | 选项选择器 |
| `list` | 列表 | 可滚动列表容器 |
| `image` | 图片 | 图片显示组件 |

### 布局系统 (Layouts)

| 布局 | 说明 | 特点 |
|------|------|------|
| `line_layout` | 线性布局 | 垂直或水平排列子视图 |
| `grid_layout` | 网格布局 | 行列网格排列 |
| `gravity_layout` | 重力布局 | 子视图按重力方向对齐 |
| `frame_layout` | 帧布局 | 层叠式布局 |

### 容器组件 (Containers)

| 容器 | 说明 | 用途 |
|------|------|------|
| `window` | 窗口 | 可拖动的窗口容器 |
| `dialog` | 对话框 | 模态对话框 |
| `tab_control` | 标签页控制器 | 多标签页切换 |
| `border_container` | 边框容器 | 带边框的容器 |
| `fold_container` | 折叠容器 | 可折叠/展开的面板 |
| `slider_container` | 滑动容器 | 可滚动内容容器 |
| `title_menu` | 标题菜单 | 带标题的菜单容器 |
| `tree_manager` | 树形管理器 | 树形结构视图 |

### 工具库 (Libs)

- **Color**: 颜色处理工具
- **Camera**: 2D相机系统
- **events_system**: 事件订阅发布系统
- **font_manger**: 字体管理器（单例模式）
- **CustomPrint**: 自定义打印输出
- **debugGraph**: 性能调试图表
- **nativefs**: 原生文件系统访问
- **fun**: 函数式编程工具库

## 布局属性

### 线性布局 (line_layout) 属性

```lua
local layout = snowGui.line_layout:new({
    orientation = "vertical",  -- 方向: "vertical" 或 "horizontal"
    gravity = "top|left",      -- 重力: "top", "bottom", "left", "right", "center"
    padding = 10,              -- 内边距（统一）
    padding_top = 10,          -- 顶部内边距
    padding_right = 10,        -- 右侧内边距
    padding_left = 10,         -- 左侧内边距
    padding_bottom = 10        -- 底部内边距
})
```

### 子视图布局属性

```lua
local child = snowGui.button:new({
    layout_weight = 1,         -- 权重（小于0自适应，0按自身比例，大于0按权重分配）
    layout_margin = 5,         -- 外边距（统一）
    layout_margin_top = 5,     -- 顶部外边距
    layout_margin_right = 5,   -- 右侧外边距
    layout_margin_left = 5,    -- 左侧外边距
    layout_margin_bottom = 5   -- 底部外边距
})
```

## 事件系统

### 内置事件

每个视图组件都支持以下事件回调：

```lua
function view:on_click(id, x, y, dx, dy, istouch, pre)
    -- 点击事件
end

function view:on_pressed(id, x, y, dx, dy, istouch, pre)
    -- 按下事件
end

function view:on_released(id, x, y, dx, dy, istouch, pre)
    -- 释放事件
end

function view:on_hover(x, y)
    -- 悬停事件
end

function view:on_drag(id, x, y, dx, dy)
    -- 拖动事件
end
```

### 自定义事件

使用事件系统进行组件间通信：

```lua
-- 订阅事件
gui.events_system:subscribe("custom_event", function(data)
    print("收到事件:", data)
end)

-- 发布事件
gui.events_system:publish("custom_event", { message = "Hello" })
```

## 配置文件

项目通过 `conf.lua` 配置 LÖVE2D 窗口和模块：

```lua
function love.conf(t)
    t.window.title = 'snowGui-pluss'
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = true
    t.version = '11.4'
    -- 更多配置选项...
end
```

## 示例项目

查看 `experiment/` 目录下的示例：

- `test.lua` - 基础框架演示
- `test1.lua` - 视图添加演示（解析式和面向对象两种方式）
- `test2.lua` - 视图编辑器
- `test99.lua` - 临时测试文件

运行示例前，在 `main.lua` 中取消对应文件的注释。

## 进阶文档

- [API 详细参考](docs/API_CN.md) - 完整的API文档
- [使用示例](docs/EXAMPLES_CN.md) - 更多实用示例
- [架构设计](docs/ARCHITECTURE_CN.md) - 框架架构说明

## 调试工具

框架内置了多个调试工具：

```lua
local debugGraph = snowGui.debugGraph  -- 性能图表
local CustomPrint = snowGui.CustomPrint  -- 自定义打印

function love.load()
    debugGraph:load()
    CustomPrint:load()
end

function love.update(dt)
    debugGraph:update(dt)
    CustomPrint:update(dt)
end

function love.draw()
    debugGraph:draw()
    CustomPrint:draw()
end
```

## 平台特定代码

### Android 触摸事件

```lua
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

### Windows 鼠标事件

```lua
function love.mousepressed(x, y, button, istouch, presses)
    gui:mousepressed(button, x, y, nil, nil, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    gui:mousereleased(button, x, y, nil, nil, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
    gui:mousemoved(nil, x, y, dx, dy, istouch, nil)
end

function love.wheelmoved(x, y)
    gui:wheelmoved(nil, x, y)
end
```

## 常见问题

### 1. 如何修改字体？

```lua
-- 使用内置中文字体
local text = snowGui.text:new({
    font = ChineseFont,  -- 全局变量，指向中文字体文件
    textSize = 16
})

-- 或使用自定义字体
local text = snowGui.text:new({
    font = "path/to/your/font.ttf",
    textSize = 16
})
```

### 2. 如何创建自定义视图？

```lua
local custom_view = snowGui.view:new()

function custom_view:new(tab)
    local new_obj = snowGui.view.new(self, tab)
    new_obj.type = "custom_view"
    return new_obj
end

function custom_view:draw()
    -- 自定义绘制逻辑
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end
```

### 3. 如何实现视图间通信？

使用事件系统：

```lua
-- 在视图A中发布事件
viewA.events_system:publish("data_changed", { value = 100 })

-- 在视图B中订阅事件
viewB.events_system:subscribe("data_changed", function(data)
    print("接收到新数据:", data.value)
end)
```

## 贡献指南

欢迎提交问题和拉取请求！

## 许可证

请查看仓库中的 LICENSE 文件（如果有）。

## 联系方式

- **作者**: 北极企鹅
- **项目仓库**: https://github.com/lmmgh-ai/snowGui-pluss

---

**祝您使用愉快！** ❄️
