local view = require (lumenGui_path .. ".view.view")
local tab_control = view:new()
tab_control.__index = tab_control
function tab_control:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type              = "tab_control",
        title             = "tab_control", -- 窗口标题
        is_title_Dragging = false,         -- 是否正在拖拽
        dragOffsetX       = 0,             -- 拖拽时的X偏移量
        dragOffsetY       = 0,             -- 拖拽时的Y偏移量
        on_page           = nil,           --当前选中的页面
        items             = {
            { name = "设置" },
            { name = "编辑" },
            { name = "关于" },
        },
        titleBarHeight    = 25,                     -- 标题栏高度
        backgroundColor   = { 0.9, 0.9, 0.9, 0.9 }, -- 背景颜色
        titleBarColor     = { 0.2, 0.4, 0.8, 1 },   -- 标题栏颜色
        borderColor       = { 0.1, 0.1, 0.1, 1 },   -- 边框颜色
        textColor         = { 1, 1, 1, 1 },         -- 文字颜色
        buttons           = {},                     -- 窗口按钮集合
        content           = "",                     -- 窗口内容
        visible           = true,                   -- 窗口是否可见
        --
        x                 = x or 0,
        y                 = y or 0,
        width             = width or 50,
        height            = height or 50,
        --
        parent            = nil, --父视图
        name              = "",  --以自己内存地址作为唯一标识
        id                = "",  --自定义索引
        children          = {},  -- 子视图列表
        _layer            = 1,   --图层
        _draw_order       = 1,   --默认根据 数值越大在当前图层越在前(目前视图在图层1起作用)
        gui               = nil, --管理器索引
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

function tab_control:_init()
    -- body
    self.on_page = self.items[1] --初始选择
    self.on_page.is_presses = true;
end

--暂时废弃 更新item
function tab_control:update_items()
    item_width = self.width / #self.items
    for i, item in ipairs(self.items) do
        local font = self:get_font(self.font, self.textSize)
        local textWidth = font:getWidth(" " .. item.name .. " ")
        local textHeight = font:getHeight()
        item.x = c_w + self.x
        item.y = self.y
        item.width = item_width
        item.height = self.textHeight
        item.is_unfold = false;
        self.items.count = i; --数量
    end
end

--将子视图添加到指定页面
function tab_control:add_page_view(page_name, view)
    local page;
    for i, c in pairs(self.items) do
        -- print(i, c.name, page_name)
        if c.name == page_name then
            page = c;
            break
        else
            --return assert(true, page_name .. " 页面不存在")
        end
    end
    assert(page, page_name .. " error: not find page_name ")
    --
    local view = self:add_view(view)
    if page.children then
        table.insert(page.children, view)
    else
        page.children = {}
        table.insert(page.children, view)
    end
    --print(page_name)
end

--额外带标题栏需要重写绘图函数
function tab_control:_draw()
    if self.visible then
        local font = self:get_font(self.font, self.textSize)
        love.graphics.setFont(font)
        self:draw()
        -- 绘制子视图
        --开启剪裁
        love.graphics.push()
        --额外增加标题的偏移
        love.graphics.translate(self.x, self.y + self.titleBarHeight)
        love.graphics.setScissor(self.x, self.y, self.width, self.height)
        if self.on_page and self.on_page.children then
            for i, child in pairs(self.on_page.children) do
                --print(i)
                child:_draw()
            end
        end
        --关闭剪裁
        love.graphics.setScissor()
        love.graphics.pop()
    else
    end
end

