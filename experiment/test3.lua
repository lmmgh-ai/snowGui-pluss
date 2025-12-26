--[[
    snowGui-pluss 综合演示
    展示框架的核心功能和最佳实践
    作者: 北极企鹅
    时间: 2025
]]

local packages = require("packages")
local snowGui = packages.snowGui
local debugGraph = snowGui.debugGraph
local CustomPrint = snowGui.CustomPrint
local gui = snowGui:new()

-- 全局状态
local demoState = {
    currentTab = 1,
    components = {},
    animationTime = 0,
    fpsHistory = {},
    showDebug = true
}

--初始化
function love.load(...)
    debugGraph:load(...)
    CustomPrint:load()
    
    -- 创建主界面
    createMainInterface()
end

-- 创建主界面
function createMainInterface()
    -- 创建主窗口
    local mainWindow = snowGui.window:new({
        x = 50,
        y = 50,
        width = 700,
        height = 500,
        text = "snowGui-pluss 综合演示",
        backgroundColor = {0.95, 0.95, 0.98, 1}
    })
    
    -- 创建标签页控制器
    local tabControl = snowGui.tab_control:new({
        x = 10,
        y = 40,
        width = 680,
        height = 450
    })
    
    -- 标签页1: 基础组件
    local tab1 = createBasicComponentsTab()
    tabControl:add_tab("基础组件", tab1)
    
    -- 标签页2: 布局演示
    local tab2 = createLayoutDemoTab()
    tabControl:add_tab("布局系统", tab2)
    
    -- 标签页3: 高级容器
    local tab3 = createAdvancedContainersTab()
    tabControl:add_tab("高级容器", tab3)
    
    -- 标签页4: 性能测试
    local tab4 = createPerformanceTestTab()
    tabControl:add_tab("性能测试", tab4)
    
    mainWindow:add_view(tabControl)
    gui:add_view(mainWindow)
    
    -- 创建调试面板
    createDebugPanel()
end

-- 创建基础组件标签页
function createBasicComponentsTab()
    local container = snowGui.frame_layout:new({
        width = 660,
        height = 400,
        backgroundColor = {1, 1, 1, 1}
    })
    
    -- 使用线性布局组织组件
    local layout = snowGui.line_layout:new({
        x = 10,
        y = 10,
        width = 640,
        height = 380,
        orientation = "vertical",
        padding = 10
    })
    
    -- 文本标签
    local titleText = snowGui.text:new({
        text = "基础UI组件演示",
        textSize = 18,
        textColor = {0.2, 0.2, 0.2},
        height = 30,
        layout_weight = 0
    })
    layout:add_view(titleText)
    
    -- 按钮组
    local buttonLayout = snowGui.line_layout:new({
        orientation = "horizontal",
        height = 50,
        layout_weight = 0,
        layout_margin = 5
    })
    
    local button1 = snowGui.button:new({
        text = "普通按钮",
        width = 120,
        height = 40,
        backgroundColor = {0.3, 0.6, 0.9, 1}
    })
    function button1:on_click()
        CustomPrint:add_message("普通按钮被点击!")
    end
    
    local button2 = snowGui.button:new({
        text = "禁用按钮",
        width = 120,
        height = 40,
        visible = true,
        backgroundColor = {0.5, 0.5, 0.5, 1}
    })
    
    buttonLayout:add_view(button1)
    buttonLayout:add_view(button2)
    layout:add_view(buttonLayout)
    
    -- 输入框
    local inputLayout = snowGui.line_layout:new({
        orientation = "horizontal",
        height = 50,
        layout_weight = 0,
        layout_margin = 5
    })
    
    local inputLabel = snowGui.text:new({
        text = "输入框:",
        width = 80,
        textSize = 14
    })
    
    local inputText = snowGui.input_text:new({
        width = 200,
        height = 35,
        text = "在此输入文本",
        backgroundColor = {1, 1, 1, 1},
        borderColor = {0.3, 0.3, 0.3, 1}
    })
    
    inputLayout:add_view(inputLabel)
    inputLayout:add_view(inputText)
    layout:add_view(inputLayout)
    
    -- 滑块
    local sliderLayout = snowGui.line_layout:new({
        orientation = "horizontal",
        height = 50,
        layout_weight = 0,
        layout_margin = 5
    })
    
    local sliderLabel = snowGui.text:new({
        text = "滑块: 50",
        width = 100,
        textSize = 14
    })
    
    local slider = snowGui.slider:new({
        width = 300,
        height = 30,
        min = 0,
        max = 100,
        value = 50
    })
    
    function slider:on_value_change(value)
        sliderLabel.text = string.format("滑块: %d", value)
    end
    
    sliderLayout:add_view(sliderLabel)
    sliderLayout:add_view(slider)
    layout:add_view(sliderLayout)
    
    -- 开关按钮
    local switchLayout = snowGui.line_layout:new({
        orientation = "horizontal",
        height = 50,
        layout_weight = 0,
        layout_margin = 5
    })
    
    local switchLabel = snowGui.text:new({
        text = "开关:",
        width = 80,
        textSize = 14
    })
    
    local switchButton = snowGui.switch_button:new({
        width = 60,
        height = 30,
        checked = true
    })
    
    function switchButton:on_toggle(checked)
        CustomPrint:add_message("开关状态: " .. (checked and "开" or "关"))
    end
    
    switchLayout:add_view(switchLabel)
    switchLayout:add_view(switchButton)
    layout:add_view(switchLayout)
    
    container:add_view(layout)
    return container
