--[[
框架名称:lumenGui
框架简称:lmGui
作者:北极企鹅
时间:2025
]]
--设置包索引
if lumenGui_path == nil then
    lumenGui_path = (...):match("(.-)[^%.]+$")
end

lumenGui_FILE_PATH = debug.getinfo(1, 'S').source:match("^@(.+)/")
lumenGui_FILE_PATH = lumenGui_FILE_PATH == nil and "" or lumenGui_FILE_PATH
--引用外部索引 尽量降低耦合
local API = require(lumenGui_path .. ".API")
local events_system = API.events_system
--字体管理 单例模式
local font_manger = API.font_manger
local color = API.Color

--管理器
--默认 帧布局
local gui = {
    x = 0,
    y = 0,
    width = 500,
    height = 500,
    scale_x = 1,   --缩放
    scale_y = 1,   --缩放
    --
    scissors = {}, -- 裁剪栈
    scissor_label = nil,
    --
    id_views = {},                                               --索引列表
    views = setmetatable({}, { __mode = 'kv' }),                 --
    tree_views = { {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }, --按图层排序分布视图
    input_state = {
        layer = nil,                                             --焦点图层
        isPressed = false,                                       --点击
        --pressed_views 既可以当做按键选中索引 也可以当做按键按下判断
        pressed_views = {},                                      --选中的视图集合 十点触摸为10个
        isMoved = false,                                         --滑动
        hover_view = nil,                                        --焦点视图
        keypressed_view = nil,                                   --键盘锁定视图(暂时用这一个标识 文字输入与键盘未区分)
        --input_text_view = nil,                                   --文字输入视图
        --拖动文件系相关
        --is_input_file = false, --是否导入文件
        --is_directory = false,  --是否是文件目录
        --file_path = {},        --文件或目录集合
    },
    --会被所有gui引用
    font_manger = nil, --字体管理器
    font = nil,        --字体名称(管理器)
    --外部索引
    --订阅发布事件系统
    events_system = events_system:new()
}

gui.__index = gui;

--创建新
function gui:new(tab)
    --这种创建对象方式 保证一些独立属性因为继承问题不会共用
    local new_obj = {
        views = setmetatable({}, { __mode = 'kv' }),                 --
        tree_views = { {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }, --按图层排序分布视图
        input_state = {
            layer = nil,                                             --焦点图层
            isPressed = false,                                       --点击
            pressed_views = {},                                      --选中的视图集合 十点触摸为10个
            isMoved = false,                                         --滑动
            hover_view = nil,                                        --焦点视图
            keypressed_view = nil,                                   --键盘锁定视图(暂时用这一个标识 文字输入与键盘未区分)
            --input_text_view = nil,                                   --文字输入视图
        },
        events_system = self.events_system:new()
    }
    --扫描 将属性挪移到 新对象
    for i, c in pairs(tab or {}) do
        new_obj[i] = c;
    end
    setmetatable(new_obj, self)
    gui:_init()
    --返回新对象
    return new_obj
end

--初始函数 系统
function gui:_init()
    return self:init()
end

--初始函数
function gui:init()
    --获取桌面大小
    -- local love.window.getDesktopDimensions()
    local window_w, window_h = love.window.getMode()
    --gui默认宽高同步窗口大小
    self.width = window_w
    self.height = window_h
    -- print(window_w, window_h)
    --初始化字体系统
    self.font_manger = font_manger
    self.font_manger:init()
    --设置默认字体对象
    self.font = "default" -- self.font_manger:get_default_fonts(20)
end

--根据id获取视图
function gui:get_id_view(id)
    return self.views[id]
end

--获取窗口宽高
function gui:get_window_wh()
    -- body
    return love.window.getMode()
end

--添加视图
function gui:add_view(view)
    --整个布局表加载模式
    if not view.type then
        for _, c in ipairs(view) do
            self:add_view(c)
        end
        --退出
        return
    end
    --子视图图层
    local _layer = view._layer
    --view.parent = self
    local name = view.name --以自己地址为唯一标识


    view.events_system = self.events_system --初始化事件管理索引
    --为视图初始公用字体
    if not view.font then
        view.font = self.font
    end
    --如果图层区域不存在
    if not gui.tree_views[_layer] then
        gui.tree_views[_layer] = {} --初始化图层
    end
    --将视图添加到图层树
    table.insert(self.tree_views[_layer], view)
    --图层排序 由小到大排序
    table.sort(self.tree_views[_layer], function(a, b)
        return a._draw_order < b._draw_order
    end) --排序

    --添加到整体区域
    --键索引表
    if view.id and view.id ~= "" then
        --后面的覆盖前面的
        if self.views[view.id] then
            self.views[self.views[view.id].name] = self.views[view.id]
        end
        self.views[view.id] = view;
    else
        self.views[name] = view;
    end

    --根据图层排序
    table.sort(self.views, function(a, b)
        --print(a._layer, b._layer)
        return a._layer < b._layer
    end) --排序

    --可能是load_layout添加的视图
    if not view.gui or #view.children > 0 then
        view.gui = self; --设置管理器索引
        --首次启动回调
        view:_on_create()
        --print(view.type)
        --处理子视图
        if #view.children > 0 then
            for i, child in ipairs(view.children) do
                self:add_view(child)
            end
        end
        --首次添加管理器 并初始化子视图
        --自身尺寸改变回调
        view:_change_from_self()
    else
        --首次启动回调
        view:_on_create()
        --首次添加管理器 并初始化子视图
    end
    --[[
    if view.parent then
        --对子视图改变做出响应
        --自身添加子视图了 如果需要响应这个事件则重写一下回调
        view.parent:change_from_children(child_view)
    end
    ]]
    return view
end

--设置焦点视图 只对图层1视图生效
function gui:set_hover_view(view)
    --print(view._layer)
    if view._layer == 1 then
        local tree_views = self.tree_views[1] --图层1索引
        --绘图总比顶层的值大1
        local o2 = #tree_views                -- 1
        local t2 = tree_views[o2]

        view._draw_order = t2._draw_order + 1

        --图层1排序
        table.sort(tree_views, function(a, b)
            --print(a._layer, b._layer)
            return a._draw_order < b._draw_order
        end) --排序
        --print(view._draw_order, tree_views[#tree_views]._draw_order)
        -----事件传递相关
        --[[
        local input_state = self.input_state      --事件状态表
        local hover_view = input_state.hover_view --焦点视图
        if hover_view then                        --焦点视图存在
            --执行失去焦点事件
            hover_view.hover = false              --焦点视图取消焦点
            hover_view:_off_hover()               --执行失去焦点回调
        end
        --重新赋值焦点视图
        input_state.hover_view = view;
        input_state.layer = view._layer; --设置焦点图层
        view:_on_hover()                 --执行获取焦点回调
        ]]
    else
        -- print(1)
        assert(true, "设置焦点视图失败 视图图层不是图层1")
    end
end

--字体
------------------------------------
--设置全局字体
function gui:set_font(path)
    -- body
    --local path = "YeZiGongChangTangYingHei-2.ttf"
    local font = love.graphics.newFont(path)
    -- love.graphics.setFont(font)
    self.font = font
    --
    for _, view in pairs(self.views) do
        view.font = font
    end
    return true
end

--获取全局字体管理器
function gui:get_font_manger()
    return self.font_manger
end

--获取指定大小字体
function gui:get_font(fn, fs)
    return self.font_manger:get_font(fn, fs)
end

---------------------------------------------
--事件系统相关
function gui:on_event(eventName, callback, subscriber)
    -- body
    return self.events_system:subscribe(eventName, callback, false, subscriber)
end

function gui:once_event(eventName, callback, subscriber)
    -- body
    return self.events_system:subscribe(eventName, callback, true, subscriber)
end

function gui:publish_event(eventName, ...)
    -- body
    return self.events_system:publish(eventName, ...)
end

function gui:unsubscribeById(eventName, subId)
    return self.events_system:unsubscribeById(eventName, subId)
end

function gui:un_event_self(eventName)
    return self.events_system:unsubscribeById(eventName, self)
end

--事件系统相关end
-----------------------------------------
--解析布局相关
-- 转换算法：将嵌套表结构转换为顺序表 + 稀疏集父子关系
function gui.convertToSequentialTable(nestedTable)
    local sequentialTable = {}      -- 顺序表，存储所有节点
    local parentChildRelations = {} -- 稀疏集，存储父子关系 {childIndex = parentIndex}
    local nodeCounter = 0           -- 节点计数器

    -- 递归遍历函数
    local function traverse(node, parentIndex)
        nodeCounter = nodeCounter + 1
        local currentIndex = nodeCounter

        -- 创建当前节点的副本（去除嵌套子节点）
        local nodeCopy = {}
        for k, v in pairs(node) do
            if type(v) ~= "table" or not v.type then -- 不是子节点
                nodeCopy[k] = v
            end
        end

        -- 添加到顺序表
        table.insert(sequentialTable, nodeCopy)

        -- 记录父子关系
        if parentIndex then
            parentChildRelations[currentIndex] = parentIndex
        else
            parentChildRelations[currentIndex] = 0
        end

        -- 递归处理子节点
        for k, v in pairs(node) do
            if type(v) == "table" and v.type then -- 是子节点
                traverse(v, currentIndex)
            end
        end
    end

    -- 开始遍历根节点
    traverse(nestedTable, nil)

    return sequentialTable, parentChildRelations
end

--将布局解析为视图对象
function gui:load_layout(lay)
    -- body
    local seqTable, relations = self.convertToSequentialTable(lay)

    local logic = true --允许头部视图
    local views = {};  --视图对象的顺序表
    for child, parent in pairs(relations) do
        --print(child .. " -> " .. parent)
        --当前视图
        view_lay = seqTable[child]
        if parent == 0 then
            assert(logic, "erro:load layout child->" .. "child")
            --assert(API[view_lay.type], "error: " .. view_lay.type)
            --print(view_lay.type)
            --print(API[view_lay.type])
            if not view_lay.type then
                views[child] = {}
            else
                view_lay.type = view_lay.type or "frame_layout"
                assert(API[view_lay.type], "erro:view type not find:" .. view_lay.type)
                views[child] = API[view_lay.type]:new(view_lay)
                logic = false
            end
        else --第二
            assert(API[view_lay.type], "error: ", view_lay.type)
            views[child] = API[view_lay.type]:new(view_lay)
            local par = views[parent]
            assert(par, "parent not nil")
            if par.type then
                par:add_view(views[child])
            else
                table.insert(par, views[child])
            end
            --print(child, parent)
            -- child
        end
    end
    return views[1]
end

--全体视图对象解析为布局
function gui:views_out_to_layout()
    local out_table = {}
    for _, child in ipairs(self.tree_views[1]) do
        local ta = child:out_to_table()
        table.insert(out_table, ta)
    end
    return dump(out_table)
end

-- 执行转换
--local seqTable, relations = convertToSequentialTable(lay)
--for child, parent in pairs(relations) do
--    print(child .. " -> " .. parent)
--end
------------------------------------------

--迭代更新函数
function gui:update(dt)
    -- body
    for i, view in pairs(self.views) do
        --print(view.update)
        -- if rawget(view, "update") then
        if view.visible then
            view:update(dt)
        end
        -- end
    end
    --print("视图总量:" .. #self.views)
end

--两矩形碰撞
local function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
        x2 < x1 + w1 and
        y1 < y2 + h2 and
        y2 < y1 + h1
end

--求两矩形交集
local function get_rect_intersection(x1, y1, w1, h1, x2, y2, w2, h2)
    -- 计算交集的左、右、上、下边界
    local left = math.max(x1, x2)
    local right = math.min(x1 + w1, x2 + w2)
    local top = math.max(y1, y2)
    local bottom = math.min(y1 + h1, y2 + h2)

    -- 判断是否相交
    if left < right and top < bottom then
        --[[
        --判断包含
        if x1 < x2 and y1 < y2 and x1 + w1 > x2 + w2 and y1 + h1 > y2 + h2 then
            return nil;
        end
        ]]
        -- 返回交集参数：x, y, width, height
        return { x = left, y = top, width = right - left, height = bottom - top }
    else
        -- 不相交时返回nil
        return nil --{ 0, 0, 0, 0 }
    end
end


--自制层级剪裁函数
--剪裁
local stack = {}   --主栈
local c_stack = {} --临时栈

function gui:push_scissor(x, y, width, height, scissor_label)
    local zoom = 1; --剪裁缩放
    --将剪裁区域压入栈
    table.insert(stack, { x = x, y = y, width = width, height = height })
    --导入临时栈
    if scissor_label then
        --与临时栈顶剪裁区域求交集
        local c_stack_top = c_stack[#c_stack] --取栈顶数据
        if c_stack_top then
            --与栈顶相交
            if checkCollision(c_stack_top.x, c_stack_top.y, c_stack_top.width, c_stack_top.height, x, y, width, height) then
                --求两矩形交集
                local rect = get_rect_intersection(c_stack_top.x, c_stack_top.y, c_stack_top.width, c_stack_top.height, x,
                    y,
                    width, height)
                --将交集推入临时栈
                table.insert(c_stack, rect)
                --将新数据推回栈
                stack[#stack] = rect --更新主栈顶
            else                     --不相交不包含
                -- print(113)
                stack[#stack] = { x = 0, y = 0, width = 0, height = 0 }
            end
        end
        --   table.insert(c_stack, { x = x, y = y, width = width, height = height })
    end


    --更新当前剪裁区域
    --[[
    love.graphics.stencil(function()
        -- 绘制当前剪裁区域
        for i, clip in ipairs(self.scissors) do
            --print(i, clip.x, clip.y, clip.width, clip.height)
            love.graphics.rectangle("fill", clip.x, clip.y, clip.width, clip.height)
        end
    end, "replace", #self.scissors)

    love.graphics.setStencilTest("greater", #self.scissors - 1)
    ]]
    local stack_top = stack[#stack] --取栈顶数据
    if stack_top then
        love.graphics.setScissor(stack_top.x, stack_top.y, stack_top.width, stack_top.height)
    end
    return stack_top
end

--关闭本层剪裁
function gui:pop_scissor()
    table.remove(stack) --删除栈顶\
    love.graphics.setScissor()
    --love.graphics.setStencilTest()
end

--关闭剪裁并清空标记
function gui:pop_scissor_label()
    table.remove(stack)   --删除栈顶\
    table.remove(c_stack) --删除临时栈顶\
    love.graphics.setScissor()
end

--绘图函数
function gui:draw(...)
    --输入
    -- body
    --只扫描图层第1层
    --
    --self:push_scissor(0, 0, 1000, 1000)
    for i, view in pairs(self.tree_views[1]) do
        if view.visible then
            --love.graphics.push()
            --love.graphics.translate(self.x, self.y)
            view:_draw()
            --love.graphics.pop()
        end
    end
    -- 只绘制模板覆盖的区域
    -- love.graphics.setStencilTest("equal", 1)
    -- 关闭模板测试
    --love.graphics.setStencilTest()
end

--点与矩形碰撞
function gui.point_in_rect(x, y, rectX, rectY, width, height) --点是否在矩形内
    return x >= rectX
        and x <= rectX + width
        and y >= rectY
        and y <= rectY + height
end

--适配多平台输入
if love.system.getOS() == "Windows" then
    --


    function gui:mousemoved(id, x, y, dx, dy, istouch, pre)
        local input_state = self.input_state
        local tree_views = self.tree_views;
        local layer = input_state.layer;                --焦点图层
        local hover_view = input_state.hover_view       --焦点视图
        local pressed_views = input_state.pressed_views --选中的视图集合--鼠标模式选中的视图[1]

        --底层向顶层扫描 尽可能的多扫描
        local function scan(tab, parent)
            --print(#tab)
            --先扫每个图层顶层
            for i = #tab, 1, -1 do
                local view = tab[i]
                if view.visible then --视图可见
                    if parent then   --如果存在父视图
                        --传递自身 复检事件传递权限
                        if parent:_event_intercept(x, y, view) then
                            if view:containsPoint(x, y) then
                                --print(12)
                                if view:_event_intercept(x, y) then --如果视图未拦截事件 传递事件到子视图
                                    if #view.children > 0 then
                                        --print(123)
                                        return scan(view.children, view) --继续扫描子视图 并传递父视图
                                    end
                                end
                                --  print(view.type, 132)
                                input_state.hover_view = view;                          --赋值焦点视图
                                input_state.layer = view._layer;                        --赋值焦点图层
                                view:_on_hover()                                        --中断后续 新的焦点视图执行获取焦点回调
                                return view:_mousemoved(id, x, y, dx, dy, istouch, pre) --中断后续 执行滑动回调
                            end
                        end
                    else --只有第一层不存在父视图
                        if view:containsPoint(x, y) then
                            --print(12)
                            local c_view;
                            if view:_event_intercept(x, y) then --如果视图未拦截事件 传递事件到子视图
                                if #view.children > 0 then
                                    --print(123)
                                    c_view = scan(view.children, view) --继续扫描子视图 并传递父视图
                                end
                            end
                            -- print(view.type, 131)
                            if c_view then
                                input_state.hover_view = c_view;                          --赋值焦点视图
                                input_state.layer = c_view._layer;                        --赋值焦点图层
                                c_view:_on_hover()                                        --中断后续 新的焦点视图执行获取焦点回调
                                return c_view:_mousemoved(id, x, y, dx, dy, istouch, pre) --中断后续 执行滑动回调
                            end
                            input_state.hover_view = view;                                --赋值焦点视图
                            input_state.layer = view._layer;                              --赋值焦点图层
                            view:_on_hover()                                              --中断后续 新的焦点视图执行获取焦点回调
                            return view:_mousemoved(id, x, y, dx, dy, istouch, pre)       --中断后续 执行滑动回调
                        end
                    end
                end
            end
        end


        --window id输入为空 需要手动获取
        if pressed_views[1] then                                               --鼠标模式选中视图存在 执行选中视图滑动回调
            return pressed_views[1]:_mousemoved(1, x, y, dx, dy, istouch, pre) --中断后续 执行滑动回调
        elseif pressed_views[2] then                                           --鼠标模式选中视图存在 执行选中视图滑动回调
            return pressed_views[2]:_mousemoved(2, x, y, dx, dy, istouch, pre) --中断后续 执行滑动回调
        elseif pressed_views[3] then                                           --鼠标模式选中视图存在 执行选中视图滑动回调
            return pressed_views[3]:_mousemoved(3, x, y, dx, dy, istouch, pre) --中断后续 执行滑动回调
        else                                                                   --无选中视图 重新获取焦点视图
            --执行焦点视图事件
            if hover_view and layer then                                       --存在焦点视图 与焦点图层
                --print(hover_view, layer)

                if hover_view:containsPoint(x, y) and hover_view.visible then --单独判断焦点视图 视图还有焦点 扫描子视图
                    --复检图层1输入权限
                    --通常所有视图在一个图层 树结构排序
                    --为了弹窗类方便 部分视图使用gui添加 且自动拦截事件
                    --主要用于实现弹窗类
                    local tab = tree_views[1]
                    --获取焦点视图最顶层父视图
                    local TopParent = hover_view:getTopParent()
                    for i = #tab, 1, -1 do
                        local view = tab[i]
                        --print(view.type)
                        if view.visible then
                            --当扫描到顶层视图则弹出 因为剩下的优先级比当前低
                            if view == TopParent then
                                -- print('弹出', view, TopParent)
                                break --弹出
                            else
                                if view:containsPoint(x, y) then
                                    --如果出现一个优先级高于当前视图 且拦截事件
                                    hover_view.hover = false; --焦点视图取消焦点
                                    hover_view:_off_hover()   --失去焦点回调
                                    --[[
                                    input_state.hover_view = view;                          --赋值焦点视图
                                    input_state.layer = view._layer;                        --赋值焦点图层
                                    view:_on_hover()                                        --中断后续 新的焦点视图执行获取焦点回调
                                    return view:_mousemoved(id, x, y, dx, dy, istouch, pre) --中断后续 执行滑动回调
                                    ]]
                                    local tree_views_childrent = tree_views[1] --图层
                                    return scan(tree_views_childrent)          --开始扫描
                                end
                            end
                        end
                    end

                    --没有失去焦点继续执行滑动回调
                    --复检父视图输入权限
                    --拦截后父视图接受事件
                    local parent = hover_view.parent
                    if parent then
                        if parent:_event_intercept(x, y, hover_view) then
                            --return hover_view:_mousemoved(id, x, y, dx, dy, istouch, pre) --执行焦点视图回调
                        else
                            hover_view.hover = false;                                 --焦点视图取消焦点
                            hover_view:_off_hover()                                   --失去焦点回调                                                        --赋值焦点图层
                            input_state.hover_view = parent;                          --赋值焦点视图
                            input_state.layer = parent._layer;                        --赋值焦点图层
                            parent:_on_hover()                                        --中断后续 新的焦点视图执行获取焦点回调
                            return parent:_mousemoved(id, x, y, dx, dy, istouch, pre) --中断后续 执行滑动回调
                        end
                    end

                    --复检子视图传递参数
                    --根据优先级扫描
                    local children = hover_view.children
                    if children then
                        for i = #children, 1, -1 do
                            local child = children[i]
                            --print(child.border_container_page)
                            -- print(child:containsPoint(x, y))
                            if child.visible then
                                --将子视图作为参数传递 判断是否获取新焦点
                                if hover_view:_event_intercept(x, y, child) then                 --如果视图未拦截事件 传递事件到子视图
                                    if child:containsPoint(x, y) then
                                        hover_view.hover = false;                                --焦点视图取消焦点
                                        hover_view:_off_hover()                                  --失去焦点回调
                                        input_state.hover_view = child;                          --赋值焦点视图
                                        input_state.layer = child._layer;                        --赋值焦点图层
                                        child:_on_hover()                                        --中断后续 新的焦点视图执行获取焦点回调
                                        return child:_mousemoved(id, x, y, dx, dy, istouch, pre) --中断后续 执行滑动回调
                                    end
                                end
                            end
                        end
                    end





                    return hover_view:_mousemoved(id, x, y, dx, dy, istouch, pre) --执行焦点视图回调
                else                                                              --视图失去焦点
                    --print(2)
                    hover_view.hover = false                                      --焦点视图取消焦点
                    hover_view:_off_hover()                                       --失去焦点回调
                    local layer = hover_view._layer                               --获取焦点视图的上一层

                    --扫描父视图
                    if hover_view.parent then
                        local view = hover_view.parent                                  --获取父视图
                        if view.visible then                                            --如果视图可见                                                   --如果扫描视图可见                                                     --可见
                            if view:containsPoint(x, y) then                            --如果点在视图内
                                hover_view.hover = false;                               --焦点视图取消焦点
                                hover_view:_off_hover()                                 --失去焦点回调
                                input_state.hover_view = view;                          --赋值焦点视图
                                input_state.layer = view._layer;                        --赋值焦点图层
                                view:_on_hover()                                        --中断后续 新的焦点视图执行获取焦点回调
                                return view:_mousemoved(id, x, y, dx, dy, istouch, pre) --中断后续 执行滑动回调
                            end
                        end
                    end
                    hover_view.hover = false;     --焦点视图取消焦点
                    hover_view:_off_hover()       --失去焦点回调
                    input_state.hover_view = nil; --赋值焦点视图
                    input_state.layer = 1;
                end
            else                                          --新的全控件顶层扫描 用于赋予视图焦点
                local tree_views_children = tree_views[1] --图层
                scan(tree_views_children)                 --开始扫描
            end
        end
        -- print(hover_view, layer)
    end

    function gui:mousepressed(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击
        local input_state = self.input_state
        local hover_view = input_state.hover_view             --焦点视图
        local pressed_views = input_state.pressed_views       --选中的视图集合--鼠标模式选中的视图[1]


        if hover_view then                                              --鼠标模式焦点视图一定存在
            if hover_view:containsPoint(x, y) then                      --复检焦点视图点击
                pressed_views[id] = hover_view;                         --赋值选中视图(根据鼠标id)
                --输入相关逻辑
                if input_state.keypressed_view then                     --输入视图是否存在
                    if hover_view ~= input_state.keypressed_view then   --输入函数失去选中
                        input_state.keypressed_view:_loss_keypressed(); --执行失去输入权限回调
                        input_state.keypressed_view = hover_view;       --赋值输入视图
                    end
                else
                    input_state.keypressed_view = hover_view; --赋值输入视图
                end

                return hover_view:_mousepressed(id, x, y, nil, nil, istouch, pre) --回调
            end
        else                                                                      --无焦点视图且点击空白
            if input_state.keypressed_view then
                input_state.keypressed_view:_loss_keypressed();                   --执行失去输入权限回调
                input_state.keypressed_view = nil;                                --赋值输入视图
            end
        end
    end

    function gui:mousereleased(id, x, y, dx, dy, istouch, pre)        --pre短时间按下次数 模拟双击
        local input_state = self.input_state
        local pressed_views = input_state.pressed_views               --选中的视图集合--鼠标模式选中的视图[1]
        local view = pressed_views[id]                                --迭代选中视图集合
        if view then
            if view:containsPoint(x, y) then                          --释放按钮在选中视图中
                view:_on_click(id, x, y, dx, dy, istouch, pre)        --执行点击回调
                view:_mousereleased(id, x, y, nil, nil, istouch, pre) --回调
                -- view:off_hover(id, x, y, dx, dy, istouch, pre)        --失去焦点回调
            else
                view:_mousereleased(id, x, y, nil, nil, istouch, pre) --回调
                view:off_hover(id, x, y, dx, dy, istouch, pre)        --失去焦点回调
            end
            view.isDragging = false;                                  --视图拖动清空
        end

        input_state.pressed_views[id] = nil --鼠标模式选中视图赋值
    end

    function gui:wheelmoved(id, x, y)                   --滚轮滑动
        local input_state = self.input_state
        local hover_view = input_state.hover_view       --焦点视图
        local pressed_views = input_state.pressed_views --选中的视图集合--鼠标模式选中的视图[1]

        if hover_view and not pressed_views[1] then     --存在焦点视图 且鼠标未选中视图
            return hover_view:_wheelmoved(nil, x, y)
        end
    end
elseif love.system.getOS() == "Android" then --多点触控支持
    --
    gui.input_state.touch_id = {}
    --
    function gui.get_touch_id(id) --将触摸id转换为数子
        if (tostring(id) == "userdata: NULL") then
            return 1
        elseif (tostring(id) == "userdata: 0x00000001") then
            return 2
        elseif (tostring(id) == "userdata: 0x00000002") then
            return 3
        elseif (tostring(id) == "userdata: 0x00000003") then
            return 4
        elseif (tostring(id) == "userdata: 0x00000004") then
            return 5
        elseif (tostring(id) == "userdata: 0x00000005") then
            return 6
        elseif (tostring(id) == "userdata: 0x00000006") then
            return 7
        elseif (tostring(id) == "userdata: 0x00000007") then
            return 8
        end
        return 1;
    end

    local function scan(tab, parent, x, y)
        --
        for i = #tab, 1, -1 do
            local child_view = tab[i]
            --print(view.type)
            -- print(1,tostring(parent))
            if child_view.visible then
                if parent then --如果存在父视图
                    --[[
                        print(i, child_view)
                        print(child_view.type)
                        print(parent:_event_intercept(x, y, child_view))
                        print(child_view:containsPoint(x, y))
                        print(y)
                        print(child_view:get_local_Position(x, y))
                        ]]
                    -- print(i, child_view, child_view.type)
                    --传递自身到父制图 复检父视图对自己事件传递权限
                    if parent:_event_intercept(x, y, child_view) then
                        if child_view:containsPoint(x, y) then
                            --print(12)
                            --传递子视图
                            if child_view:_event_intercept(x, y) then                  --如果视图未拦截事件 传递事件到子视图
                                if #child_view.children > 0 then
                                    return scan(child_view.children, child_view, x, y) --继续扫描子视图 并传递父视图
                                end
                            end
                            --中断后续 新的焦点视图执行获取焦点回调
                            return child_view
                        end
                    end
                else                                                                      --没有父视图
                    if child_view:containsPoint(x, y) then
                        local return_view = nil;                                          --扫描出的视图
                        if child_view:_event_intercept(x, y) then                         --如果视图未拦截事件 传递事件到子视图
                            if #child_view.children > 0 then
                                return_view = scan(child_view.children, child_view, x, y) --继续扫描子视图 并传递父视图
                            end
                        end
                        --print(view.type)
                        --不向下传递 返回自己
                        return return_view or child_view;
                    end
                end
            end
        end
        --
        return parent
    end
    --[[
    local tree_views = self.tree_views;
    local tree_views_children = tree_views[1]             --图层
    local view = scan(tree_views_children, nil, x, y)     --开始扫描
    print("视图:", view.type, view._layer)
]]
    --回调
    function gui:touchpressed(id, x, y, dx, dy, ispressure, pressure) --触摸按下
        local input_state = self.input_state
        local tree_views = self.tree_views;
        local hover_view = input_state.hover_view       --焦点视图
        local pressed_views = input_state.pressed_views --选中的视图集合--鼠标模式选中的视图[1]
        local id = self.get_touch_id(id)                --获取触摸id
        --[[
        local function scan(tab, parent)
            --print(#tab)
            for i = #tab, 1, -1 do
                local view = tab[i]
                --print(view.type)
                -- print(1,tostring(parent))
                if parent then           --如果存在父视图
                    -- print(2)
                    if view.visible then --视图可见
                        --传递自身 复检事件传递权限
                        -- print(3)
                        if parent:_event_intercept(x, y, view) then
                            if view:containsPoint(x, y) then
                                --print(12)
                                if view:_event_intercept(x, y) then      --如果视图未拦截事件 传递事件到子视图
                                    if #view.children > 0 then
                                        return scan(view.children, view) --继续扫描子视图 并传递父视图
                                    end
                                end
                                pressed_views[id] = view;                                       --赋值触控id视图
                                --输入相关逻辑
                                if id == 1 then                                                 --只处理单指
                                    if input_state.keypressed_view then                         --输入视图是否存在
                                        if pressed_views[1] ~= input_state.keypressed_view then --输入函数失去选中
                                            input_state.keypressed_view:_loss_keypressed();     --执行失去输入权限回调
                                            input_state.keypressed_view = pressed_views[1];     --赋值输入视图
                                        end
                                    else
                                        input_state.keypressed_view = pressed_views[1]; --赋值输入视图
                                    end
                                end
                                --print(4)
                                view:_on_hover()                                            --中断后续 新的焦点视图执行获取焦点回调
                                return view:_mousepressed(id, x, y, dx, dy, true, pressure) --中断后续 执行滑动回调
                            else                                                            --未被点击到
                                -- print(321)
                                --复检输入权限相关
                                if input_state.keypressed_view then
                                    input_state.keypressed_view:_loss_keypressed(); --执行失去输入权限回调
                                    input_state.keypressed_view = nil;              --赋值输入视图
                                end
                            end
                        end
                    end
                else --没有父视图
                    -- print(6)
                    -- print(view.type)

                    if view:_event_intercept(x, y) then --如果视图未拦截事件 传递事件到子视图
                        if view:containsPoint(x, y) then
                            if #view.children > 0 then
                                return scan(view.children, view) --继续扫描子视图 并传递父视图
                            end
                            --
                            pressed_views[id] = view;                                       --赋值触控id视图
                            --输入相关逻辑
                            if id == 1 then                                                 --只处理单指
                                if input_state.keypressed_view then                         --输入视图是否存在
                                    if pressed_views[1] ~= input_state.keypressed_view then --输入函数失去选中
                                        input_state.keypressed_view:_loss_keypressed();     --执行失去输入权限回调
                                        input_state.keypressed_view = pressed_views[1];     --赋值输入视图
                                    end
                                else
                                    input_state.keypressed_view = pressed_views[1]; --赋值输入视图
                                end
                            end
                            --print(4)
                            view:_on_hover()                                            --中断后续 新的焦点视图执行获取焦点回调
                            return view:_mousepressed(id, x, y, dx, dy, true, pressure) --中断后续 执行滑动回调
                        end

                        --
                    end
                end
            end
        end
        ]]
        --新的全控件顶层扫描

        local tree_views_children = tree_views[1]         --图层
        local view = scan(tree_views_children, nil, x, y) --开始扫描
        --如果扫描到视图
        if view then
            pressed_views[id] = view;                                       --赋值触控id视图
            --输入相关逻辑
            if id == 1 then                                                 --只处理单指
                if input_state.keypressed_view then                         --输入视图是否存在
                    if pressed_views[1] ~= input_state.keypressed_view then --输入函数失去选中
                        input_state.keypressed_view:_loss_keypressed();     --执行失去输入权限回调
                        input_state.keypressed_view = pressed_views[1];     --赋值输入视图
                    end
                else
                    input_state.keypressed_view = pressed_views[1]; --赋值输入视图
                end
            end
            view:_on_hover()                                            --中断后续 新的焦点视图执行获取焦点回调
            return view:_mousepressed(id, x, y, dx, dy, true, pressure) --中断后续 执行滑动回调
        else
            --复检输入权限相关
            if input_state.keypressed_view then
                input_state.keypressed_view:_loss_keypressed(); --执行失去输入权限回调
                input_state.keypressed_view = nil;              --赋值输入视图
            end
        end
    end

    function gui:touchmoved(id, x, y, dx, dy, ispressure, pressure)   --触摸滑动
        local input_state = self.input_state
        local pressed_views = input_state.pressed_views               --选中的视图集合--鼠标模式选中的视图[1]
        local id = self.get_touch_id(id)                              --获取触摸id
        if pressed_views[id] then                                     --如果触摸id视图存在
            local view = pressed_views[id]
            view.isDragging = true;                                   --视图拖动变量赋值
            return view:_mousemoved(id, x, y, dx, dy, true, pressure) --执行回调        ;
        end
    end

    function gui:touchreleased(id, x, y, dx, dy, ispressure, pressure) --触摸抬起
        local input_state = self.input_state
        local pressed_views = input_state.pressed_views                --选中的视图集合--鼠标模式选中的视图[1]
        local id = self.get_touch_id(id)                               --获取触摸id
        if pressed_views[id] then                                      --如果触摸id视图存在
            local view = pressed_views[id]
            if view then
                if view:containsPoint(x, y) then                                  --释放按钮在选中视图中
                    view:_on_click(id, x, y, dx, dy, ispressure, pressure)        --执行点击回调
                    view.hover = false                                            --清楚视图焦点
                    view:_mousereleased(id, x, y, nil, nil, ispressure, pressure) --回调
                    view:off_hover(id, x, y, dx, dy, ispressure, pressure)        --失去焦点回调
                else
                    view:_mousereleased(id, x, y, nil, nil, ispressure, pressure) --回调
                    view:off_hover(id, x, y, dx, dy, ispressure, pressure)        --失去焦点回调
                end
            end

            view.hover = false      --清楚视图焦点

            pressed_views[id] = nil --触摸id视图赋值为空
            return;
        end
    end
end

--键盘输入
function gui:keypressed(key)                            --键盘点击事件
    --print(123)
    local input_state = self.input_state                --输入状态库
    local keypressed_view = input_state.keypressed_view --输入视图
    -- print(keypressed_view)
    if keypressed_view then
        keypressed_view:keypressed(key)
    end
end

--文字输入
function gui:textinput(text)                            --文字输入事件
    --print(123)
    local input_state = self.input_state                --输入状态库
    local keypressed_view = input_state.keypressed_view --输入视图
    -- print(keypressed_view)
    if keypressed_view then
        keypressed_view:textinput(text)
    end
end

--------------------------------------
--退出程序 exit
function gui:quit()
end

--拖入文件目录到真实窗口
function gui:directorydropped(path)
    -- print(path)
end

--拖入文件到真实窗口
--鼠标操作模式
function gui:filedropped(file)
    -- print(file:getFilename())
end

--窗口显示状态 (判断屏幕方向)
function gui:visible(v)
    --print(v)
    --print(v and "Window is visible!" or "Window is not visible!");
end

--窗口大小变化
function gui:resize(width, height)
    --print(123)
    --视图更新
    --窗口大小改变 调用最底层的回调
    for _, view in pairs(self.tree_views[1]) do
        view:change_from_parent(nil)
    end
end

--用户最小化窗口/取消最小化窗口回调
function gui:visible(is_small)
    -- body
end

return gui;
