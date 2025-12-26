--这是一个基本的演示库
local packages = require("packages")
local snowGui = packages.snowGui
local module_loader = packages.module_loader
--
local debugGraph = snowGui.debugGraph
local CustomPrint = snowGui.CustomPrint
local gui = snowGui:new()
local File = snowGui.nativefs
--
--初始化
function love.load(...)
    debugGraph:load(...)
    CustomPrint:load()

    --布局开始
    --初始化gui编辑控件
    --用面向对象的创建方式 便于其他控件操作它
    local s2g = snowGui.scene_2D_guiEditor:new({ width = "fill", height = 300 })
    --local s2d = snowGui.scene_2D:new({ width = "fill", height = 200 })
    --主要布局
    local main_lay = {
        type = "line_layout",
        width = "fill",
        height = "fill",
        --gravity = "center",
        --顶栏菜单控件
        {
            type = "title_menu",
            items = {
                {
                    text = "文件",
                    items = {
                        { text = "新建文件" },
                        { text = "打开" },
                        { text = "另存为.." },
                        { text = "保存" }
                    },
                },
                {
                    text = "视图1",
                },
                { text = "查看" },
                {
                    text = "运行",
                    items = {
                        {
                            text = "window run",
                            on_click = function(self, gui)
                                local lay_data = "return" .. (s2g.scene_gui:views_out_to_layout())
                                -- print(lay_data)
                                gui:add_view(gui:load_layout(
                                    {
                                        type = "window",
                                        title = "sandbox_window",
                                        {
                                            type = "sandbox",
                                            env = {
                                                layout = lay_data
                                            },

                                        }
                                    }
                                ))
                            end
                        },
                        {
                            text = "new Love2d run",
                            on_click = function(self, gui)
                                local lay_data = "layout=" .. (s2g.scene_gui:views_out_to_layout())
                                local path = "./project/scene/default/main.lua"
                                --写入到场景文件
                                File.write(path, lay_data)
                                --复制库gui库
                                File.copyDirectory("./packages", "./project/packages")
                                --调用love运行某文件
                                --默认运行当前
                                os.execute("start  love ./project/")
                            end

                        }
                    }

                },
                {
                    text = "关于",
                    on_click = function(self, gui)
                        print("关于")
                    end
                },
                {
                    text = "退出",
                    on_click = function(self, gui)
                        --print(1)
                        love.event.quit()
                    end
                },
            },
        }
    }
    --最底层的线性布局
    local lin = gui:add_view(gui:load_layout(main_lay))
    --将布局编辑器添加到布局
    lin:add_view(s2g)

    --添加选项
    lin:add_view(gui:load_layout(
        {
            type = "line_layout",
            width = "fill",
            orientation = "horizontal", --horizontal
            {
                type = "edit_text"
            },
            {
                type = "fold_container",
                text = "views",
                {
                    type = "list",
                    items = {
                        { text = "button" },
                        { text = "edit_text" },
                        { text = "image" },
                        { text = "input_text" },
                        { text = "list" },
                        { text = "select_button" },
                        { text = "slider" },
                        { text = "select_menu" },
                        { text = "text" },
                    },
                    item_on_click = function(self, count, text) --元素点击事件
                        print(s2g.scene_gui:add_view(gui:load_layout({ type = text })))
                    end
                }
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
                        print(s2g.scene_gui:add_view(gui:load_layout({ type = text })))
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
                        print(s2g.scene_gui:add_view(gui:load_layout({ type = text })))
                    end
                }
            },

        }
    ))
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
