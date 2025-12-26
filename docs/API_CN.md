# snowGui-pluss API 参考文档

本文档提供 snowGui-pluss 框架的完整 API 参考。

## 目录

- [GUI 管理器](#gui-管理器)
- [基础视图 (View)](#基础视图-view)
- [视图组件](#视图组件)
  - [Button 按钮](#button-按钮)
  - [Text 文本](#text-文本)
  - [EditText 可编辑文本](#edittext-可编辑文本)
  - [InputText 输入框](#inputtext-输入框)
  - [Slider 滑块](#slider-滑块)
  - [SwitchButton 开关按钮](#switchbutton-开关按钮)
  - [SelectButton 选择按钮](#selectbutton-选择按钮)
  - [SelectMenu 下拉菜单](#selectmenu-下拉菜单)
  - [List 列表](#list-列表)
  - [Image 图片](#image-图片)
- [布局系统](#布局系统)
  - [LineLayout 线性布局](#linelayout-线性布局)
  - [GridLayout 网格布局](#gridlayout-网格布局)
  - [GravityLayout 重力布局](#gravitylayout-重力布局)
  - [FrameLayout 帧布局](#framelayout-帧布局)
- [容器组件](#容器组件)
  - [Window 窗口](#window-窗口)
  - [Dialog 对话框](#dialog-对话框)
  - [TabControl 标签页](#tabcontrol-标签页)
  - [BorderContainer 边框容器](#bordercontainer-边框容器)
  - [FoldContainer 折叠容器](#foldcontainer-折叠容器)
  - [SliderContainer 滑动容器](#slidercontainer-滑动容器)
  - [TitleMenu 标题菜单](#titlemenu-标题菜单)
  - [TreeManager 树形管理器](#treemanager-树形管理器)
- [工具库](#工具库)
  - [Color 颜色工具](#color-颜色工具)
  - [Camera 相机](#camera-相机)
  - [EventsSystem 事件系统](#eventssystem-事件系统)
  - [FontManager 字体管理器](#fontmanager-字体管理器)

---

## GUI 管理器

GUI 管理器是框架的核心，负责管理所有视图组件。

### 构造函数

```lua
snowGui:new(options)
```

**参数:**
- `options` (table, 可选): 配置选项
  - `x` (number): X坐标，默认 0
  - `y` (number): Y坐标，默认 0
  - `width` (number): 宽度，默认窗口宽度
  - `height` (number): 高度，默认窗口高度
  - `scale_x` (number): X轴缩放，默认 1
  - `scale_y` (number): Y轴缩放，默认 1

**返回值:** GUI 实例

**示例:**
```lua
local gui = snowGui:new({
    width = 800,
    height = 600
})
```

### 方法

#### add_view(view)

添加视图到 GUI。

```lua
gui:add_view(view)
```

**参数:**
- `view` (View): 要添加的视图实例

**示例:**
```lua
local button = snowGui.button:new()
gui:add_view(button)
```

#### remove_view(view)

从 GUI 移除视图。

```lua
gui:remove_view(view)
```

#### load_layout(table)

从表格式配置加载布局。

```lua
gui:load_layout(layout_table)
```

**参数:**
- `layout_table` (table): 布局配置表

**返回值:** 创建的视图实例

**示例:**
```lua
local layout = {
    type = "line_layout",
    x = 10,
    y = 10,
    {
        type = "button",
        text = "按钮"
    }
}
local view = gui:load_layout(layout)
gui:add_view(view)
```

#### update(dt)

更新 GUI 状态（每帧调用）。

```lua
gui:update(dt)
```

**参数:**
- `dt` (number): 时间增量（秒）

#### draw()

绘制所有视图（每帧调用）。

```lua
gui:draw()
```

#### resize(width, height)

处理窗口大小变化。

```lua
gui:resize(width, height)
```

---

## 基础视图 (View)

所有UI组件的基类，提供通用属性和方法。

### 属性

#### 位置和尺寸

- `x` (number): X坐标
- `y` (number): Y坐标
- `width` (number): 宽度
- `height` (number): 高度

#### 可见性和状态

- `visible` (boolean): 是否可见，默认 true
- `isHover` (boolean): 是否悬停，只读
- `isPressed` (boolean): 是否按下，只读
- `isDragging` (boolean): 是否拖动，只读

#### 样式

- `backgroundColor` (table): 背景色，RGBA格式 `{r, g, b, a}`
- `borderColor` (table): 边框色
- `hoverColor` (table): 悬停时颜色
- `pressedColor` (table): 按下时颜色
- `textColor` (table): 文本颜色
- `textSize` (number): 文本大小，默认 10
- `font` (string): 字体路径或名称，默认 "default"

#### 层级和关系

- `_layer` (number): 图层编号，1-11
- `_draw_order` (number): 同层绘制顺序
- `parent` (View): 父视图
- `children` (table): 子视图列表
- `gui` (GUI): 所属的GUI管理器
- `name` (string): 视图名称（内存地址标识）
- `id` (string): 自定义ID

#### 交互扩展

- `is_extension` (boolean): 是否启用扩展点击区域
- `extension_x`, `extension_y` (number): 扩展区域坐标
- `extension_width`, `extension_height` (number): 扩展区域尺寸

### 方法

#### new(options)

创建新视图实例。

```lua
view:new(options)
```

**参数:**
- `options` (table, 可选): 属性配置

#### add_view(child)

添加子视图。

```lua
view:add_view(child_view)
```

#### remove_view(child)

移除子视图。

```lua
view:remove_view(child_view)
```

#### destroy()

销毁视图（从父视图和GUI中移除）。

```lua
view:destroy()
```

#### get_font(fontName, size)

获取字体对象。

```lua
view:get_font(fontName, size)
```

**返回值:** Love2D Font 对象

#### get_local_Position(x, y)

获取相对于视图的局部坐标。

```lua
local localX, localY = view:get_local_Position(globalX, globalY)
```

#### is_point_inside(x, y)

判断点是否在视图内。

```lua
local inside = view:is_point_inside(x, y)
```

**返回值:** boolean

### 事件回调

以下方法可在子类中重写以处理事件：

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
    -- 拖动事件（按下后移动）
end

function view:init()
    -- 初始化回调
end

function view:update(dt)
    -- 更新回调
end

function view:draw()
    -- 绘制回调
end
```

---

## 视图组件

### Button 按钮

可点击的按钮组件。

```lua
snowGui.button:new(options)
```

**特有属性:**
- `text` (string): 按钮文本，默认 "button"

**示例:**
```lua
local button = snowGui.button:new({
    x = 100,
    y = 100,
    width = 120,
    height = 40,
    text = "点击我",
    backgroundColor = {0.5, 0.5, 1, 1}
})

function button:on_click(id, x, y)
    print("按钮被点击")
end
```

---

### Text 文本

显示静态文本的标签。

```lua
snowGui.text:new(options)
```

**特有属性:**
- `text` (string): 显示文本
- `align` (string): 对齐方式 "left", "center", "right"
- `valign` (string): 垂直对齐 "top", "middle", "bottom"

**示例:**
```lua
local label = snowGui.text:new({
    x = 50,
    y = 50,
    width = 200,
    height = 30,
    text = "Hello World",
    textSize = 16,
    textColor = {0, 0, 0, 1},
    align = "center"
})
```

---

### EditText 可编辑文本

多行文本编辑器。

```lua
snowGui.edit_text:new(options)
```

**特有属性:**
- `text` (string): 文本内容
- `editable` (boolean): 是否可编辑
- `cursor_pos` (number): 光标位置

**方法:**
- `get_text()`: 获取文本内容
- `set_text(text)`: 设置文本内容
- `append_text(text)`: 追加文本

**示例:**
```lua
local editor = snowGui.edit_text:new({
    x = 10,
    y = 10,
    width = 300,
    height = 200,
    text = "可编辑的文本内容"
})
```

---

### InputText 输入框

单行文本输入框。

```lua
snowGui.input_text:new(options)
```

**特有属性:**
- `placeholder` (string): 占位符文本
- `password` (boolean): 是否为密码框
- `max_length` (number): 最大字符数

**示例:**
```lua
local input = snowGui.input_text:new({
    x = 10,
    y = 10,
    width = 200,
    height = 30,
    placeholder = "请输入文本"
})

function input:on_text_changed(text)
    print("输入内容:", text)
end
```

---

### Slider 滑块

数值选择滑块。

```lua
snowGui.slider:new(options)
```

**特有属性:**
- `value` (number): 当前值
- `min` (number): 最小值，默认 0
- `max` (number): 最大值，默认 100
- `step` (number): 步进值
- `orientation` (string): 方向 "horizontal" 或 "vertical"

**方法:**
- `get_value()`: 获取当前值
- `set_value(value)`: 设置值

**示例:**
```lua
local slider = snowGui.slider:new({
    x = 50,
    y = 100,
    width = 200,
    height = 20,
    min = 0,
    max = 100,
    value = 50,
    orientation = "horizontal"
})

function slider:on_value_changed(value)
    print("当前值:", value)
end
```

---

### SwitchButton 开关按钮

布尔值切换开关。

```lua
snowGui.switch_button:new(options)
```

**特有属性:**
- `checked` (boolean): 是否选中
- `on_text` (string): 开启状态文本
- `off_text` (string): 关闭状态文本

**示例:**
```lua
local switch = snowGui.switch_button:new({
    x = 100,
    y = 100,
    checked = false
})

function switch:on_toggle(checked)
    print("开关状态:", checked)
end
```

---

### SelectButton 选择按钮

单选或多选按钮。

```lua
snowGui.select_button:new(options)
```

**特有属性:**
- `selected` (boolean): 是否被选中
- `group` (string): 单选组名称

---

### SelectMenu 下拉菜单

下拉选项菜单。

```lua
snowGui.select_menu:new(options)
```

**特有属性:**
- `options` (table): 选项列表
- `selected_index` (number): 当前选中索引

**示例:**
```lua
local menu = snowGui.select_menu:new({
    x = 50,
    y = 50,
    width = 150,
    height = 30,
    options = {"选项1", "选项2", "选项3"}
})

function menu:on_selection_changed(index, value)
    print("选中:", index, value)
end
```

---

### List 列表

可滚动的列表容器。

```lua
snowGui.list:new(options)
```

**特有属性:**
- `items` (table): 列表项
- `item_height` (number): 每项高度
- `scroll_offset` (number): 滚动偏移

---

### Image 图片

图片显示组件。

```lua
snowGui.image:new(options)
```

**特有属性:**
- `image_path` (string): 图片文件路径
- `scale` (number): 缩放比例
- `rotation` (number): 旋转角度

**示例:**
```lua
local img = snowGui.image:new({
    x = 100,
    y = 100,
    width = 200,
    height = 200,
    image_path = "assets/logo.png"
})
```

---

## 布局系统

### LineLayout 线性布局

按垂直或水平方向排列子视图。

```lua
snowGui.line_layout:new(options)
```

**特有属性:**
- `orientation` (string): 排列方向
  - `"vertical"`: 垂直（默认）
  - `"horizontal"`: 水平
- `gravity` (string): 子视图对齐方式
  - 支持组合: `"top|left"`, `"center"`, `"bottom|right"` 等
- `padding` (number): 统一内边距
- `padding_top`, `padding_right`, `padding_left`, `padding_bottom` (number): 各边内边距

**子视图布局属性:**
- `layout_weight` (number): 布局权重
  - `< 0`: 自适应内容
  - `= 0`: 按自身尺寸
  - `> 0`: 按权重分配剩余空间
- `layout_margin` (number): 统一外边距
- `layout_margin_top`, `layout_margin_right`, `layout_margin_left`, `layout_margin_bottom` (number): 各边外边距

**示例:**
```lua
local layout = snowGui.line_layout:new({
    x = 10,
    y = 10,
    width = 300,
    height = 400,
    orientation = "vertical",
    gravity = "center",
    padding = 10
})

local btn1 = snowGui.button:new({
    text = "按钮1",
    layout_weight = 1,
    layout_margin = 5
})

local btn2 = snowGui.button:new({
    text = "按钮2",
    layout_weight = 1,
    layout_margin = 5
})

layout:add_view(btn1)
layout:add_view(btn2)
```

---

### GridLayout 网格布局

网格状排列子视图。

```lua
snowGui.grid_layout:new(options)
```

**特有属性:**
- `rows` (number): 行数
- `columns` (number): 列数
- `cell_width` (number): 单元格宽度
- `cell_height` (number): 单元格高度
- `spacing` (number): 间距

**示例:**
```lua
local grid = snowGui.grid_layout:new({
    x = 10,
    y = 10,
    width = 400,
    height = 400,
    rows = 3,
    columns = 3,
    spacing = 5
})

for i = 1, 9 do
    local btn = snowGui.button:new({
        text = tostring(i)
    })
    grid:add_view(btn)
end
```

---

### GravityLayout 重力布局

按重力方向对齐子视图。

```lua
snowGui.gravity_layout:new(options)
```

**特有属性:**
- `gravity` (string): 重力方向
  - 可选: `"top"`, `"bottom"`, `"left"`, `"right"`, `"center"`
  - 可组合: `"top|left"`, `"bottom|right"` 等

---

### FrameLayout 帧布局

层叠式布局，子视图重叠显示。

```lua
snowGui.frame_layout:new(options)
```

**特点:**
- 子视图按添加顺序从下到上层叠
- 适合创建多层UI效果

---

## 容器组件

### Window 窗口

可拖动、可调整大小的窗口容器。

```lua
snowGui.window:new(options)
```

**特有属性:**
- `title` (string): 窗口标题
- `draggable` (boolean): 是否可拖动
- `resizable` (boolean): 是否可调整大小
- `closable` (boolean): 是否可关闭

**示例:**
```lua
local window = snowGui.window:new({
    x = 100,
    y = 100,
    width = 400,
    height = 300,
    title = "我的窗口",
    draggable = true,
    resizable = true
})

local content = snowGui.text:new({
    text = "窗口内容"
})
window:add_view(content)
```

---

### Dialog 对话框

模态对话框。

```lua
snowGui.dialog:new(options)
```

**特有属性:**
- `modal` (boolean): 是否模态
- `title` (string): 对话框标题
- `message` (string): 提示消息

---

### TabControl 标签页

多标签页切换控制器。

```lua
snowGui.tab_control:new(options)
```

**特有属性:**
- `tabs` (table): 标签页列表
- `active_tab` (number): 当前活动标签索引

**示例:**
```lua
local tabControl = snowGui.tab_control:new({
    x = 10,
    y = 10,
    width = 500,
    height = 400
})

tabControl:add_tab("标签1", content1)
tabControl:add_tab("标签2", content2)
```

---

### BorderContainer 边框容器

带边框的容器。

```lua
snowGui.border_container:new(options)
```

**特有属性:**
- `border_width` (number): 边框宽度
- `border_style` (string): 边框样式

---

### FoldContainer 折叠容器

可折叠/展开的面板容器。

```lua
snowGui.fold_container:new(options)
```

**特有属性:**
- `folded` (boolean): 是否折叠状态
- `header_text` (string): 头部文本

**示例:**
```lua
local foldPanel = snowGui.fold_container:new({
    x = 10,
    y = 10,
    width = 300,
    header_text = "点击展开/折叠",
    folded = false
})

local content = snowGui.text:new({
    text = "这是折叠面板的内容"
})
foldPanel:add_view(content)
```

---

### SliderContainer 滑动容器

可滚动的内容容器。

```lua
snowGui.slider_container:new(options)
```

**特有属性:**
- `scroll_x` (number): 水平滚动偏移
- `scroll_y` (number): 垂直滚动偏移
- `scrollbar_visible` (boolean): 是否显示滚动条

---

### TitleMenu 标题菜单

带标题栏的菜单容器。

```lua
snowGui.title_menu:new(options)
```

---

### TreeManager 树形管理器

树形结构视图管理器。

```lua
snowGui.tree_manager:new(options)
```

**方法:**
- `add_node(parent, node)`: 添加节点
- `remove_node(node)`: 移除节点
- `expand_node(node)`: 展开节点
- `collapse_node(node)`: 折叠节点

---

## 工具库

### Color 颜色工具

颜色处理工具类。

```lua
snowGui.Color
```

**方法:**

```lua
-- RGB转十六进制
Color.RGBA_To_HEX({r, g, b, a})  -- 返回 "#RRGGBBAA"

-- 十六进制转RGB
Color.HEX_To_RGBA("#RRGGBBAA")   -- 返回 {r, g, b, a}

-- HSV转RGB
Color.HSV_To_RGB(h, s, v)        -- 返回 {r, g, b}

-- RGB转HSV
Color.RGB_To_HSV(r, g, b)        -- 返回 {h, s, v}
```

---

### Camera 相机

2D相机系统。

```lua
snowGui.Camera:new(options)
```

**方法:**
- `set_position(x, y)`: 设置相机位置
- `move(dx, dy)`: 移动相机
- `set_zoom(zoom)`: 设置缩放级别
- `attach()`: 应用相机变换
- `detach()`: 取消相机变换

---

### EventsSystem 事件系统

事件订阅发布系统。

```lua
snowGui.events_system:new()
```

**方法:**

```lua
-- 订阅事件
events:subscribe(event_name, callback)

-- 取消订阅
events:unsubscribe(event_name, callback)

-- 发布事件
events:publish(event_name, data)
```

**示例:**
```lua
local events = snowGui.events_system:new()

-- 订阅
local handler = function(data)
    print("收到事件:", data.message)
end
events:subscribe("custom_event", handler)

-- 发布
events:publish("custom_event", { message = "Hello" })

-- 取消订阅
events:unsubscribe("custom_event", handler)
```

---

### FontManager 字体管理器

字体管理器（单例模式）。

```lua
snowGui.font_manger
```

**方法:**

```lua
-- 加载字体
font_manger:load_font(name, path, size)

-- 获取字体
local font = font_manger:get_font(name, size)

-- 设置默认字体
font_manger:set_default_font(name)
```

---

## 全局变量

- `lumenGui_path`: 框架包路径
- `lumenGui_FILE_PATH`: 框架文件路径
- `ChineseFont`: 中文字体文件路径

---

## 类型定义

### 颜色格式

颜色使用RGBA表格式：

```lua
{r, g, b, a}  -- 每个值范围 0-1
```

示例:
```lua
{1, 0, 0, 1}      -- 红色
{0, 1, 0, 0.5}    -- 半透明绿色
{0.5, 0.5, 0.5, 1} -- 灰色
```

### 重力方向

- `"top"`: 顶部
- `"bottom"`: 底部
- `"left"`: 左侧
- `"right"`: 右侧
- `"center"`: 居中
- 可组合: `"top|left"`, `"bottom|right"`, `"center|top"` 等

---

## 注意事项

1. **坐标系统**: 原点 (0,0) 在左上角
2. **图层**: 范围 1-11，数字越大越靠前
3. **事件传递**: 从最上层视图开始，向下传递
4. **内存管理**: 视图使用弱引用表，但建议手动调用 `destroy()` 清理
5. **字体加载**: 首次使用字体时会自动加载，建议在 `love.load()` 中预加载

---

**更多示例请参考 [EXAMPLES_CN.md](EXAMPLES_CN.md)**
