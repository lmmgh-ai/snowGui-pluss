--这是添加view演示
--这是一个基本的演示库
local packages = require("packages")
local snowGui = packages.snowGui
local module_loader = packages.module_loader
--
local debugGraph = snowGui.debugGraph
local CustomPrint = snowGui.CustomPrint
local gui = snowGui:new()

--初始化
function love.load(...)
    debugGraph:load(...)
    CustomPrint:load()

    --view具有父子关系

    --解析式添加视图
    --解析式 type严格模式
    --解析式视图需要将对应添加到API
    -- button = button
    lay = {
        type = "border_container",
        width = "300",
        height = "300"
    }
    --local bc = gui:add_view(gui:load_layout(lay))
    local border_container = snowGui.border_container
    local bc = gui:add_view(border_container:new({
        width = "300",
        height = "300"
    }))
    bc:add_page_view("main", gui:load_layout({
        type = "list",
        items = {
            { text = "button" },
            { text = "edit_text" },
            { text = "image" },
            { text = "list" },
            { text = "select_button" },
            { text = "slider" },
            { text = "select_menu" },
            { text = "text" },
        }
    }))
    bc:add_page_view("left", gui:load_layout({
        type = "list",
        items = {
            { text = "button" },
            { text = "edit_text" },
            { text = "image" },
            { text = "list" },
            { text = "select_button" },
            { text = "slider" },
            { text = "select_menu" },
            { text = "text" },
        }
    }))
    bc:add_page_view("right", gui:load_layout({
        type = "list",
        --  x = 100,
    }))
    bc:add_page_view("bottom", gui:load_layout(
        {
            type = "line_layout",
            width = "fill",
            height = 300,
            {
                type = "button",
            },
            {
                type = "list",
                items = {
                    { text = "button" },
                    { text = "edit_text" },
                    { text = "image" },
                    { text = "list" },
                    { text = "select_button" },
                    { text = "slider" },
                    { text = "select_menu" },
                    { text = "text" },
                }
            },
            {
                type = "fold_container",
                text = "views",
                {
                    type = "button",
                },
                --[[
                {
                    type = "list",
                    items = {
                        { text = "button" },
                        { text = "edit_text" },
                        { text = "image" },
                        { text = "list" },
                        { text = "select_button" },
                        { text = "slider" },
                        { text = "select_menu" },
                        { text = "text" },
                    },
                    item_on_click = function(self, count, text) --元素点击事件
                        local view = require("view." .. text)
                        print(s2g.scene_gui:add_view(view:new()))
                    end
                }]]
            },

            {
                type = "fold_container",
                text = "layout",
                {
                    type = "list",
                    items = {
                        { text = "line_layout" },
                        { text = "frame_layout" },
                        { text = "grid_layout" },
                        { text = "gravity_layout" },
                    },
                    item_on_click = function(self, count, text) --元素点击事件
                        local view = require("layout." .. text)
                        print(s2g.scene_gui:add_view(view:new()))
                    end
                }
            },
            {
                type = "fold_container",
                text = "container",
                {
                    type = "list",
                    items = {
                        { text = "border_container" },
                        { text = "fold_container" },
                        { text = "slider_container" },
                        { text = "tab_control" },
                        { text = "title_menu" },
                        { text = "tree_manager" },
                        { text = "window" },
                    },
                    item_on_click = function(self, count, text) --元素点击事件
                        local view = require("container." .. text)
                        print(s2g.scene_gui:add_view(view:new()))
                    end
                }
            },

        }
    ))
    --print(dump(gui:load_layout(lay)))
    -- print(gui:add_view(gui:load_layout(lay)))
end

--迭代
function love.update(dt)
    gui:update(dt)
    debugGraph:update(dt)
    CustomPrint:update(dt)
end

--绘图
function love.draw()
    love.graphics.clear(1, 1, 1) -- 白色背景
    gui:draw()
    --
    love.graphics.setColor({ 0, 0, 0 })
    debugGraph:draw()
    CustomPrint:draw()
end

--键盘输入
function love.keypressed(key)
    gui:keypressed(key)
end

--文字输入
function love.textinput(text)
    gui:textinput(text)
end

--适应两个平台的api 其实是触摸与鼠标输入的区别
if love.system.getOS() == "Android" then
    function love.touchpressed(id, x, y, dx, dy, pressure) --触摸按下
        --  print((tostring(id)=="userdata: NULL"))
        --print((tostring(id)=="userdata: 0x00000001"))
        -- print(love.getVersion())
        gui:touchpressed(id, x, y, dx, dy, true, pressure)
    end

    function love.touchmoved(id, x, y, dx, dy, pressure) --触摸滑动
        gui:touchmoved(id, x, y, dx, dy, true, pressure)
    end

    function love.touchreleased(id, x, y, dx, dy, pressure) --触摸抬起
        gui:touchreleased(id, x, y, dx, dy, true, pressure)
    end
elseif love.system.getOS() == "Windows" then
    function love.mousemoved(x, y, dx, dy, istouch) --鼠标滑动
        gui:mousemoved(nil, x, y, dx, dy, istouch, nil)
    end

    function love.mousepressed(x, y, id, istouch, pressure) --pre短时间按下次数 模拟双击
        gui:mousepressed(id, x, y, nil, nil, istouch, pressure)
    end

    function love.mousereleased(x, y, id, istouch, pressure) --pre短时间按下次数 模拟双击
        gui:mousereleased(id, x, y, nil, nil, istouch, pressure)
    end

    function love.wheelmoved(x, y)
        gui:wheelmoved(nil, x, y)
    end
end


--退出程序 exit
function love.quit()
    gui:quit()
end

--拖入文件目录到窗口
function love.directorydropped(path)
    gui:directorydropped(path)
end

--拖入文件到窗口
function love.filedropped(file)
    gui:filedropped(file)
end

--窗口显示状态 (判断屏幕方向)
function love.visible(v)
    gui:visible(v)
    --  print(v)
    --print(v and "Window is visible!" or "Window is not visible!");
end

--窗口大小变化
function love.resize(width, height)
    gui:resize(width, height)
end

--用户最小化窗口/取消最小化窗口回调
function love.visible(is_small)
    gui:visible(is_small)
    -- body
end
