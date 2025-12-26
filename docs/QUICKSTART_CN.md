# snowGui-pluss 快速入门指南

本指南帮助您快速上手 snowGui-pluss 框架。

## 5分钟快速开始

### 第一步：安装 LÖVE2D

1. 访问 [LÖVE2D 官网](https://love2d.org/)
2. 下载并安装 LÖVE2D 11.4 或更高版本
3. 验证安装：在命令行运行 `love --version`

### 第二步：克隆项目

```bash
git clone https://github.com/lmmgh-ai/snowGui-pluss.git
cd snowGui-pluss
```

### 第三步：运行示例

```bash
love .
```

您应该会看到一个窗口打开，这就是 snowGui-pluss 的演示程序！

---

## 创建第一个应用

### 1. 创建项目结构

```
my-app/
├── main.lua          # 入口文件
├── conf.lua          # 配置文件
└── packages/         # 复制 snowGui-pluss 的 packages 目录
```

### 2. 编写 conf.lua

```lua
function love.conf(t)
    t.window.title = '我的第一个GUI应用'
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = true
    t.version = '11.4'
end
```

### 3. 编写 main.lua

```lua
-- 引入框架
local packages = require("packages")
local snowGui = packages.snowGui

-- 创建 GUI 管理器
local gui = snowGui:new()

-- 初始化
function love.load()
    -- 创建一个欢迎文本
    local welcomeText = snowGui.text:new({
        x = 250,
        y = 200,
        width = 300,
        height = 50,
        text = "欢迎使用 snowGui!",
        textSize = 24,
        textColor = {0, 0, 0, 1}
    })
    
    -- 创建一个按钮
    local myButton = snowGui.button:new({
        x = 300,
        y = 300,
        width = 200,
        height = 50,
        text = "点击我",
        textSize = 16
    })
    
    -- 按钮点击事件
    function myButton:on_click()
        print("按钮被点击了!")
        welcomeText.text = "你点击了按钮！"
    end
    
    -- 添加到 GUI
    gui:add_view(welcomeText)
    gui:add_view(myButton)
end

-- 更新
function love.update(dt)
    gui:update(dt)
end

-- 绘制
function love.draw()
    love.graphics.clear(0.95, 0.95, 0.95)  -- 浅灰色背景
    gui:draw()
end

-- === 事件处理 ===
function love.mousepressed(x, y, button, istouch, presses)
    gui:mousepressed(button, x, y, nil, nil, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    gui:mousereleased(button, x, y, nil, nil, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
    gui:mousemoved(nil, x, y, dx, dy, istouch, nil)
end

function love.keypressed(key)
    gui:keypressed(key)
end

function love.textinput(text)
    gui:textinput(text)
end
```

### 4. 运行应用

```bash
cd my-app
love .
```

---

## 常见组件使用

### 按钮 Button

```lua
local button = snowGui.button:new({
    x = 100,
    y = 100,
    width = 120,
    height = 40,
    text = "点击我",
    backgroundColor = {0.3, 0.6, 1, 1}
})

function button:on_click()
    print("按钮被点击")
end

gui:add_view(button)
```

### 文本标签 Text

```lua
local label = snowGui.text:new({
    x = 50,
    y = 50,
    width = 200,
    height = 30,
    text = "这是一个标签",
    textSize = 16,
    textColor = {0, 0, 0, 1}
})

gui:add_view(label)
```

### 输入框 InputText

```lua
local input = snowGui.input_text:new({
    x = 50,
    y = 100,
    width = 300,
    height = 35,
    placeholder = "请输入文本"
})

function input:on_text_changed(text)
    print("输入内容:", text)
end

gui:add_view(input)
```

### 滑块 Slider

```lua
local slider = snowGui.slider:new({
    x = 50,
    y = 150,
    width = 300,
    height = 20,
    min = 0,
    max = 100,
    value = 50
})

function slider:on_value_changed(value)
    print("当前值:", value)
end

gui:add_view(slider)
```

---

## 使用布局

布局可以自动排列子组件，省去手动计算位置的麻烦。

### 垂直线性布局

```lua
-- 创建垂直布局
local layout = snowGui.line_layout:new({
    x = 50,
    y = 50,
    width = 300,
    height = 400,
    orientation = "vertical",  -- 垂直方向
    padding = 10               -- 内边距
})

-- 添加按钮
for i = 1, 5 do
    local btn = snowGui.button:new({
        text = "按钮 " .. i,
        height = 60,
        layout_margin = 5  -- 按钮之间的间距
    })
    layout:add_view(btn)
end

gui:add_view(layout)
```

### 水平线性布局

```lua
local layout = snowGui.line_layout:new({
    x = 50,
    y = 50,
    width = 500,
    height = 80,
    orientation = "horizontal",  -- 水平方向
    padding = 10
})

-- 添加三个按钮
local btn1 = snowGui.button:new({
    text = "按钮1",
    width = 100,
    layout_margin = 5
})

local btn2 = snowGui.button:new({
    text = "按钮2",
    width = 100,
    layout_margin = 5
})

local btn3 = snowGui.button:new({
    text = "按钮3",
    width = 100,
    layout_margin = 5
})

layout:add_view(btn1)
layout:add_view(btn2)
layout:add_view(btn3)

gui:add_view(layout)
```

---

## 事件处理完整模板

将以下代码添加到您的 `main.lua` 中，确保所有事件都能正确处理：

```lua
-- Windows 平台
if love.system.getOS() == "Windows" then
    function love.mousemoved(x, y, dx, dy, istouch)
        gui:mousemoved(nil, x, y, dx, dy, istouch, nil)
    end

    function love.mousepressed(x, y, button, istouch, presses)
        gui:mousepressed(button, x, y, nil, nil, istouch, presses)
    end

    function love.mousereleased(x, y, button, istouch, presses)
        gui:mousereleased(button, x, y, nil, nil, istouch, presses)
    end

    function love.wheelmoved(x, y)
        gui:wheelmoved(nil, x, y)
    end
end

-- Android 平台
if love.system.getOS() == "Android" then
    function love.touchpressed(id, x, y, dx, dy, pressure)
        gui:touchpressed(id, x, y, dx, dy, true, pressure)
    end

    function love.touchmoved(id, x, y, dx, dy, pressure)
        gui:touchmoved(id, x, y, dx, dy, true, pressure)
    end

    function love.touchreleased(id, x, y, dx, dy, pressure)
        gui:touchreleased(id, x, y, dx, dy, true, pressure)
    end
end

-- 键盘和文本输入
function love.keypressed(key)
    gui:keypressed(key)
end

function love.textinput(text)
    gui:textinput(text)
end

-- 窗口事件
function love.resize(width, height)
    gui:resize(width, height)
end

function love.quit()
    gui:quit()
end
```

---

## 调试技巧

### 1. 启用调试输出

```lua
-- 在 love.load() 中
local debugGraph = snowGui.debugGraph
local CustomPrint = snowGui.CustomPrint

debugGraph:load()
CustomPrint:load()

-- 在 love.update(dt) 中
debugGraph:update(dt)
CustomPrint:update(dt)

-- 在 love.draw() 中
debugGraph:draw()
CustomPrint:draw()
```

### 2. 打印视图信息

```lua
function button:on_click()
    print("按钮位置:", self.x, self.y)
    print("按钮尺寸:", self.width, self.height)
    print("父视图:", self.parent)
    print("子视图数量:", #self.children)
end
```

### 3. 查看所有视图

```lua
function love.keypressed(key)
    if key == "d" then  -- 按 D 键查看所有视图
        for i, view in pairs(gui.views) do
            print(string.format("视图: %s, 类型: %s, 位置: (%d,%d)", 
                view.name, view.type, view.x, view.y))
        end
    end
    
    gui:keypressed(key)
end
```

---

## 常见问题

### Q: 我的按钮没有响应点击？

**A:** 检查以下几点：
1. 是否正确设置了鼠标事件处理函数？
2. 按钮是否被其他视图遮挡？（检查 `_layer` 属性）
3. 按钮是否可见？（`visible = true`）
4. 点击坐标是否在按钮范围内？

### Q: 文本显示为方框？

**A:** 可能是字体不支持中文。使用框架提供的中文字体：

```lua
local text = snowGui.text:new({
    text = "中文文本",
    font = ChineseFont,  -- 使用内置中文字体
    textSize = 16
})
```

### Q: 布局没有按预期排列？

**A:** 确保：
1. 设置了正确的 `orientation` (vertical/horizontal)
2. 子视图的 `layout_weight` 设置正确
3. 在添加完所有子视图后调用了 `layout:layout()`（通常自动调用）

### Q: 如何隐藏视图？

**A:** 设置 `visible` 属性：

```lua
view.visible = false  -- 隐藏
view.visible = true   -- 显示
```

### Q: 如何删除视图？

**A:** 调用 `destroy()` 方法：

```lua
button:destroy()  -- 从父视图和 GUI 中移除
```

---

## 下一步

现在您已经掌握了基础知识，可以：

1. **查看完整示例**: 参考 [EXAMPLES_CN.md](EXAMPLES_CN.md)
2. **学习 API**: 阅读 [API_CN.md](API_CN.md)
3. **理解架构**: 深入 [ARCHITECTURE_CN.md](ARCHITECTURE_CN.md)
4. **查看源码**: 研究 `experiment/` 目录中的示例

---

## 获取帮助

- **查看示例代码**: `experiment/test.lua`, `experiment/test1.lua`
- **阅读源码**: `packages/snowGui/` 目录
- **提交问题**: GitHub Issues

祝您开发愉快！ 🎉
