--[[
框架名称:lumingGui
框架简称:lmGui
作者:北极企鹅
事件:2025
]]

local color = require(lumenGui_path .. ".libs.Color.Color")

-- 基础view类
local view = {
    type             = "view", --类型
    text             = "view",
    x                = 0,
    y                = 0,
    width            = 0,
    height           = 0,
    visible          = true,                 --是否可见
    isHover          = false,                --是否获取焦点(鼠标悬浮在控件上 强制获取焦点)
    isPressed        = false,                --是否点击
    isDragging       = false,                --是否拖动(点击后的滑动)
    --颜色
    hoverColor       = { 0.8, 0.8, 1, 1 },   --获取焦点颜色
    pressedColor     = { 0.6, 0.6, 1, 0.8 }, --点击时颜色
    backgroundColor  = { 0.6, 0.6, 1, 1 },   --背景颜色
    borderColor      = { 0, 0, 0, 1 },       --边框颜色
    textColor        = { 0, 0, 0 },          --统一字体颜色
    textSize         = 10,                   --统一字体大小
    --必须重写部分
    font             = "default",            --字体
    parent           = nil,                  --父视图
    name             = "",                   --以自己内存地址作为唯一标识
    id               = "",                   --自定义索引
    children         = {},                   -- 子视图列表
    _layer           = 1,                    --图层
    _draw_order      = 1,                    --父视图图层索引
    gui              = nil,                  --管理器索引
    events_system    = nil,                  --事件系统索引
    ---交互扩展
    --扩展虚拟宽高
    is_extension     = false, --是否扩展状态 点击视图判断使用扩展宽高判断
    extension        = {},    --扩展点击区域 可以是表 是对象
    extension_x      = 0,     --扩展的坐标
    extension_y      = 0,
    extension_width  = 0,
    extension_height = 0,
}
view.__index = view

-- 构造函数 这些属性 可以被继承
function view:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        parent      = nil, --父视图
        name        = "",  --以自己内存地址作为唯一标识
        id          = "",  --自定义索引
        children    = {},  -- 子视图列表
        _layer      = 1,   --图层
        _draw_order = 1,   --默认根据 数值越大在当前图层越在前(目前视图在图层1起作用)
        gui         = nil, --管理器索引
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

--将自身导出为可加载table 可以直接被new创建
--包含子视图
--系统级
function view:out_to_table()
    local out_table = {}
    local no_value = {
        "__index",
        "_layer",
        "_draw_order",
        "gui",
        "parent",
        "children",
        "name",
        "isHover",
        "isPressed",
        "isDragging",
        "font",
        "events_system",
    }
    --不复制的属性 函数默认不复制
    local function scan(value)
        for i, str in pairs(no_value) do
            if str == value then
                return false
            end
        end
        return true
    end

    --扫描所有的属性复制到新表
    for i, value in pairs(self) do
        if scan(i) then --确认属性可复制
            if type(value) == "function" then
            elseif type(value) == "table" then
                --颜色代码rgb转化16进制
                if string.find(i, "Color") or string.find(i, "color") then
                    out_table[i] = color.RGBA_To_HEX(value)
                else
                    if not self.children then
                        self:self_to_table(i, value, out_table)
                    end
                end
            elseif type(value) == "string" or type(value) == "number" or type(value) == "boole" then
                out_table[i] = value
            else
                --调用自定义属性输出
                self:self_to_table(i, value, out_table)
            end
        end
    end
    --单独扫描子视图
    if self.children then
        -- print("扫描子视图")
        for _, child in ipairs(self.children) do
            print("child", child.type)
            local ta = child:out_to_table()
            table.insert(out_table, ta)
        end
    end

    return out_table
end

--其余视图自定义输出视图
--默认只输出字符 数字 布尔
--一些自定义属性需要重写此函数输出
function view:self_to_table(key, value, out_table)

end

--系统级函数 处理视图统一属性
--在新视图对象被创建 并完成继承 后执行 主要用于初始视图部分属性
--无法获取父视图
function view:_init()
    -- body
    --扫描自身 初始化一些无依赖基本属性
    for i, value in pairs(self) do
        --将自身hex颜色转换为Rgb
        --颜色代码rgb转化16进制
        if string.find(i, "Color") or string.find(i, "color") then
            if type(value) == "string" then
                --print(value)
                self[i] = color.HEX_To_RGBA(value)
            end
        end
    end

    return self:init()
