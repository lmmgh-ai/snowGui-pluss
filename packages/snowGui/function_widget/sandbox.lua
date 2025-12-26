local view = require(lumenGui_path .. ".view.view")
local sandbox = view:new()
sandbox.__index = sandbox
function sandbox:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type            = "sandbox", --类型
        text            = "sandbox",
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.8, 0.8, 1, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 0.6, 0.6, 1, 1 },
        borderColor     = { 0, 0, 0, 1 },
        --
        lua_code        = "",      --加载代码 优先级
        lua_path        = "1.lua", --脚本路径
        env             = nil,     --虚拟环境
        --
        x               = 0,
        y               = 0,
        width           = 200,
        height          = 200,
        --
        parent          = nil, --父视图
        name            = "",  --以自己内存地址作为唯一标识
        id              = "",  --自定义索引
        children        = {},  -- 子视图列表
        _layer          = 1,   --图层
        _draw_order     = 1,   --默认根据 数值越大在当前图层越在前(目前视图在图层1起作用)
        gui             = nil, --管理器索引
    }
    --扫描 将属性挪移到 新对象
    for i, c in pairs(tab or {}) do
        new_obj[i] = c;
    end
    --继承视图
    new_obj.__index = new_obj;
    setmetatable(new_obj, self)
    --执行初始属性函数
    new_obj:_init()
    --返回新对象
    return new_obj;
end

--如果返回值为true 则事件下传递
--默认不传递
function sandbox:change_from_parent(parent)
    -- body
    --获取父视图 宽高 防止父视图是window 将自身当做参数传输
    local width, height = parent:get_wh(self)
    self.width = width
    self.height = height
    return false
end

local default_code = [[


--print(load)
if layout then
  gui:add_view(gui:load_layout(load(layout)()))
end
function love.draw()
    --love.graphics.rectangle("fill", 0, 0, 20, 20, 5)
    gui:draw()
end

function love.update(dt)
    gui:update(dt)
end

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

function love.keypressed(key)
     gui:keypressed(key)
end

--键盘输入文本回调(键盘事件后)
function love.textinput(text)
    gui:textinput(text)
end
]]


local function createAdvancedSandbox(env)
    local env = env or {}

    -- 白名单：只允许安全的函数和模块
    local whitelist = {
        -- 基础类型
        type = type,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        tonumber = tonumber,
        tostring = tostring,
        print = print,
        -- 安全模块（可选择性开放）
        math = math,
        string = string,
        table = table,
        love = {
            graphics = love.graphics,
        },
        gui = require(lumenGui_path .. ".gui"):new(),
        File = File, --文件系统
        require = require,
        dump = dump,
        load = load
    }

    -- 设置环境
    setmetatable(env, {
        __index = function(t, k)
            return whitelist[k]
        end,
        __newindex = function(t, k, v)
            -- error("不允许修改沙盒环境", 2)
            whitelist[k] = v;
        end
    })

    return env
end

function sandbox:init()
    self.env = createAdvancedSandbox(self.env or {})
    --a, b = load(love.filesystem.read("1.lua"), nil, nil, self.env)()
    -- 设置超时保护
    local code = ""
    if #self.lua_code > 3 then
        code = self.lua_code
    else
        code = love.filesystem.read(self.lua_path)
    end
    local co = coroutine.create(function()
        local func, err = load(default_code, "sandbox_code", "t", self.env)
        if not func then
            print("编译错误: " .. err)
            return nil, "编译错误: " .. err
        end

        -- 使用pcall保护执行
        local success, result = pcall(func)
        if success then
            return result
        else
            print("运行时错误: " .. result)
            return nil, "运行时错误: " .. result
        end
    end)
    local success, result = coroutine.resume(co)
    if success then
        return result
    else
        print("执行错误: " .. result)
        return nil, "执行错误: " .. result
    end
end

function sandbox:update(dt)
    if not self.visible then return end
    local env_love = self.env.love
    if env_love.update then
        env_love.update(dt)
    end
end

function sandbox:draw()
    if not self.visible then return end
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    --开启剪裁
    local x, y = self:get_world_Position(self.x, self.y)
    love.graphics.setScissor(x, y, self.width, self.height)
    local env_love = self.env.love
    if env_love.draw then
        love.graphics.setColor(0, 0, 0)
        env_love.draw()
    end
    --关闭剪裁
    love.graphics.setScissor()
    -- 绘制文本
    love.graphics.setColor(self.textColor)
    local font = self:get_font(self.font, self.textSize)
    local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    love.graphics.print(self.text, self.x + (self.width - textWidth) / 2, self.y + (self.height - textHeight) / 2)
end

function sandbox:on_click(id, x, y, dx, dy, istouch, pressure)
    -- body
    --self:destroy()
    -- print(self.type, self:get_local_Position(x, y))
end

------------------------------------------
--输入回调 在获取[焦点][输入权限][锁定点击]
function sandbox:mousemoved(id, x, y, dx, dy, istouch, pressure) --滑动回调
    local x1, y1 = self:get_local_Position(x, y)
    local env_love = self.env.love
    if env_love.mousemoved then
        env_love.mousemoved(x1, y1, dx, dy, istouch)
        return
    end
    if env_love.touchmoved then
        env_love.touchmoved(id, x1, y1, dx, dy, pressure)
        return
    end
end

--按下
function sandbox:mousepressed(id, x, y, dx, dy, istouch, pressure) --pre短时间按下次数 模拟双击
    local x1, y1 = self:get_local_Position(x, y)
    local env_love = self.env.love
    if env_love.mousepressed then
        env_love.mousepressed(x1, y1, id, istouch, pressure)
        return
    end
    if env_love.touchpressed then
        env_love.touchpressed(id, x1, y1, dx, dy, pressure)
        return
    end
end

--抬起
function sandbox:mousereleased(id, x, y, dx, dy, istouch, ppressurere) --pre短时间按下次数 模拟双击
    local x1, y1 = self:get_local_Position(x, y)
    local env_love = self.env.love
    if env_love.mousereleased then
        env_love.mousereleased(x1, y1, id, istouch, pressure)
        return
    end
    if env_love.touchreleased then
        env_love.touchreleased(id, x1, y1, dx, dy, pressure)
        return
    end
end

--滚轮滑动
function sandbox:wheelmoved(id, x, y)
    -- body
    local env_love = self.env.love
    if env_love.wheelmoved then
        env_love.wheelmoved(x, y)
    end
end

--键盘按下回调
function sandbox:keypressed(key)
    local env_love = self.env.love
    if env_love.keypressed then
        env_love.keypressed(key)
    end
end

--键盘输入文本回调(键盘事件后)
function sandbox:textinput(text)
    local env_love = self.env.love
    if env_love.textinput then
        env_love.textinput(text)
    end
end

return sandbox;
