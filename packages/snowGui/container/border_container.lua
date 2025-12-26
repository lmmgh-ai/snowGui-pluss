local view = require(lumenGui_path .. ".view.view")
local border_container = view:new()
border_container.__index = border_container
--[[
子视图额外属性
判断子视图在哪个页面
border_container_page = page_name
]]

function border_container:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type            = "border_container", --类型
        text            = "border_container",
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.8, 0.8, 1, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 1, 1, 1, 1 },
        borderColor     = { 0, 0, 0, 1 },
        --
        pages           = {
            top = { x = 0, y = 0, width = 0, height = 0, unfold_distance = 0, is_unfold = false },
            bottom = { x = 0, y = 0, width = 0, height = 0, unfold_distance = 0, is_unfold = false },
            left = { x = 0, y = 0, width = 0, height = 0, unfold_distance = 0, is_unfold = false },
            right = { x = 0, y = 0, width = 0, height = 0, unfold_distance = 0, is_unfold = false },
        },
        buttons         = {
            top = { x = 0, y = 0, width = 0, height = 0, is_presses = false, is_drag = false },
            bottom = { x = 0, y = 0, width = 0, height = 0, is_presses = false, is_drag = false },
            left = { x = 0, y = 0, width = 0, height = 0, is_presses = false, is_drag = false },
            right = { x = 0, y = 0, width = 0, height = 0, is_presses = false, is_drag = false },
        },
        --页面单独视图排序
        page_children   = {
            main = {},
            top = {},
            bottom = {},
            left = {},
            right = {},
        },
        select_button   = nil, --选中的按钮
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

function border_container:_init()

end

function border_container:on_create()
    self:update_pages()   --更新页面位置
    self:update_buttons() --更新页面按钮位置
end

--当自身尺寸被父视图改变 响应
function border_container:change_from_parent(parent)
    -- body
    self:update_pages()   --更新页面位置
    self:update_buttons() --更新页面按钮位置
end

--根据页展开距离(unfold_distance) 更新页尺寸
function border_container:update_pages()
    local top = self.pages.top
    local bottom = self.pages.bottom
    local left = self.pages.left
    local right = self.pages.right;
    --

    if top.is_unfold then
        top.x = self.x
        top.y = self.y
        top.width = self.width;
        top.height = top.unfold_distance;
    else
        top.x = self.x
        top.y = self.y
        top.width = self.width;
        top.height = 0;
    end

    --

    if bottom.is_unfold then
        bottom.x = self.x
        bottom.y = self.y + self.height - bottom.unfold_distance
        bottom.width = self.width;
        bottom.height = bottom.unfold_distance;
    else
        bottom.x = self.x
        bottom.y = self.y + self.height
        bottom.width = self.width;
        bottom.height = 0;
    end

    --

    if left.is_unfold then
        left.x = self.x
        left.y = top.y + top.height
        left.width = left.unfold_distance;
        left.height = self.height - top.height - bottom.height;
    else
        left.x = self.x
        left.y = top.y + top.height
        left.width = 0;
        left.height = self.height - top.height - bottom.height;
    end

    --

    if right.is_unfold then
        right.x = self.x + self.width - right.unfold_distance
        right.y = top.y + top.height
        right.width = right.unfold_distance;
        right.height = self.height - top.height - bottom.height;
    else
        right.x = self.x + self.width
        right.y = top.y + top.height
        right.width = 0;
        right.height = self.height - top.height - bottom.height;
    end

    --print(dump(self.pages))
end

--根据页尺寸 更新按钮尺寸
function border_container:update_buttons()
    local top_page = self.pages.top
    local bottom_page = self.pages.bottom
    local left_page = self.pages.left
    local right_page = self.pages.right;
    --
    local top_b = self.buttons.top
    local bottom_b = self.buttons.bottom
    local left_b = self.buttons.left
    local right_b = self.buttons.right;
    --
    local font = self:get_font(self.font, self.textSize)
    local textWidth = 30  --font:getWidth("-----")
    local textHeight = 20 --font:getHeight()
    --
    top_b.width = textWidth;
    top_b.height = textHeight;
    top_b.x = top_page.x + (top_page.width - top_b.width) / 2
    top_b.y = top_page.y + top_page.height
    --
    bottom_b.width = textWidth;
    bottom_b.height = textHeight;
    bottom_b.x = bottom_page.x + (bottom_page.width - bottom_b.width) / 2
    bottom_b.y = bottom_page.y - bottom_b.height
    --
    left_b.width = textHeight;
    left_b.height = textWidth;
    left_b.x = left_page.x + left_page.width
    left_b.y = left_page.y + (left_page.height - left_b.height) / 2
    --
    right_b.width = textHeight;
    right_b.height = textWidth;
    right_b.x = right_page.x - right_b.width
    right_b.y = right_page.y + (right_page.height - right_b.height) / 2