end

--视图级函数 可重写
--在新视图对象被创建 并完成继承 后执行 主要用于初始视图部分属性
--无法获取父视图
function view:init()
    --
end

--当被添加到gui系统后回调
--可以访问gui与parent
function view:_on_create()
    --字符串参数解析为绝对值
    self:init_string_module()
    --初始化宽高
    if rawget(self, "width") then
    end
    if rawget(self, "height") then
    end
    return self:on_create()
end

function view:on_create()
end

--将视图百分比字符串属性转换为绝对值
function view:string_to_number(key)
    local parent = self:get_parent()
    local p_w, p_h
    --不存在父视图 返回窗口视图
    if parent then
        --父视图尺寸
        p_w, p_h = self:get_parent_wh()
    else
        p_w, p_h = self:get_window_wh()
    end
    --print(p_w, view.type)
    assert(type(p_w) == "number", "字符错误 p_w" .. self.type)
    assert(type(p_h) == "number", "字符错误 p_h" .. self.type)
    --窗口尺寸
    local window_w, window_h = self:get_window_wh()
    local value = string.lower(self[key])
    --print(value)
    if string.find((value), "%%") then --解析百分比符号
        local rate = tonumber(string.match(value, "(.-)%%")) / 100
        --比值对象 强制转化小写
        local rate_obj = string.match(value, "%%(.+)")
        --"100%ww"
        -- print(rate, rate_obj)
        if rate_obj == "ww" then     --百分比窗口
            self[key] = math.floor(window_w * rate)
        elseif rate_obj == "wh" then --百分比窗口
            self[key] = math.floor(window_h * rate)
        elseif rate_obj == "pw" then --百分比父布局
            self[key] = math.floor(p_w * rate)
        elseif rate_obj == "ph" then --百分比父布局
            self[key] = math.floor(p_h * rate)
        else
            local parent = self:get_parent()
            --直接访问变量风险代码
            self[key] = parent[key]
        end
        -- print(比值)
    elseif tonumber(value) then --字符串数字
        -- print(value)
        self[key] = tonumber(value)
    elseif value == "fill" then --充满父布局
        if key == "width" then
            self[key] = p_w
        elseif key == "height" then
            self[key] = p_h
        end
    else
        self[key] = 100
    end
end

--新对象 可以访问父类后初始化字符属性
--通常是用table转换为对象时有用
--如果对象导出到table 宽高通常为绝对值
function view:init_string_module()
    --local parent = self:get_parent()
    --父视图尺寸
    -- local p_w, p_h = parent:get_wh()
    --窗口尺寸
    -- local window_w, window_h = love.window.getMode()
    if type(self.width) == "string" then
        self:string_to_number("width")
        -- print(self.type)
    end
    if type(self.height) == "string" then
        self:string_to_number("height")
    end
end

-- 设置位置
--这些函数主要为了触发各种回调而设立
--他们具有安全性
--
function view:setPosition(x, y)
    self.x = x
    self.y = y
    self:_change_from_self(nil)
end

