# snowGui-pluss 使用示例

本文档提供各种实用的 snowGui-pluss 使用示例。

## 目录

- [基础示例](#基础示例)
- [按钮示例](#按钮示例)
- [输入框示例](#输入框示例)
- [列表示例](#列表示例)
- [布局示例](#布局示例)
- [窗口和对话框](#窗口和对话框)
- [事件通信](#事件通信)
- [自定义组件](#自定义组件)
- [完整应用示例](#完整应用示例)

---

## 基础示例

### 最小示例

创建一个最简单的 GUI 应用：

```lua
local packages = require("packages")
local snowGui = packages.snowGui
local gui = snowGui:new()

function love.load()
    -- 什么都不做，显示空白窗口
end

function love.update(dt)
    gui:update(dt)
end

function love.draw()
    love.graphics.clear(1, 1, 1)
    gui:draw()
end

function love.mousepressed(x, y, button, istouch, presses)
    gui:mousepressed(button, x, y, nil, nil, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    gui:mousereleased(button, x, y, nil, nil, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
    gui:mousemoved(nil, x, y, dx, dy, istouch, nil)
end
```

---

## 按钮示例

### 基础按钮

```lua
function love.load()
    local button = snowGui.button:new({
        x = 100,
        y = 100,
        width = 120,
        height = 40,
        text = "点击我",
        textSize = 14,
        backgroundColor = {0.2, 0.6, 1, 1},
        hoverColor = {0.3, 0.7, 1, 1},
        pressedColor = {0.1, 0.5, 0.9, 1}
    })
    
    function button:on_click(id, x, y)
        print("按钮被点击了!")
    end
    
    gui:add_view(button)
end
```

### 多个按钮

```lua
function love.load()
    local buttons = {}
    local buttonNames = {"保存", "加载", "删除", "退出"}
    
    for i, name in ipairs(buttonNames) do
        local btn = snowGui.button:new({
            x = 50,
            y = 50 + (i - 1) * 60,
            width = 100,
            height = 45,
            text = name
        })
        
        function btn:on_click()
            print(name .. " 按钮被点击")
        end
        
        gui:add_view(btn)
        table.insert(buttons, btn)
    end
end
```

### 带图标的按钮

```lua
function love.load()
    local iconButton = snowGui.button:new({
        x = 100,
        y = 100,
        width = 60,
        height = 60,
        text = "📁"  -- 使用 emoji 作为图标
    })
    
    function iconButton:on_click()
        print("打开文件")
    end
    
    gui:add_view(iconButton)
end
```

---

## 输入框示例

### 简单输入框

```lua
function love.load()
    local input = snowGui.input_text:new({
        x = 50,
        y = 50,
        width = 300,
        height = 35,
        placeholder = "请输入您的名字",
        textSize = 14
    })
    
    function input:on_text_changed(text)
        print("当前输入:", text)
    end
    
    gui:add_view(input)
end
```

### 密码输入框

```lua
function love.load()
    local passwordInput = snowGui.input_text:new({
        x = 50,
        y = 100,
        width = 300,
        height = 35,
        placeholder = "请输入密码",
        password = true  -- 显示为 ****
    })
    
    gui:add_view(passwordInput)
end
```

### 带标签的输入框

```lua
function love.load()
    -- 标签
    local label = snowGui.text:new({
        x = 50,
        y = 50,
        width = 100,
        height = 30,
        text = "用户名:",
        textSize = 14
    })
    
    -- 输入框
    local input = snowGui.input_text:new({
        x = 150,
        y = 50,
        width = 200,
        height = 30
    })
    
    gui:add_view(label)
    gui:add_view(input)
end
```

### 表单示例

```lua
function love.load()
    local form = {}
    
    -- 用户名
    local usernameLabel = snowGui.text:new({
        x = 50, y = 50, width = 100, height = 30,
        text = "用户名:", textSize = 14
    })
    local usernameInput = snowGui.input_text:new({
        x = 150, y = 50, width = 200, height = 30
    })
    
    -- 密码
    local passwordLabel = snowGui.text:new({
        x = 50, y = 100, width = 100, height = 30,
        text = "密码:", textSize = 14
    })
    local passwordInput = snowGui.input_text:new({
        x = 150, y = 100, width = 200, height = 30,
        password = true
    })
    
    -- 提交按钮
    local submitButton = snowGui.button:new({
        x = 150, y = 150, width = 100, height = 40,
        text = "登录"
    })
    
    function submitButton:on_click()
        local username = usernameInput:get_text()
        local password = passwordInput:get_text()
        print("登录:", username, password)
    end
    
    gui:add_view(usernameLabel)
    gui:add_view(usernameInput)
    gui:add_view(passwordLabel)
    gui:add_view(passwordInput)
    gui:add_view(submitButton)
end
```

---

## 列表示例

### 简单列表

```lua
function love.load()
    local list = snowGui.list:new({
        x = 50,
        y = 50,
        width = 300,
        height = 400,
        item_height = 40
    })
    
    local items = {"项目1", "项目2", "项目3", "项目4", "项目5"}
    
    for _, itemText in ipairs(items) do
        local item = snowGui.text:new({
            text = itemText,
            height = 40
        })
        list:add_item(item)
    end
    
    gui:add_view(list)
end
```

### 可点击列表

```lua
function love.load()
    local list = snowGui.list:new({
        x = 50,
        y = 50,
        width = 300,
        height = 400
    })
    
    for i = 1, 10 do
        local item = snowGui.button:new({
            text = "列表项 " .. i,
            height = 40
        })
        
        function item:on_click()
            print("点击了:", self.text)
        end
        
        list:add_item(item)
    end
    
    gui:add_view(list)
end
```

---

## 布局示例

### 垂直线性布局

```lua
function love.load()
    local layout = snowGui.line_layout:new({
        x = 50,
        y = 50,
        width = 300,
        height = 400,
        orientation = "vertical",
        gravity = "center",
        padding = 10
    })
    
    -- 添加多个按钮
    for i = 1, 5 do
        local btn = snowGui.button:new({
            text = "按钮 " .. i,
            height = 50,
            layout_weight = 1,  -- 平均分配空间
            layout_margin = 5
        })
        layout:add_view(btn)
    end
    
    gui:add_view(layout)
end
```

### 水平线性布局

```lua
function love.load()
    local layout = snowGui.line_layout:new({
        x = 50,
        y = 50,
        width = 500,
        height = 80,
        orientation = "horizontal",
        gravity = "center",
        padding = 10
    })
    
    -- 添加按钮
    local btn1 = snowGui.button:new({
        text = "返回",
        width = 80,
        layout_margin = 5
    })
    
    local btn2 = snowGui.button:new({
        text = "确定",
        width = 80,
        layout_margin = 5
    })
    
    local btn3 = snowGui.button:new({
        text = "取消",
        width = 80,
        layout_margin = 5
    })
    
    layout:add_view(btn1)
    layout:add_view(btn2)
    layout:add_view(btn3)
    
    gui:add_view(layout)
end
```

### 网格布局

```lua
function love.load()
    local grid = snowGui.grid_layout:new({
        x = 50,
        y = 50,
        width = 300,
        height = 300,
        rows = 3,
        columns = 3,
        spacing = 5
    })
    
    -- 创建九宫格
    for i = 1, 9 do
        local btn = snowGui.button:new({
            text = tostring(i)
        })
        grid:add_view(btn)
    end
    
    gui:add_view(grid)
end
```

### 嵌套布局

```lua
function love.load()
    -- 主垂直布局
    local mainLayout = snowGui.line_layout:new({
        x = 50,
        y = 50,
        width = 400,
        height = 500,
        orientation = "vertical",
        padding = 10
    })
    
    -- 标题
    local title = snowGui.text:new({
        text = "设置面板",
        textSize = 20,
        height = 40
    })
    mainLayout:add_view(title)
    
    -- 水平布局（按钮组）
    local buttonRow = snowGui.line_layout:new({
        orientation = "horizontal",
        height = 50,
        layout_margin_top = 10
    })
    
    local saveBtn = snowGui.button:new({
        text = "保存",
        layout_weight = 1,
        layout_margin = 5
    })
    
    local cancelBtn = snowGui.button:new({
        text = "取消",
        layout_weight = 1,
        layout_margin = 5
    })
    
    buttonRow:add_view(saveBtn)
    buttonRow:add_view(cancelBtn)
    mainLayout:add_view(buttonRow)
    
    gui:add_view(mainLayout)
end
```

---

## 窗口和对话框

### 基础窗口

```lua
function love.load()
    local window = snowGui.window:new({
        x = 100,
        y = 100,
        width = 400,
        height = 300,
        title = "我的窗口",
        draggable = true,
        resizable = true
    })
    
    -- 窗口内容
    local content = snowGui.text:new({
        x = 20,
        y = 50,
        text = "这是窗口内容",
        textSize = 14
    })
    
    window:add_view(content)
    gui:add_view(window)
end
```

### 确认对话框

```lua
function love.load()
    local function showConfirmDialog(message, onConfirm, onCancel)
        local dialog = snowGui.dialog:new({
            x = 200,
            y = 200,
            width = 400,
            height = 200,
            title = "确认",
            modal = true
        })
        
        -- 消息
        local msgText = snowGui.text:new({
            x = 20,
            y = 60,
            width = 360,
            height = 60,
            text = message,
            textSize = 14
        })
        
        -- 按钮布局
        local btnLayout = snowGui.line_layout:new({
            x = 100,
            y = 130,
            width = 200,
            height = 50,
            orientation = "horizontal"
        })
        
        local confirmBtn = snowGui.button:new({
            text = "确定",
            layout_weight = 1,
            layout_margin = 5
        })
        
        local cancelBtn = snowGui.button:new({
            text = "取消",
            layout_weight = 1,
            layout_margin = 5
        })
        
        function confirmBtn:on_click()
            if onConfirm then onConfirm() end
            dialog:destroy()
        end
        
        function cancelBtn:on_click()
            if onCancel then onCancel() end
            dialog:destroy()
        end
        
        btnLayout:add_view(confirmBtn)
        btnLayout:add_view(cancelBtn)
        
        dialog:add_view(msgText)
        dialog:add_view(btnLayout)
        gui:add_view(dialog)
    end
    
    -- 测试按钮
    local testBtn = snowGui.button:new({
        x = 100,
        y = 50,
        width = 150,
        height = 40,
        text = "显示对话框"
    })
    
    function testBtn:on_click()
        showConfirmDialog(
            "确定要删除这个文件吗？",
            function() print("已确认") end,
            function() print("已取消") end
        )
    end
    
    gui:add_view(testBtn)
end
```

---

## 事件通信

### 组件间通信

```lua
function love.load()
    -- 创建事件系统
    local events = gui.events_system
    
    -- 发送者按钮
    local senderBtn = snowGui.button:new({
        x = 100,
        y = 100,
        width = 120,
        height = 40,
        text = "发送消息"
    })
    
    function senderBtn:on_click()
        events:publish("message_sent", { 
            text = "Hello World!",
            time = os.time()
        })
    end
    
    -- 接收者文本
    local receiverText = snowGui.text:new({
        x = 100,
        y = 200,
        width = 300,
        height = 40,
        text = "等待消息...",
        textSize = 14
    })
    
    -- 订阅事件
    events:subscribe("message_sent", function(data)
        receiverText.text = "收到: " .. data.text
    end)
    
    gui:add_view(senderBtn)
    gui:add_view(receiverText)
end
```

### 数据绑定

```lua
function love.load()
    local events = gui.events_system
    
    -- 滑块
    local slider = snowGui.slider:new({
        x = 50,
        y = 100,
        width = 300,
        height = 20,
        min = 0,
        max = 100,
        value = 50
    })
    
    -- 显示值的文本
    local valueText = snowGui.text:new({
        x = 370,
        y = 95,
        width = 80,
        height = 30,
        text = "50",
        textSize = 16
    })
    
    function slider:on_value_changed(value)
        valueText.text = tostring(math.floor(value))
        events:publish("value_changed", value)
    end
    
    gui:add_view(slider)
    gui:add_view(valueText)
end
```

---

## 自定义组件

### 创建自定义按钮

```lua
-- 自定义圆形按钮
local CircleButton = snowGui.button:new()
CircleButton.__index = CircleButton

function CircleButton:new(options)
    local obj = snowGui.button.new(self, options)
    obj.radius = options.radius or 30
    return obj
end

function CircleButton:draw()
    if not self.visible then return end
    
    -- 选择颜色
    local color = self.backgroundColor
    if self.isPressed then
        color = self.pressedColor
    elseif self.isHover then
        color = self.hoverColor
    end
    
    -- 绘制圆形
    love.graphics.setColor(color)
    local cx = self.x + self.radius
    local cy = self.y + self.radius
    love.graphics.circle("fill", cx, cy, self.radius)
    
    -- 绘制边框
    love.graphics.setColor(self.borderColor)
    love.graphics.circle("line", cx, cy, self.radius)
    
    -- 绘制文本
    love.graphics.setColor(self.textColor)
    local font = self:get_font(self.font, self.textSize)
    local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    love.graphics.print(self.text, 
        cx - textWidth / 2, 
        cy - textHeight / 2)
end

-- 使用自定义按钮
function love.load()
    local circleBtn = CircleButton:new({
        x = 100,
        y = 100,
        radius = 40,
        text = "⭐",
        backgroundColor = {1, 0.8, 0, 1}
    })
    
    function circleBtn:on_click()
        print("圆形按钮被点击")
    end
    
    gui:add_view(circleBtn)
end
```

### 创建进度条组件

```lua
local ProgressBar = snowGui.view:new()
ProgressBar.__index = ProgressBar

function ProgressBar:new(options)
    local obj = snowGui.view.new(self, options)
    obj.type = "progress_bar"
    obj.progress = options.progress or 0  -- 0-100
    obj.barColor = options.barColor or {0, 0.8, 0, 1}
    return obj
end

function ProgressBar:draw()
    if not self.visible then return end
    
    -- 绘制背景
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- 绘制进度
    local progressWidth = self.width * (self.progress / 100)
    love.graphics.setColor(self.barColor)
    love.graphics.rectangle("fill", self.x, self.y, progressWidth, self.height)
    
    -- 绘制边框
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    
    -- 绘制文本
    love.graphics.setColor(self.textColor)
    local font = self:get_font(self.font, self.textSize)
    local text = string.format("%.0f%%", self.progress)
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text,
        self.x + (self.width - textWidth) / 2,
        self.y + (self.height - textHeight) / 2)
end

function ProgressBar:set_progress(value)
    self.progress = math.max(0, math.min(100, value))
end

-- 使用进度条
function love.load()
    local progressBar = ProgressBar:new({
        x = 100,
        y = 200,
        width = 400,
        height = 30,
        progress = 0,
        backgroundColor = {0.3, 0.3, 0.3, 1},
        barColor = {0, 0.6, 1, 1}
    })
    
    gui:add_view(progressBar)
    
    -- 模拟进度增加
    local timer = 0
    function love.update(dt)
        gui:update(dt)
        timer = timer + dt
        if timer > 0.05 then
            timer = 0
            local current = progressBar.progress
            if current < 100 then
                progressBar:set_progress(current + 1)
            end
        end
    end
end
```

---

## 完整应用示例

### 简单计算器

```lua
local packages = require("packages")
local snowGui = packages.snowGui
local gui = snowGui:new()

local display
local currentValue = "0"

function love.load()
    -- 显示屏
    display = snowGui.text:new({
        x = 50,
        y = 50,
        width = 300,
        height = 50,
        text = "0",
        textSize = 24,
        align = "right",
        backgroundColor = {0.9, 0.9, 0.9, 1}
    })
    gui:add_view(display)
    
    -- 按钮网格
    local grid = snowGui.grid_layout:new({
        x = 50,
        y = 120,
        width = 300,
        height = 300,
        rows = 4,
        columns = 4,
        spacing = 5
    })
    
    local buttons = {
        "7", "8", "9", "/",
        "4", "5", "6", "*",
        "1", "2", "3", "-",
        "C", "0", "=", "+"
    }
    
    for _, label in ipairs(buttons) do
        local btn = snowGui.button:new({
            text = label,
            textSize = 20
        })
        
        function btn:on_click()
            handleInput(self.text)
        end
        
        grid:add_view(btn)
    end
    
    gui:add_view(grid)
end

function handleInput(input)
    if input == "C" then
        currentValue = "0"
    elseif input == "=" then
        -- 简单计算（实际应用需要更完善的解析）
        local result = load("return " .. currentValue)()
        currentValue = tostring(result)
    else
        if currentValue == "0" then
            currentValue = input
        else
            currentValue = currentValue .. input
        end
    end
    display.text = currentValue
end

function love.update(dt)
    gui:update(dt)
end

function love.draw()
    love.graphics.clear(0.95, 0.95, 0.95)
    gui:draw()
end

function love.mousepressed(x, y, button, istouch, presses)
    gui:mousepressed(button, x, y, nil, nil, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    gui:mousereleased(button, x, y, nil, nil, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
    gui:mousemoved(nil, x, y, dx, dy, istouch, nil)
end
```

### 待办事项应用

```lua
local packages = require("packages")
local snowGui = packages.snowGui
local gui = snowGui:new()

local todoList = {}

function love.load()
    -- 标题
    local title = snowGui.text:new({
        x = 50,
        y = 20,
        width = 300,
        height = 40,
        text = "待办事项",
        textSize = 24,
        textColor = {0, 0, 0, 1}
    })
    gui:add_view(title)
    
    -- 输入框
    local input = snowGui.input_text:new({
        x = 50,
        y = 80,
        width = 250,
        height = 35,
        placeholder = "输入新任务..."
    })
    gui:add_view(input)
    
    -- 添加按钮
    local addBtn = snowGui.button:new({
        x = 310,
        y = 80,
        width = 80,
        height = 35,
        text = "添加"
    })
    
    function addBtn:on_click()
        local task = input:get_text()
        if task and task ~= "" then
            addTodoItem(task)
            input:set_text("")
        end
    end
    gui:add_view(addBtn)
    
    -- 任务列表容器
    todoList = snowGui.list:new({
        x = 50,
        y = 130,
        width = 340,
        height = 350,
        item_height = 40
    })
    gui:add_view(todoList)
end

function addTodoItem(task)
    local itemLayout = snowGui.line_layout:new({
        orientation = "horizontal",
        height = 35,
        backgroundColor = {0.95, 0.95, 0.95, 1}
    })
    
    local checkbox = snowGui.switch_button:new({
        width = 30,
        checked = false,
        layout_margin = 5
    })
    
    local taskText = snowGui.text:new({
        text = task,
        layout_weight = 1,
        textSize = 14
    })
    
    local deleteBtn = snowGui.button:new({
        text = "删除",
        width = 60,
        layout_margin = 5,
        backgroundColor = {1, 0.3, 0.3, 1}
    })
    
    function checkbox:on_toggle(checked)
        if checked then
            taskText.textColor = {0.5, 0.5, 0.5, 1}
        else
            taskText.textColor = {0, 0, 0, 1}
        end
    end
    
    function deleteBtn:on_click()
        todoList:remove_item(itemLayout)
    end
    
    itemLayout:add_view(checkbox)
    itemLayout:add_view(taskText)
    itemLayout:add_view(deleteBtn)
    
    todoList:add_item(itemLayout)
end

function love.update(dt)
    gui:update(dt)
end

function love.draw()
    love.graphics.clear(1, 1, 1)
    gui:draw()
end

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

---

## 性能优化建议

1. **避免频繁创建/销毁视图**：尽量重用视图对象
2. **使用层级系统**：合理设置 `_layer` 避免不必要的绘制
3. **延迟加载**：大型列表使用虚拟滚动
4. **批量更新**：集中更新多个视图的属性
5. **合理使用事件**：避免过多的事件订阅

---

**更多信息请参考 [API_CN.md](API_CN.md)**
