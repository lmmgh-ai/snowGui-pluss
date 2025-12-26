local gui = require(lumenGui_path .. ".gui")
local scene_gui = gui:new()
local API = require(lumenGui_path .. ".API")
--
--为操作状态添加更多状态
scene_gui.input_state = {
    --layer = nil, --焦点图层
    --isPressed = false,     --点击
    isMoved = false,    --滑动

    pressed_views = {}, --选中的视图集合 十点触摸为10个
    --hover_view = nil,      --焦点视图
    --keypressed_view = nil, --键盘锁定视图(暂时用这一个标识 文字输入与键盘未区分)
    --input_text_view = nil,                                   --文字输入视图
    --新增
    select_view = nil,     --当前选中的视图
    is_select_box = false, --是否框选
    is_change_box = false, --选中视图后 拖动大小改变框
    --输入值 左键按下取值 用于绘制选择框
    --调试边框8个控制点
    points = {
        { 1,  0 },
        { 1,  1 },
        { 0,  1 },
        { -1, 1 },
        { -1, 0 },
        { -1, -1 },
        { 0,  -1 },
        { 1,  -1 },
    },
    select_point = nil, --选中的控制点
    --缓存的指向视图
    point_view = nil,
    --框选边框
    -- select_rect = {},
}
--重写gui交互事件 为场景添加一个 视图管理器

--重写解析视图与导出视图放边修改与导出函数定义
--将布局解析为视图对象
function scene_gui:load_layout(lay)
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
function scene_gui:views_out_to_layout()
    local out_table = {}
    for _, child in ipairs(self.tree_views[1]) do
        local ta = child:out_to_table()
        table.insert(out_table, ta)
    end
    return dump(out_table)
end

--重写绘图 选中视图绘制边框
function scene_gui:draw(...)
    --输入
    -- body
    --只扫描图层第1层
    --
    for i, view in pairs(self.tree_views[1]) do
        if view.visible then
            view:_draw()
        end
    end
    self:tool_draw()
end

--工具绘图
function scene_gui:tool_draw()
    local input_state = self.input_state
    --选中视图存在
    local select_view = input_state.select_view
    if select_view then
        local points = input_state.points
        local x, y = select_view:get_world_Position(-5, -5)
        local width, height = select_view.width + 10, select_view.height + 10
        local cx, cy = x + width / 2, y + height / 2
        love.graphics.setColor(1, 1, 0)
        love.graphics.rectangle("line", x, y, width, height)
        --绘制8方向拖动块(控制点)
        for i, c in ipairs(points) do
            local x1 = cx + (width / 2 * c[1])
            local y1 = cy + (height / 2 * c[2])
            love.graphics.setColor(1, 1, 0)
            love.graphics.circle("fill", x1, y1, 8)
            love.graphics.setColor(0, 0, 0)
            love.graphics.circle("line", x1, y1, 8)
        end
    end
    --指向视图存在
    local point_view = input_state.point_view
    if point_view then
        local x, y = point_view:get_world_Position(-5, -5)
        local width, height = point_view.width + 10, point_view.height + 10
        love.graphics.setColor(1, 1, 0)
        love.graphics.rectangle("line", x, y, width, height)
    end
end

