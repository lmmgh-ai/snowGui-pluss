local view = require (lumenGui_path .. ".view.view")
local gravity_layout = view:new()
gravity_layout.__index = gravity_layout

--[[
子视图属性
layout_gravity         = "top|left", --x|y方向重力
--center top left bottom right
--outside_top
--inner_top
--类比line_layout
layout_margin--子视图外边距限制
layout_margin_top
layout_margin_right
layout_margin_left
layout_margin_bottom
]]

function gravity_layout:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        text            = "gravity_layout",
        type            = "gravity_layout",
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.8, 0.8, 1, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 0.6, 0.6, 1, 1 },
        borderColor     = { 0, 0, 0, 1 },

        --
        x               = 0,
        y               = 0,
        width           = 50,
        height          = 50,
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

function gravity_layout:init()
    --  print(dump(self:gravity_string_analysis("a|b")))
end

function gravity_layout:draw()
    if not self.visible then return end
    -- 绘制按钮背景
    if self.isPressed then
        love.graphics.setColor(self.pressedColor)
    elseif self.isHover then
        love.graphics.setColor(self.borderColor)
    else
        love.graphics.setColor(self.backgroundColor)
    end
    --绘制边框
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    --绘制布局调试线
    love.graphics.line(self.x, self.y, self.x + self.width, self.y + self.height)
    love.graphics.line(self.x + self.width, self.y, self.x, self.y + self.height)
    -- 绘制文本
    love.graphics.setColor(self.textColor)
    local font = self:get_font(self.font, self.textSize)
    local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    love.graphics.print(self.text, self.x, self.y)
end

--重写添加子视图或子视图改变宽高后回调
function gravity_layout:change_from_self(child_view) --改变子视图数量后的回调 适用需要对子视图数量更新做出反应的视图
    --self:update_weiht()
    -- print(123)
    --初始化子视图外边框边界属性
    if child_view then
        --   self:init_child_layout_margin(child_view)
    end
    --更新重力
    self:update_gravity()
    return true, true --返回true 通知父视图子视图自身做出改变
end

--按指定间隔字符分割
function gravity_layout:string_segmentation(str, reps)
    local resultStrList = {}
    string.gsub(str, '[^' .. reps .. ']+', function(w)
        --table.insert(resultStrList, w)
        --resultStrList[w] = 0
        table.insert(resultStrList, w)
    end)
    return resultStrList
end

--将字字符串转化为顺序表(与line_layout有区别 这个要分先后顺序)
--前一个字符代表x,后一个字符代表y
--重力布局 用手将布局里的方块单个调整
function gravity_layout:gravity_string_analysis(str)
    -- body
    local str = string.lower(str) --将参数大写转为小写
    --[[
   {
        ["key"] = 0,
        ["key"] = 0,
    }
   ]]
    return self:string_segmentation(str, "|")
end

--全局重力
function gravity_layout:globe_gravity(str, on_view_n, ago_view_n)
    -- body

    --索引视图
    local children = self.children
    local on_view = children[on_view_n]
    local ago_view = children[ago_view_n]
    --
    --print(on_view_n, ago_view_n)
    if on_view_n == 1 then
        on_view.x = 0 --self.x + (self.width / 2) - on_view.width / 2
        on_view.y = 0 -- self.y + (self.height / 2) - (on_view.height / 2)
    end
    --布局内边框
    local padding_top = self.padding_top or 0
    local padding_bottom = self.padding_bottom or 0
    local padding_right = self.padding_right or 0
    local padding_left = self.padding_left or 0
    --自动小写
    local str = string.lower(str)
    --
    --center 无视视图刚体 强制子视图与布局同心
    if str == "center" then
        on_view.x = self.x + (self.width / 2) - on_view.width / 2
        on_view.y = self.y + (self.height / 2) - (on_view.height / 2)
    elseif str == "top" then
        local mx, my = 0, 0
        --扫描前进1
        for i = ago_view_n, 1, -1 do
            local view = children[i]
            --扫描前面视图

            if view.x < on_view.x + on_view.width and
                view.x + view.width > on_view.x then
                --print(i, view.type)
                local bottom = view.layout_margin_bottom or 0
                vmy = view.y + view.height + bottom
                if vmy > my then
                    my = vmy
                end
                -- print(vmy)
            end
        end
        print(my)
        local on_top = on_view.layout_margin_top or 0
        on_view.y = my + on_top
    elseif str == "bottom" then
        local mx, my = 0, 0
        for i = ago_view_n, 1, -1 do
            local view = children[i]
            --扫描前面视图
            if view.x < on_view.x + on_view.width and
                view.x + view.width > on_view.x then
                local top = view.layout_margin_top or 0
                vmy = view.y - top
                if vmy > my then
                    my = vmy
                end
            end
        end

        local on_bottom = on_view.layout_margin_bottom or 0
        on_view.y = my - on_bottom
    elseif str == "left" then
        local mx, my = 0, 0
        local vmx = 0
        for i = ago_view_n, 1, -1 do
            local view = children[i]
            --扫描前面视图
            if view.y < on_view.y + on_view.height and
                view.y + view.height > on_view.y then
                local right = view.layout_margin_right or 0
                vmx = view.x + view.width + right
                if vmx > mx then
                    my = vmy
                end
            end
        end

        local on_left = on_view.layout_margin_left or 0
        on_view.x = mx - on_left
    elseif str == "right" then
    else
        assert(false, "重力布局:字符解析失败 " .. str)
    end
    return true