end

-- 创建布局演示标签页
function createLayoutDemoTab()
    local container = snowGui.frame_layout:new({
        width = 660,
        height = 400,
        backgroundColor = {1, 1, 1, 1}
    })
    
    local mainLayout = snowGui.line_layout:new({
        x = 10,
        y = 10,
        width = 640,
        height = 380,
        orientation = "vertical",
        padding = 10
    })
    
    -- 标题
    local title = snowGui.text:new({
        text = "布局系统演示",
        textSize = 18,
        height = 30,
        layout_weight = 0
    })
    mainLayout:add_view(title)
    
    -- 水平线性布局示例
    local hLayout = snowGui.line_layout:new({
        orientation = "horizontal",
        height = 80,
        layout_weight = 0,
        layout_margin = 5,
        backgroundColor = {0.9, 0.95, 1, 1}
    })
    
    for i = 1, 4 do
        local box = snowGui.view:new({
            width = 80,
            height = 60,
            layout_margin = 5,
            backgroundColor = {0.3 + i*0.1, 0.4 + i*0.1, 0.9, 1}
        })
        hLayout:add_view(box)
    end
    
    mainLayout:add_view(hLayout)
    
    -- 垂直线性布局示例
    local vLayout = snowGui.line_layout:new({
        orientation = "vertical",
        width = 120,
        height = 200,
        layout_weight = 0,
        layout_margin = 5,
        backgroundColor = {1, 0.95, 0.9, 1}
    })
    
    for i = 1, 3 do
        local box = snowGui.view:new({
            height = 50,
            layout_margin = 5,
            backgroundColor = {0.9, 0.4 + i*0.1, 0.3 + i*0.1, 1}
        })
        vLayout:add_view(box)
    end
    
    mainLayout:add_view(vLayout)
    
    container:add_view(mainLayout)
    return container
end