end

--改变页折叠展开状态
function border_container:change_page_unfold(page_label, state)
    local button = self.buttons[page_label]
    local page = self.pages[page_label]
    if page then
        -- print(page.is_unfold)
        page.is_unfold = not page.is_unfold
        --print(page.is_unfold)
        if page.is_unfold then --展开
            if page.unfold_distance <= 0 then
                page.unfold_distance = 10
            end
            if page_label == "top" then
                page.height = page.unfold_distance
            elseif page_label == "bottom" then
                page.y = self.y + self.height - page.unfold_distance
                page.height = page.unfold_distance
            elseif page_label == "left" then
                page.width = page.unfold_distance
            elseif page_label == "right" then
                page.x = self.x + self.width - page.unfold_distance
                page.width = page.unfold_distance
            end
            --视图显示
            for i, view in pairs(self.page_children[page_label]) do
                view:set_visible(true)
            end
        else --折叠
            if page_label == "top" then
                page.height = 0
            elseif page_label == "bottom" then
                page.y = self.y + self.height
                page.height = 0
            elseif page_label == "left" then
                page.width = 0
            elseif page_label == "right" then
                page.x = self.x + self.width
                page.width = 0
            end

            --视图隐藏
            for i, view in pairs(self.page_children[page_label]) do
                view:set_visible(false)
            end
        end
        self:update_pages()
        self:update_buttons()
    end
end

-- 添加子视图
function border_container:add_view(child_view)
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
    --独特属性
    --[[
    local page = self.page_children.main
    --为视图添加唯一标记
    view.border_container_page = page_name
    if page then
        table.insert(page, child_view)
    end
    ]]
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

--将子视图添加到指定页面
--为子视图添加额外属性 border_container_page="page_name"
function border_container:add_page_view(page_name, view)
    --
    -- print(self.gui)
    --获取页面 table
    local page = self.page_children[page_name]
    --添加到子视图
    assert(page, page_name .. " error: not find page_name ")
    local view = self:add_view(view)
    --为视图添加唯一标记
    view.border_container_page = page_name
    if page then
        table.insert(page, view)
    end
    --print(page_name)
    return view
end