end

--约束重力
function gravity_layout:constraint_gravity(str, on_view, ago_view)
    -- body
    --当前视图外边距
    local on_top = on_view.layout_margin_top or 0
    local on_bottom = on_view.layout_margin_bottom or 0
    local on_left = on_view.layout_margin_left or 0
    local on_right = on_view.layout_margin_right or 0
    --相对视图外边距
    local ago_top = ago_view.layout_margin_top or 0
    local ago_bottom = ago_view.layout_margin_bottom or 0
    local ago_left = ago_view.layout_margin_left or 0
    local ago_right = ago_view.layout_margin_right or 0
    --自动小写
    local str = string.lower(str)
    if str == "center" then
        on_view.x = ago_view.x + (ago_view.width / 2) - on_view.width / 2
        on_view.y = ago_view.y + (ago_view.height / 2) - (on_view.height / 2)
    elseif str == "inner_top" then
        on_view.y = ago_view.y
    elseif str == "outside_top" then
        on_view.y = ago_view.y - on_view.height - on_bottom - ago_top
    elseif str == "inner_bottom" then
        on_view.y = ago_view.y + ago_view.height - on_view.height
    elseif str == "outside_bottom" then
        on_view.y = ago_view.y + ago_view.height + on_top + ago_bottom
    elseif str == "inner_left" then
        on_view.x = ago_view.x
    elseif str == "outside_left" then
        on_view.x = ago_view.x - on_view.width - on_right - ago_left
    elseif str == "inner_right" then
        on_view.x = ago_view.x + ago_view.width - on_view.width
    elseif str == "outside_right" then
        on_view.x = ago_view.x + ago_view.width + on_left + ago_right
    else
        assert(false, "重力布局:字符解析失败 " .. str)
    end
    return true
end

--更新重力
function gravity_layout:update_gravity()
    local children = self.children
    if #children < 1 then
        return
    end
    --
    local before_view = nil

    --
    --迭代子视图重力字符
    for i = 1, #children do
        local view = children[i]
        --
        if before_view then
            view.x = before_view.x + (before_view.width / 2) - view.width / 2
            view.y = before_view.y + (before_view.height / 2) - (view.height / 2)
        else
            view.x = 0
            view.y = 0
        end
        --

        if not view.layout_gravity then
            view.layout_gravity = "outside_bottom"
        end
        --print(view.layout_gravity)
        local layout_gravity = view.layout_gravity
        local g_t = self:gravity_string_analysis(layout_gravity)
        for _, str in ipairs(g_t) do
            -- if not self:globe_gravity(str, i, i - 1) then
            self:constraint_gravity(str, view, before_view or self)
            --  end
        end
        --self:constraint_gravity(view.layout_gravity, view, before_view)
        before_view = view
    end
end

function gravity_layout:on_click(id, x, y, dx, dy, is_touch, pre)
    -- body
    --self:destroy()
    print(self.type, self:get_local_Position(x, y))
end

return gravity_layout;