-- 创建高级容器标签页
function createAdvancedContainersTab()
    local container = snowGui.frame_layout:new({
        width = 660,
        height = 400,
        backgroundColor = {1, 1, 1, 1}
    })
    
    local layout = snowGui.line_layout:new({
        x = 10,
        y = 10,
        width = 640,
        height = 380,
        orientation = "vertical",
        padding = 10
    })
    
    -- 标题
    local title = snowGui.text:new({
        text = "高级容器组件",
        textSize = 18,
        height = 30,
        layout_weight = 0
    })
    layout:add_view(title)
    
    -- 可折叠容器
    local foldContainer = snowGui.fold_container:new({
        width = 620,
        height = 150,
        text = "可折叠面板 (点击展开/折叠)",
        layout_weight = 0,
        layout_margin = 5
    })
    
    local foldContent = snowGui.text:new({
        text = "这是可折叠面板的内容区域\n可以放置任何UI组件",
        textSize = 14,
        x = 10,
        y = 10
    })
    foldContainer:add_view(foldContent)
    layout:add_view(foldContainer)
    
    -- 边框容器
    local borderContainer = snowGui.border_container:new({
        width = 620,
        height = 100,
        layout_weight = 0,
        layout_margin = 5,
        borderColor = {0.3, 0.3, 0.8, 1}
    })
    
    local borderContent = snowGui.text:new({
        text = "带边框的容器组件",
        textSize = 14,
        x = 10,
        y = 10
    })
    borderContainer:add_view(borderContent)
    layout:add_view(borderContainer)
    
    container:add_view(layout)
    return container
end

-- 创建性能测试标签页
function createPerformanceTestTab()
    local container = snowGui.frame_layout:new({
        width = 660,
        height = 400,
        backgroundColor = {1, 1, 1, 1}
    })
    
    local layout = snowGui.line_layout:new({
        x = 10,
        y = 10,
        width = 640,
        height = 380,
        orientation = "vertical",
        padding = 10
    })
    
    -- 标题
    local title = snowGui.text:new({
        text = "性能测试与监控",
        textSize = 18,
        height = 30,
        layout_weight = 0
    })
    layout:add_view(title)
    
    -- FPS显示
    local fpsText = snowGui.text:new({
        text = "FPS: --",
        textSize = 16,
        height = 30,
        layout_weight = 0,
        textColor = {0, 0.7, 0}
    })
    demoState.components.fpsText = fpsText
    layout:add_view(fpsText)
    
    -- 内存使用
    local memoryText = snowGui.text:new({
        text = "内存: --",
        textSize = 16,
        height = 30,
        layout_weight = 0,
        textColor = {0.7, 0, 0.7}
    })
    demoState.components.memoryText = memoryText
    layout:add_view(memoryText)
    
    -- 视图计数
    local viewCountText = snowGui.text:new({
        text = "视图数量: --",
        textSize = 16,
        height = 30,
        layout_weight = 0
    })
    demoState.components.viewCountText = viewCountText
    layout:add_view(viewCountText)
    
    -- 性能测试按钮
    local perfTestButton = snowGui.button:new({
        text = "运行压力测试",
        width = 200,
        height = 40,
        layout_margin = 10,
        backgroundColor = {0.8, 0.3, 0.3, 1}
    })
    
    function perfTestButton:on_click()
        runStressTest()
    end
    
    layout:add_view(perfTestButton)
    
    -- 清理按钮
    local clearButton = snowGui.button:new({
        text = "清理测试视图",
        width = 200,
        height = 40,
        layout_margin = 5,
        backgroundColor = {0.3, 0.7, 0.3, 1}
    })
    
    function clearButton:on_click()
        clearStressTest()
    end
    
    layout:add_view(clearButton)
    
    container:add_view(layout)
    return container
end

-- 创建调试面板
function createDebugPanel()
    local debugPanel = snowGui.window:new({
        x = 10,
        y = 10,
        width = 300,
        height = 150,
        text = "性能监控",
        backgroundColor = {0.1, 0.1, 0.15, 0.9},
        visible = demoState.showDebug
    })
    
    local debugLayout = snowGui.line_layout:new({
        x = 10,
        y = 40,
        width = 280,
        height = 100,
        orientation = "vertical"
    })
    
    local fpsDebug = snowGui.text:new({
        text = "FPS: --",
        textSize = 14,
        textColor = {0, 1, 0},
        height = 25
    })
    demoState.components.fpsDebug = fpsDebug
    
    local memDebug = snowGui.text:new({
        text = "内存: --",
        textSize = 14,
        textColor = {1, 1, 0},
        height = 25
    })
    demoState.components.memDebug = memDebug
    
    local updateDebug = snowGui.text:new({
        text = "更新时间: --",
        textSize = 14,
        textColor = {0.5, 0.5, 1},
        height = 25
    })
    demoState.components.updateDebug = updateDebug
    
    debugLayout:add_view(fpsDebug)
    debugLayout:add_view(memDebug)
    debugLayout:add_view(updateDebug)
    debugPanel:add_view(debugLayout)
    
    gui:add_view(debugPanel)