--适配多平台输入
--if love.system.getOS() == "Windows" then
--
local function scan(tab, parent, select_view, x, y)
    --print(#tab)
    --先扫每个图层顶层
    for i = #tab, 1, -1 do
        local view = tab[i]
        --选择视图指向不等于自身
        if view.visible and view ~= select_view then --视图可见
            if parent then                           --如果存在父视图
                --传递自身 复检事件传递权限
                if parent:_event_intercept(x, y, view) then
                    if view:containsPoint(x, y) then
                        --print(12)
                        if view:_event_intercept(x, y) then --如果视图未拦截事件 传递事件到子视图
                            if #view.children > 0 then
                                --print(123)
                                return scan(view.children, view) --继续扫描子视图 并传递父视图
                            end

                            --中断后续 新的焦点视图执行获取焦点回调
                            return view;
                        else
                            return view;
                        end
                    end
                end
            else --只有第一层不存在父视图
                if view:containsPoint(x, y) then
                    -- print(12)
                    if view:_event_intercept(x, y) then --如果视图未拦截事件 传递事件到子视图
                        if #view.children > 0 then
                            --print(123)
                            return scan(view.children, view, select_view, x, y) --继续扫描子视图 并传递父视图
                        end
                        return view
                    else
                        return view;
                    end
                end
            end
        end
    end
end

function scene_gui:mousemoved(id, x, y, dx, dy, istouch, pre)
    local input_state = self.input_state
    local tree_views = self.tree_views;
    local layer = input_state.layer;                --焦点图层
    local select_view = input_state.select_view     --选中视图
    local pressed_views = input_state.pressed_views --选中的视图集合--鼠标模式选中的视图[1]
    --
    input_state.isMoved = true                      --滑动
    --window id输入为空 需要手动获取
    -- print(select_view, pressed_views[1])
    if (select_view and pressed_views[1]) or input_state.select_point then -- and love.mouse.isDown(1) then --鼠标模式选中视图存在 执行选中视图滑动回调
        --选中控制点 拖动
        local i = input_state.select_point
        --print(i)
        --点击到控制点
        if i then
            local point = input_state.points[i]
            select_view:set_width(select_view.width + point[1] * dx)
            select_view:set_height(select_view.height + point[2] * dy)
            if i == 8 then
                select_view.y = select_view.y - point[2] * dy
            elseif i == 4 then
                select_view.x = select_view.x - point[1] * dx
            end
            if i >= 5 and i <= 7 then
                select_view.x = select_view.x - point[1] * dx
                select_view.y = select_view.y - point[2] * dy
            end
            return input_state
        else --拖动视图
            --指向视图
            local point_view = input_state.point_view
            -- print(123)
            --select_view.x = select_view.x + dx
            --select_view.y = select_view.y + dy
            select_view:move_Position(dx, dy)
            self:publish_event("选中视图属性更新", select_view)
            --判断存在父视图
            local parent = select_view:get_parent()
            if parent then
                --拖动还在父视图内
                if parent:containsPoint(x, y) then
                    input_state.point_view = parent
                    return --parent
                end
            end
            --扫描新的指向视图
            if point_view then
                if point_view:containsPoint(x, y) then --如果点在视图内
                    --复检子视图传递参数
                    --根据优先级扫描
                    local children = point_view.children
                    if #children > 0 then
                        for i = #children, 1, -1 do
                            local child = children[i]
                            --print(child.border_container_page)
                            -- print(child:containsPoint(x, y))
                            if child.visible then
                                --将子视图作为参数传递 判断是否获取新焦点
                                if child:containsPoint(x, y) then
                                    input_state.point_view = child
                                    return --child --中断后续 执行滑动回调
                                end
                            end
                        end
                    end
                    return input_state.point_view
                else
                    --失去焦点 扫描父视图
                    local parent = point_view:get_parent()
                    if parent then
                        if point_view:containsPoint(x, y) then
                            input_state.point_view = parent
                            return parent
                        end
                    end
                end
                input_state.point_view = nil
                return nil
                --重新扫描 指向视图
            else
                for i = 1, 1 do
                    local tree_views_chliden = tree_views[i] --图层
                    for i2 = #tree_views_chliden, 1, -1 do
                        local view = tree_views_chliden[i2]  --如果扫描视图可见
                        if view.visible and view ~= select_view then
                            if view:containsPoint(x, y) then --如果点在视图内
                                --赋值指向视图
                                input_state.point_view = view
                                return view; --将视图返回上层
                            end
                        end
                    end
                end
                return input_state.point_view
            end

            --
        end
    elseif pressed_views[2] then --鼠标模式选中视图存在 执行选中视图滑动回调
    elseif pressed_views[3] then --鼠标模式选中视图存在 执行选中视图滑动回调
    end
end

local function scan(tab, parent, x, y)
    --print(#tab)
    for i = #tab, 1, -1 do
        local view = tab[i]

        if view:containsPoint(x, y) then
            if #view.children > 0 then
                return scan(view.children, view, x, y) --继续扫描子视图 并传递父视图
            end
            --
            --中断后续 新的焦点视图执行获取焦点回调
            return view
        end
    end
end

function scene_gui:mousepressed(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击
    local input_state = self.input_state
    local tree_views = self.tree_views;
    local select_view = input_state.select_view     --选中视图
    local pressed_views = input_state.pressed_views --选中的视图集合--鼠标模式选中的视图[1]
    --顶层向下扫描视图
    --print(x, y)
    -- print(id)

    --
    if id == 1 then
        --判断视图
        --存在选中视图
        --判断点击调试边框
        if select_view then
            local points = input_state.points
            local x1, y1 = select_view:get_world_Position(-5, -5)
            local width, height = select_view.width + 10, select_view.height + 10
            local cx, cy = x1 + width / 2, y1 + height / 2
            --判断是否点击控制点
            for i, c in ipairs(points) do
                --调试边框控制点中心坐标
                local x2 = cx + (width / 2 * c[1])
                local y2 = cy + (height / 2 * c[2])
                if select_view.point_in_rect(x, y, x2 - 5, y2 - 5, 10, 10) then
                    --赋值控制点
                    --print("控制点", i, dump(input_state.points[i]))
                    input_state.select_point = i;
                    return select_view;
                end
            end
            --未扫描控制点 赋值为空
            input_state.select_point = nil
        end
        -- print(2)
        --重新扫描

        for i = #tree_views, 1, -1 do
            local tree_views_chliden = tree_views[i] --图层
            for i2 = #tree_views_chliden, 1, -1 do
                local view = tree_views_chliden[i2]  --如果扫描视图可见
                if view:containsPoint(x, y) then     --如果点在视图内
                    pressed_views[1] = view;         --赋值触控id视图
                    input_state.select_view = view
                    return input_state;              --将视图返回上层
                end
            end
        end

        --选中视图赋值为空
        input_state.select_view = nil
    elseif id == 2 then
        --取消选择
        input_state.pressed_views = {} --清空选中视图
        return input_state;
    end
    --点击了空白
    input_state.pressed_views = {} --清空选中视图
    return input_state;
    --print(2)
end

function scene_gui:mousereleased(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击
    local input_state = self.input_state
    local pressed_views = input_state.pressed_views              --选中的视图集合--鼠标模式选中的视图[1]
    local point_view = input_state.point_view                    --指向视图
    local view = pressed_views[id]                               --迭代选中视图集合
    local select_view = input_state.select_view                  --选中视图
    --拖动改变父视图

    if select_view then
        --获取父视图
        local parent = select_view:get_parent()
        --存在新指向视图
        if point_view and point_view ~= parent then
            --print(111)
            -- if view:containsPoint(x, y) then --释放按钮在选中视图中
            select_view.x, select_view.y = point_view:get_local_Position(select_view.x, select_view.y)
            select_view:change_parent(point_view)
        elseif parent then
            --判断是否移出父视图
            if not parent:containsPoint(x, y) then --存在父视图
                ---print("1111111111")
                local x1, y1 = select_view:get_world_Position(0, 0)
                select_view:change_parent() --转化为浮动视图
                select_view.x, select_view.y = x1, y1
            else                            --在父视图内移动
                --调用父视图回调
                parent:_change_from_self(select_view)
            end
        end
    end
    --清空变量

    --
    --input_state.select_view = nil;
    input_state.select_point = nil      --选中控制点置零
    input_state.pressed_views[id] = nil --鼠标模式选中视图赋值
    input_state.point_view = nil        --指向视图赋值为空
end

--
return scene_gui;