function view:move_Position(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
    self:_change_from_self(nil)
end

-- 设置尺寸
function view:set_width(width)
    self.width = width
    self:_change_from_self(nil)
end

function view:set_height(height)
    self.height = height
    self:_change_from_self(nil)
end

function view:set_wh(width, height)
    self.width  = width
    self.height = height
    self:_change_from_self(nil)
end

-- 获取自身尺寸
function view:get_wh()
    return self.width, self.height
end

-- 获取所在父视图尺寸
function view:get_parent_wh()
    local parent = self:get_parent();
    return parent:get_wh(self)
end

--获取窗口尺寸
function view:get_window_wh()
    return self.gui:get_window_wh()
end

-- 添加子视图
function view:add_view(child_view)
    --

    local name = tostring(child_view) --以自己地址为唯一标识
    child_view.name = name;           --设置唯一标识
    --初始化可见 跟随父视图
    child_view.visible = self.visible
    --添加到父视图
    table.insert(self.children, child_view)
    --
    child_view.parent = self;            --为chlid赋值父视图
    child_view._layer = self._layer + 1; --设置图层为父视图下一层
    -- print(self.type)
    --自身存在布局管理器索引
    --不存在可能加载了一个布局
    if self.gui then
        child_view.gui = self.gui;
        self.gui:add_view(child_view) --添加到视图管理器
        --自身尺寸改变回调
        self:_change_from_self(child_view)
    end
    return child_view
end

--子视图发生尺寸变化
--子视图添加 删除生命周期发生时调用
--通常父视图要对子视图做出反应时被调用
--父视图是响应者
--当视图需要响应子视图对自己做出改变时
function view:_change_from_children(child_view)
    -- body
    if self:change_from_children(child_view) then
        --向上通知
        if self.parent then
            return self.parent:change_from_children(self)
        end
    end
end

--如果返回值为true 则事件向上传递
--默认不传递
function view:change_from_children(child_view)
    -- body
    --print(self.type)
    return false
end

--父视图改变子视图位置 尺寸时调用
--子视图是响应者
--当视图需要响应父视图对自己做出的改变时
function view:_change_from_parent(parent)
    -- body
    if self:change_from_parent(parent) then
        --向下传递
        if #self.children > 0 then
            for _, child in ipairs(self.children) do
                child:_change_from_parent(self)
            end
        end
    end
end

--如果返回值为true 则事件下传递
--默认不传递
function view:change_from_parent(parent)
    -- body
    return false
end

--添加视图自身改变回调
--当视图响应自身
function view:_change_from_self(child_view)
    local is_p, is_c = self:change_from_self(child_view)
    if is_p then
        --print("123", self.parent)
        if self.parent then
            self.parent:_change_from_children(self)
        end
    end
    if is_c then
        --因为改变了子视图尺寸 调用他们改变回调
        for _, child in ipairs(self.children) do
            child:_change_from_parent(self)
        end
    end
end

--如果返回值为true 则通知父视图与子视图
--默认不通知 只有需要响应手动通知
function view:change_from_self(child_view)
    --
    --print(1)
    --返回两个参数 true通知父布局更新 true通知子视图更新
    return true, false;
end

--设置视图可见
function view:set_visible(val)
    if val == true or val == false then
        self.visible = val;
        if self.children then --存在子视图
            for i, child in pairs(self.children) do
                child:set_visible(val)
            end
        end
    end
end

--设置全部子视图可见
function view:set_children_visible(val)
    if self.children then --存在子视图
        for i, child in pairs(self.children) do
            child:set_visible(val)
        end
    end
end

--将自身置顶 获取输入焦点 绘图顶层
--!如果是底层视图 绘图顶层 如果是拥有父视图的视图 将在父视图绘制队列置顶
function view:set_hover_view()
    -- print(self._layer)
    if self._layer == 1 then --顶层图层
        return self.gui:set_hover_view(self)
    else
        self._draw_order = 2 --赋予绘图等级
        --排序
        table.sort(self.parent.children, function(a, b)
            --print(a._layer, b._layer)
            return a._draw_order < b._draw_order
        end) --排序
    end
end

--销毁视图自身
function view:destroy()
    self:set_visible(false); --自身不可见
    local gui = self.gui;
    local name = self.name;
    if view.id and view.id ~= "" then
        gui.views[view.id] = nil --全体视图索引清空
    else
        gui.views[name] = nil    --全体视图索引清空
    end


    --清除图层索引
    local views = gui.tree_views[self._layer]
    for i, view in ipairs(views) do
        if view == self then
            views[#views], views[i] = views[i], views[#views]
            table.remove(views, #views)
            break
        end
    end
    if self.parent then --存在父视图
        for i, c in ipairs(self.parent) do
            if self.parent == c then
                self.parent[i] = nil --取消索引
            end
        end
    end
    if self.chliden then
        for i, chlid in pairs(self.chliden) do
            chlid:destroy() --调用子视图清除函数
        end
    end
    -- body
end

--gui编辑常用函数
--------------------------------------------------------
-- 从父视图中移除索引
function view:remove_form_parent()
    --存在父视图
    --通常只有最底层视图不存在父视图
    local parent = self:get_parent()
    local children = parent.children
    for i, child in ipairs(children) do
        if child == self then
            children[#children], children[i] = children[i], children[#children]
            table.remove(children, #children)
            break
        end
    end
    self.parent = nil
    return true
end

-- 移除所有子视图索引
function view:remove_all_children()
    self.children = {}
    return true
end

--获取父视图
function view:get_parent()
    return self.parent
end

--获取子视图集
function view:get_children()
    return self.children
end

--切换父视图
function view:change_parent(new_parent)
    self.x = 0
    self.y = 0
    --改变图层树
    -- self._layer = view._layer
    if new_parent then
        self:change_layer(new_parent._layer + 1)
    else --将试图浮动化 调整到图层1
        self:change_layer(1)
    end
    --存在父视图
    --通常只有最底层视图不存在父视图
    local parent = self:get_parent()
    if parent then
        --删除在父视图的索引与自身索引
        self:remove_form_parent()
        --旧父视图执行改变回调
        parent:_change_from_self(self)
    end
    if new_parent then
        --赋值父视图
        self.parent = new_parent
        --为新父视图添加自身索引
        new_parent.children = new_parent.children or {}
        table.insert(new_parent.children, self)

        --新父视图执行改变回调
        new_parent:_change_from_self(self)
    end
end

--改变自身图层树
function view:change_layer(_layer)
    if self._layer == _layer then
    elseif self._layer == _layer == 1 then
        return
    end
    local gui = self.gui

    --调整图层树位置
    local tree_views = gui.tree_views[self._layer]
    -- gui.tree_views[_layer] = gui.tree_views[_layer] or {}
    for i, view in ipairs(tree_views) do
        if view == self then
            tree_views[#tree_views], tree_views[i] = tree_views[i], tree_views[#tree_views]
            table.remove(tree_views, #tree_views)
            --print(tree_views[i]==self)
            break
        end
    end

    --将自家添加到新图层树
    table.insert(gui.tree_views[_layer], self)
    --赋值新图层
    self._layer = _layer
    --子视图全部调整
    for _, child in ipairs(self.children) do
        child:change_layer(_layer + 1)
    end
end

--获取最顶层父视图
function view:getTopParent()
    local parent = self:get_parent()
    if parent then
        return parent:getTopParent()
    else
        return self
    end
end

--字体
-----------------------------------------------------
--获取指定大小字体对象1-100
function view:get_font(font_name, font_size)
    -- body
    return self.gui:get_font_manger():get_font(font_name, font_size)
end

--------------------------------------------------------------
--事件系统相关
function view:on_event(eventName, callback)
    -- body
    return self.events_system:subscribe(eventName, callback, false, self)
end

function view:once_event(eventName, callback)
    -- body
    return self.events_system:subscribe(eventName, callback, true, self)
end

function view:publish_event(eventName, ...)
    -- body
    return self.events_system:publish(eventName, ...)
end

function view:unsubscribeById(eventName, subId)
    return self.events_system:unsubscribeById(eventName, subId)
end

function view:un_event_self(eventName)
    return self.events_system:unsubscribeById(eventName, self)
end

--事件系统相关end
-----------------------------------------------------------
--坐标系相关 谨慎重写
----------------------------------------------------------------
--点是否在矩形内
--左上角矩形
function view.point_in_rect(x, y, rectX, rectY, width, height)
    return x >= rectX
        and x <= rectX + width
        and y >= rectY
        and y <= rectY + height
end

--获取自身绝对位置
function view:getAbsolutePosition()
    local absX, absY = self.x, self.y
    local parent = self.parent

    while parent do
        absX = absX + parent.x
        absY = absY + parent.y
        parent = parent.parent
    end

    return absX, absY
end

--事件拦截机制 如果此函数返回false 则输入事件不会传递给子视图
--通常用于 父视图区域外不会触发子视图情况
--返回true则不拦截
--gui调用检测 child 为空 子视图调用检测 child为子视图本身
function view:_event_intercept(x, y, child)
    return true
end

--全局点转换相对点 视图判断时会调用
function view:get_local_Position(x, y, child)
    local parent = self.parent
    local x1 = x - self.x
    local y1 = y - self.y
    if parent then
        return parent:get_local_Position(x1, y1, self)
    else
        return x1, y1;
    end
end

--相对点转换全局点
function view:get_world_Position(x, y, child)
    local parent = self.parent
    local x1 = x + self.x
    local y1 = y + self.y

    if parent then
        return parent:get_world_Position(x1, y1, self)
    else
        return x1, y1;
    end
end

-- 检测点全局点是否在视图内
-- 判断鼠标是否在视图内使用此的此函数
function view:containsPoint(x, y)
    --local absX, absY = self:get_world_Position(0, 0, self)
    local x1, y1 = self:get_local_Position(x, y, self)
    --print(self.type, x1, y1)
    --父视图可以回传空参数 拦截点击事件
    if x1 and y1 then
        return x1 >= 0 and x1 <= self.width and
            y1 >= 0 and y1 <= self.height
    else
        return false
    end
    return nil
end

--绘图函数 谨慎重写
--------------------------------------------------------------
--迭代子类函数 非专业勿动
function view:_draw()
    if self.visible then
        -- print(self.type)
        --  print(self.type, self.font)

        local font = self:get_font(self.font, self.textSize)
        love.graphics.setFont(font)
        self:draw()
        -- 绘制子视图
        --绘图偏移
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        --开启剪裁
        --love.graphics.setScissor(self.x, self.y, self.width, self.height)
        for i, child in ipairs(self.children) do
            --print(i)
            child:_draw()
        end
        --关闭剪裁
        --love.graphics.setScissor()
        love.graphics.pop()
    else
    end
end

--[[
function view:_get_self_viewport()

end

function view:_set_parent_viewport(x, y, width, height)

end
]]
--谨慎重写回调 (为视图失去焦点 获取焦点 获取输入提供支持)
---------------------------------------------------------------------
--鼠标移动
function view:_mousemoved(id, x, y, dx, dy, istouch, pre)
    --输入点转换相对输入点
    if self.isPressed then
        self.isDragging = true --拖动变量赋值
    end
    return self:mousemoved(id, x, y, dx, dy, istouch, pre)
end

--鼠标按下
function view:_mousepressed(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击
    self.isPressed = true                                   --点击变量赋值
    --输入点转换相对输入点
    -- print("点击", self.type)
    return self:mousepressed(id, x, y, dx, dy, istouch, pre)
end

--鼠标抬起
function view:_mousereleased(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击
    self.isPressed = false                                   --点击变量赋值
    self:mousereleased(id, x, y, dx, dy, istouch, pre)       --释放回调
    self.isDragging = false                                  --拖动赋值
    --输入点转换相对输入点
end

--滚轮滚动
function view:_wheelmoved(id, x, y) --滚轮滑动
    return self:wheelmoved(id, x, y)
end

--视图获取焦点
function view:_on_hover(id, x, y, dx, dy, istouch, pre) --获取焦点回调
    --self:_mousemoved(id, x, y, dx, dy, istouch, pre)
    self.isHover = true                                 --焦点变量赋值
    return self:on_hover()
end

--视图失去焦点
function view:_off_hover() --失去焦点回调
    -- return self:_mousemoved(id, x, y, dx, dy, istouch, pre)
    self.isHover = false   --焦点变量赋值
    self._draw_order = 1   --重新赋值绘图等级
    return self:off_hover();
end

--失去输入权限时执行回调
function view:_loss_keypressed()
    return self:loss_keypressed()
end

--视图点击
function view:_on_click(id, x, y, dx, dy, istouch, pre) --单击
    return self:on_click(id, x, y, dx, dy, istouch, pre);
end

--可重写回调 继承后改写的回调
-------------------------------------------------------------
-- 被操作时更新自己
function view:update(dt)
    -- body
end

--绘图函数
function view:draw()

end

--获取焦点回调
function view:on_hover()

end

--失去焦点回调 在输入release回调之后
function view:off_hover()
    -- print(1)
end

--输入回调 在获取[焦点][输入权限][锁定点击]
function view:mousemoved(id, x, y, dx, dy, istouch, pre) --滑动回调

end

--按下
function view:mousepressed(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击

end

--抬起
function view:mousereleased(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击

end

--滚轮滑动
function view:wheelmoved(id, x, y)
    -- body
end

--键盘按下回调
function view:keypressed(key)

end

--失去输入权限时执行回调
function view:loss_keypressed()

end

--键盘输入文本回调(键盘事件后)
function view:textinput(text)

end

--点击事件
function view:on_click(id, x, y, dx, dy, istouch, pre)
    --  print("点击", self)
    return true;
end

--长按
function view:on_long_click(self)
    return true;
end

--双击
function view:on_double_click(self)
    return true;
end

--其他回调
-----------------------------------
--拖入文件目录到真实窗口
function view:directorydropped(path)

end

--拖入文件到真实窗口
--鼠标操作模式
function view:filedropped(path)

end

return view;