end

-- 运行压力测试
function runStressTest()
    CustomPrint:add_message("开始压力测试...")
    
    -- 创建大量视图
    for i = 1, 100 do
        local x = math.random(100, 600)
        local y = math.random(100, 400)
        local size = math.random(10, 30)
        
        local testView = snowGui.view:new({
            x = x,
            y = y,
            width = size,
            height = size,
            backgroundColor = {
                math.random(),
                math.random(),
                math.random(),
                0.7
            }
        })
        
        gui:add_view(testView)
        table.insert(demoState.components, testView)
    end
    
    CustomPrint:add_message(string.format("创建了 100 个测试视图"))
end

-- 清理压力测试
function clearStressTest()
    local count = 0
    for i = #demoState.components, 1, -1 do
        local comp = demoState.components[i]
        if comp.type == "view" then
            if comp.gui then
                gui:remove_view(comp)
            end
            table.remove(demoState.components, i)
            count = count + 1
        end
    end
    CustomPrint:add_message(string.format("清理了 %d 个测试视图", count))
end

-- 更新性能统计
local updateTimer = 0
function updatePerformanceStats(dt)
    updateTimer = updateTimer + dt
    
    if updateTimer >= 0.5 then
        updateTimer = 0
        
        -- FPS
        local fps = love.timer.getFPS()
        if demoState.components.fpsText then
            demoState.components.fpsText.text = string.format("FPS: %d", fps)
        end
        if demoState.components.fpsDebug then
            demoState.components.fpsDebug.text = string.format("FPS: %d", fps)
        end
        
        -- 内存
        local memKB = collectgarbage("count")
        local memMB = memKB / 1024
        if demoState.components.memoryText then
            demoState.components.memoryText.text = string.format("内存: %.2f MB", memMB)
        end
        if demoState.components.memDebug then
            demoState.components.memDebug.text = string.format("内存: %.2f MB", memMB)
        end
        
        -- 视图计数
        local viewCount = 0
        for _ in pairs(gui.views) do
            viewCount = viewCount + 1
        end
        if demoState.components.viewCountText then
            demoState.components.viewCountText.text = string.format("视图数量: %d", viewCount)
        end
    end
end

--迭代
function love.update(dt)
    demoState.animationTime = demoState.animationTime + dt
    
    gui:update(dt)
    debugGraph:update(dt)
    CustomPrint:update(dt)
    
    updatePerformanceStats(dt)
end

--绘图
function love.draw()
    love.graphics.clear(0.9, 0.9, 0.92) -- 浅灰色背景
    gui:draw()
    
    love.graphics.setColor({0, 0, 0})
    debugGraph:draw()
    CustomPrint:draw()
end

--键盘输入
function love.keypressed(key)
    if key == "f1" then
        demoState.showDebug = not demoState.showDebug
        -- 切换调试面板可见性
    elseif key == "escape" then
        love.event.quit()
    end
    
    gui:keypressed(key)
end

--文字输入
function love.textinput(text)
    gui:textinput(text)
end

-- 平台适配
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
elseif love.system.getOS() == "Windows" then
    function love.mousemoved(x, y, dx, dy, istouch)
        gui:mousemoved(nil, x, y, dx, dy, istouch, nil)
    end

    function love.mousepressed(x, y, id, istouch, pressure)
        gui:mousepressed(id, x, y, nil, nil, istouch, pressure)
    end

    function love.mousereleased(x, y, id, istouch, pressure)
        gui:mousereleased(id, x, y, nil, nil, istouch, pressure)
    end

    function love.wheelmoved(x, y)
        gui:wheelmoved(nil, x, y)
    end
end

-- 窗口大小变化
function love.resize(width, height)
    gui:resize(width, height)
end

-- 退出清理
function love.quit()
    gui:quit()
end