function tab_control:draw()
    if not self.visible then return end


    -- 绘制窗口背景
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    -- 绘制标题栏
    love.graphics.setColor(self.titleBarColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.titleBarHeight)

    -- 绘制窗口边框
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.titleBarHeight)

    -- 绘制标题文字
    love.graphics.setColor(self.textColor)
    love.graphics.print(self.title, self.x + 10, self.y + 5)

    -- 绘制顶栏按钮
    --即时获取子元素宽
    local item_width = self.width / #self.items
    for i, item in ipairs(self.items) do
        -- 设置颜色
        -- print(i)
        --绘制选中背景
        if item.is_presses then
            love.graphics.setColor(self.hoverColor)
            love.graphics.rectangle("fill", (i - 1) * item_width + self.x, self.y, item_width,
                self.y + self.titleBarHeight, 5)
        end
        -- 绘制文本
        love.graphics.setColor(self.textColor)
        local font = self:get_font(self.font, self.textSize)
        local textWidth = font:getWidth(item.name)
        local textHeight = font:getHeight()
        love.graphics.print(item.name, self.x + (i - 1) * item_width + (item_width - textWidth) / 2,
            self.y + (self.titleBarHeight - textHeight) / 2)
    end
    --除去顶栏绘图坐标系
    --love.graphics.push()
    --额外增加标题的偏移
    love.graphics.push()
    love.graphics.translate(self.x, self.y + self.titleBarHeight)
    love.graphics.setScissor(self.x, self.y, self.width, self.height)
    --
    -- love.graphics.rectangle("fill", 0, 0, 50, 50)
    --
    love.graphics.setScissor()
    love.graphics.pop()
end

--额外带标题栏需要重写传递给子视图的位置
--全局点转换相对点
function tab_control:get_local_Position(x, y, child)
    local parent = self.parent
    local x1 = x - self.x
    local y1 = y - self.y - self.titleBarHeight
    if parent then
        return parent:get_local_Position(x1, y1, self)
    else
        return x1, y1;
    end
end

--相对点转换全局点
function tab_control:get_world_Position(x, y, child)
    local parent = self.parent
    local x1 = x + self.x
    local y1 = y + self.y + self.titleBarHeight
    if parent then
        return parent:get_world_Position(x1, y1, self)
    else
        return x1, y1;
    end
end

-- 检测点全局点是否在视图内
function tab_control:containsPoint(x, y)
    local absX, absY = self:get_world_Position(0, -self.titleBarHeight, self)
    --print(absX, absY)
    return x >= absX and x <= absX + self.width and
        y >= absY and y <= absY + self.height
end

-- 检测点全局点是否在视图内
-- 判断鼠标是否在视图内使用此的此函数
function tab_control:containsPoint(x, y)
    --local absX, absY = self:get_world_Position(0, 0, self)
    local x1, y1 = self:get_local_Position(x, y + self.titleBarHeight, self)
    --父视图可以回传空参数 拦截点击事件
    -- print(x1, y1)
    if x1 and y1 then
        return x1 >= 0 and x1 <= self.width and
            y1 >= 0 and y1 <= self.height
    else
        return false
    end
end

-- 检查鼠标是否在标题栏内
function tab_control:isMouseInTitleBar(mx, my)
    return mx >= 0 and mx <= self.x + self.width and
        my >= -self.titleBarHeight and my <= self.titleBarHeight
end

--点击
function tab_control:on_click(id, x, y, dx, dy, istouch, pre)
    local x1, y1 = self:get_local_Position(x, y)
    -- print(self:isMouseInTitleBar(x1, y1))
    if self:isMouseInTitleBar(x1, y1) then --点在标题栏
        --获取标题栏按钮宽
        local item_width = self.width / #self.items
        for i, item in ipairs(self.items) do
            local ix = (i - 1) * item_width + self.x
            local iy = self.y
            local iw = item_width
            local ih = self.y + self.titleBarHeight
            -- print(x1, y1, ix, iy, iw, ih)
            if self.point_in_rect(x1, y1 + self.titleBarHeight, ix, iy, iw, ih) then --点击了某元素
                -- print(x, y, ix, iy, iw, ih)
                --print(item.name)
                self.on_page = item; --改变当前选择
                item.is_presses = true;
                --子视图可见
                if item.children then
                    for i, view in ipairs(item.children) do
                        view:set_visible(true)
                        print(1)
                    end
                end
            else
                item.is_presses = false;
                --其他页面子视图影藏
                if item.children then
                    for i, view in ipairs(item.children) do
                        view:set_visible(false)
                    end
                end
            end
        end
    end
    local absX, absY = self:get_world_Position(0, -self.titleBarHeight, self)
    print("tab", x1, y1)
end

return tab_control;