--改变绘图规则
function border_container:_draw()
    if self.visible then
        -- 绘制子视图
        local gui = self.gui
        local pages = self.pages
        local top = pages.top
        local bottom = pages.bottom
        local left = pages.left
        local right = pages.right;
        --print(self.point_in_rect(x, y, left.x + left.width, top.y + top.height, right.x, bottom.y))
        --print(x, y, left.x + left.width, top.y + top.height, right.x, bottom.y)
        local x = left.x + left.width
        local y = top.y + top.height
        local width = right.x - left.x - left.width
        local height = bottom.y - top.y - top.height
        --字体
        local font = self:get_font(self.font, self.textSize)
        love.graphics.setFont(font)
        -- print(x, y, width, height)

        --开启剪裁

        -- love.graphics.setScissor(self.x, self.y, self.width, self.height)
        --gui:push_scissoruiself.x, self.y, self.width, self.height)
        --绘制自身
        self:draw()

        --主页子视图绘制
        for i, main_child in pairs(self.page_children.main) do
            --print(i)
            -- main_child:_draw()
        end
        --绘制背景
        for i, page in pairs(self.pages) do
            --绘制背景
            love.graphics.setColor(self.backgroundColor)
            love.graphics.rectangle("fill", page.x, page.y, page.width, page.height)
            --绘制边框
            love.graphics.setColor(self.borderColor)
            love.graphics.rectangle("line", page.x, page.y, page.width, page.height)
        end


        --剪裁
        --love.graphics.intersectScissor(left.x + left.width, top.y + top.height, right.x - left.x - left.width,
        --   bottom.y - top.y - top.height)
        --绘制四个页面子视图
        -- 启用模板测试
        --[[
        -- 绘制内容（可以是图片、颜色等）
        for label, page in pairs(self.pages) do
            gui:push_scissor(page.x, page.y, page.width, page.height, true)
            love.graphics.push()
            --额外增加标题的偏移
            love.graphics.translate(page.x, page.y)
            --love.graphics.setScissor(page.x, page.y, page.width, page.height)
            --love.graphics.intersectScissor(page.x, page.y, page.width, page.height)
            --print(#self.page_children.bottom)
            for i, child in pairs(self.page_children[label]) do
                --print(#self.page_children.bottom)
                child:_draw()
            end
            love.graphics.pop()
            gui:pop_scissor_label()
        end
]]

        local page = self.pages.bottom
        -- print(page.x, page.y, page.width, page.height)
        gui:push_scissor(page.x, page.y, page.width, page.height, true)
        love.graphics.push()
        --额外增加标题的偏移

        love.graphics.translate(page.x, page.y)

        for i, child in pairs(self.page_children.bottom) do
            --print(#self.page_children.bottom)
            child:_draw()
        end
        love.graphics.pop()
        gui:pop_scissor_label()

        --绘制按钮
        for i, button in pairs(self.buttons) do
            --print(dump(buttons))
            --绘制背景
            love.graphics.setColor(self.backgroundColor)
            love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
            --绘制边框
            love.graphics.setColor(self.borderColor)
            love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
            --绘制标识点
            love.graphics.circle("fill", button.x + button.width / 2, button.y + button.height / 2, 5)
        end
        -- love.graphics.setScissor()
    else
    end
end

--视图绘制
function border_container:draw()
    if not self.visible then return end

    -- 绘制按钮背景
    if self.isPressed then
        love.graphics.setColor(self.pressedColor)
    elseif self.isHove then
        love.graphics.setColor(self.hoverColor)
    else
        love.graphics.setColor(self.backgroundColor)
    end

    --love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5)
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5)



    -- 绘制标识文本
    love.graphics.setColor(self.textColor)
    local font = self:get_font(self.font, self.textSize)
    local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    love.graphics.print(self.text, self.x + (self.width - textWidth) / 2, self.y + (self.height - textHeight) / 2)
end

--不同页面位置不一样 需要重写坐标转换函数
--全局转相对
function border_container:get_local_Position(x, y, child)
    local parent = self.parent
    local x1 = 0.0
    local y1 = 0.0;
    --判断子视图特殊标识
    --
    if child then
        --print(dump2(child))
        local label = child.border_container_page

        if label then
            -- print(child.type)
            if label == "main" then
                x1 = x - self.x
                y1 = y - self.y
                -- print(123)
            else
                local page = self.pages[label]

                y1 = y - page.y
                x1 = x - page.x
                -- print(child.type, label, y1)
            end
        else
            x1 = x - self.x
            y1 = y - self.y
        end
    else
        x1 = x - self.x
        y1 = y - self.y
    end
    --

    -- print(y1)
    if parent then
        return parent:get_local_Position(x1, y1, self)
    else
        return x1, y1;
    end
end

--相对点转换全局点
function border_container:get_world_Position(x, y, child)
    local parent = self.parent
    local x1 = 0.0
    local y1 = 0.0;
    --判断子视图特殊标识
    if child then
        --print(child.type)
        --print(dump2(child))
        local label = child.border_container_page
        if label then
            -- print(child.type)
            if label == "main" then
                -- print(self.point_in_rect(x, y, left.x + left.width, top.y + top.height, right.x, bottom.y))
                x1 = x + self.x
                y1 = y + self.y
                --print(123)
            else
                local page = self.pages[label]
                x1 = x + page.x
                y1 = y + page.y
            end
        else
            x1 = x + self.x
            y1 = y + self.y
            --  assert(false, child.type .. " 边框布局视图未正确添加独特属性")
        end
    else
        x1 = x + self.x
        y1 = y + self.y
    end
    --

    -- print(child.type)
    if parent then
        return parent:get_world_Position(x1, y1, self)
    else
        return x1, y1;
    end
end

--事件拦截机制 如果此函数返回false 则输入事件不会传递给子视图
--*通常用于 点击父视图区域外将不会触发子视图情况
function border_container:_event_intercept(x, y, child)
    --判断按钮 高优先级
    for _, button in pairs(self.buttons) do
        if self.point_in_rect(x, y, button.x, button.y, button.width, button.height) then
            return false
        end
    end
    --根据子类回调确认权限
    --判断子视图特殊标识
    if child then
        --print(dump2(child))
        local label = child.border_container_page
        if label then
            --print(child.type)
            if label == "main" then
                local top = self.pages.top
                local bottom = self.pages.bottom
                local left = self.pages.left
                local right = self.pages.right;
                --print(self.point_in_rect(x, y, left.x + left.width, top.y + top.height, right.x, bottom.y))
                --print(x, y, left.x + left.width, top.y + top.height, right.x, bottom.y)
                if self.point_in_rect(x, y, left.x + left.width, top.y + top.height, right.x - left.x - left.width, bottom.y - top.y - top.height) then
                    --  print(123)
                    return true
                else
                    return false
                end
            else
                local page = self.pages[label]
                --print(self.point_in_rect(x, y, page.x, page.y, page.width, page.height))

                if self.point_in_rect(x, y, page.x, page.y, page.width, page.height) then
                    return true
                else
                    return false
                end
            end
        else
            --没有页面标识添加到主
            --print(label, child.type .. " 边框布局视图未正确添加独特属性")
        end
    end
    --print(123)
    --默认向下传递
    return true
end

--点击
function border_container:mousepressed(id, x, y, dx, dy, istouch, pre)
    for i, button in pairs(self.buttons) do
        if self.point_in_rect(x, y, button.x, button.y, button.width, button.height) then
            button.is_presses = true --按下
            self.select_button = i   --标识
        end
    end
    local top = self.pages.top
    local bottom = self.pages.bottom
    local left = self.pages.left
    local right = self.pages.right;
    -- print(self.point_in_rect(x, y, left.x + left.width, top.y + top.height, right.x, bottom.y))
end

function border_container:mousemoved(id, x, y, dx, dy, istouch, pre) --滑动回调
    local label = self.select_button
    --print(123)
    if label then
        local button = self.buttons[label]
        local page = self.pages[label]
        if button.is_presses then
            button.is_drag = true; --拖动标识
            if page.is_unfold then
               -- self:change_page_unfold(label, false)
                if label == "top" then
                    --print(1)
                    --print(dy)
                    if page.unfold_distance + dy < 0 then
                        page.unfold_distance = 0
                    elseif page.unfold_distance + dy >= self.height - button.height * 2 then
                        -- print(2)
                    else
                        page.unfold_distance = page.unfold_distance + dy
                    end
                    -- print(22)
                    self:update_pages()
                    self:update_buttons()
                elseif label == "bottom" then
                    --print(2, dy, page.unfold_distance)
                    if page.unfold_distance - dy < 0 then
                        page.unfold_distance = 0
                    elseif page.unfold_distance - dy >= self.height - button.height * 2 then
                    else
                        page.unfold_distance = page.unfold_distance - dy
                    end
                    self:update_pages()
                    self:update_buttons()
                elseif label == "left" then
                    --print(3)
                    if page.unfold_distance + dx < 0 then
                        page.unfold_distance = 0
                    elseif page.unfold_distance + dx >= self.width - button.width * 2 then
                    else
                        page.unfold_distance = page.unfold_distance + dx
                    end
                    self:update_pages()
                    self:update_buttons()
                elseif label == "right" then
                    -- print(4)
                    if page.unfold_distance - dx < 0 then
                        page.unfold_distance = 0
                    elseif page.unfold_distance - dx >= self.width - button.width * 2 then
                    else
                        page.unfold_distance = page.unfold_distance - dx
                    end
                    self:update_pages()
                    self:update_buttons()
                end
            else --折叠状态
                -- print("dx", dx + dy)
                page.is_unfold = true
                page.unfold_distance = 0
                --self:change_page_unfold(page, false)
            end
        end
    end
end

function border_container:mousereleased(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击
    local label = self.select_button
    if label then
        local button = self.buttons[label]
        if not button.is_drag then             --触发点击事件
            if self.point_in_rect(x, y, button.x, button.y, button.width, button.height) then
                self:change_page_unfold(label) --改变页面折叠状态
                --print(123)
            end
        else

        end
        button.is_presses = false
        button.is_drag = false;
    end
    -- print(dump(self.pages[label]))
end

function border_container:on_click(id, x, y, dx, dy, istouch, pre)
    -- body
    --self:destroy()
    -- print(self:get_local_Position(x, y))
    -- print(self.pages.right.width)
end

return border_container;
