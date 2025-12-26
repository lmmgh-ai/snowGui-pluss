local view = require(lumenGui_path .. ".view.view")
local fold_container = view:new()
fold_container.__index = fold_container
function fold_container:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type            = "fold_container", --类型
        text            = "fold_container", --显示的文本
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.8, 0.8, 1, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 0.6, 0.6, 1, 1 },
        borderColor     = { 0, 0, 0, 1 },
        is_unfold       = false, --是否展开扩展区域
        extension       = {},    --扩展点击区域 可以是表 是对象
        -- extension_x      = 0,     --扩展的坐标
        -- extension_y      = 0,
        -- extension_width  = 100,
        --  extension_height = 100,
        --
        x               = 0,
        y               = 0,
        width           = 100,
        height          = 30,
        --展开时内容高度加标题高度
        titleBarHeight  = 20,  --标题栏高
        contentHeight   = 100, --内容高度

        -----必须重写属性
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

function fold_container:init()
    --
    if self.is_unfold then
        self.height = self.titleBarHeight + self.contentHeight
    else
        self.height = self.titleBarHeight
    end
end

--重写
--如果返回值为true 则通知父视图与子视图
--默认不通知 只有需要响应手动通知
function fold_container:change_from_self(child_view)
    --
    --print(1)

    self:adapt_children_wh()
    --
    --返回两个参数 true通知父布局更新 true通知自视图更新
    return true, false;
end

--重写当子视图改变尺寸 回调
function fold_container:change_from_children(child_view)
    self:adapt_children_wh()
    return true;
end

--适应子视图宽高
function fold_container:adapt_children_wh()
    if #self.children > 0 then
        local mw, mh = 0, 0
        for _, child in ipairs(self.children) do
            if mw < child.width then
                mw = child.width
            end
            if mh < child.height then
                mh = child.height
            end
        end
        self.width = mw
        self.contentHeight = mh
    end
end

-- 添加子视图
--根据默认折叠状态确认是否隐藏添加的子视图
function fold_container:add_view(child_view)
    local name = tostring(child_view) --以自己地址为唯一标识
    child_view.name = name;           --设置唯一标识
    --初始化可见 跟随父视图
    child_view.visible = self.is_unfold and self.visible
    --添加到父视图
    table.insert(self.children, child_view)
    --
    child_view.parent = self;            --为chlid赋值父视图
    child_view._layer = self._layer + 1; --设置图层为父视图下一层
    -- print(self.type)
    if self.gui then
        child_view.gui = self.gui;
        self.gui:add_view(child_view) --添加到视图管理器
        --自身尺寸改变回调
        self:_change_from_self(child_view)
    end
    return child_view
end

--
--额外带标题栏需要重写绘图函数
function fold_container:_draw()
    if self.visible then
        local font = self:get_font(self.font, self.textSize)
        love.graphics.setFont(font)
        local x, y = self:get_world_Position(0, 0)
        --print(x, y)
        -- love.graphics.setScissor(x, y, self.width, self.height)
        -- print(dump(self.gui:push_scissor(self.x, self.y, self.width, self.height)))
        -- self.gui:push_scissor(self.x, self.y, self.width, self.height)
        -- 绘制子视图
        love.graphics.push()
        --额外增加标题的偏移
        love.graphics.translate(self.x, self.y + self.titleBarHeight)

        if self.is_unfold then --视图展开绘制子视图
            --剪裁
            --love.graphics.intersectScissor(x, y, self.width, self.height)
            for i, child in pairs(self.children) do
                --print(i)
                child:_draw()
            end
        end
        love.graphics.pop()
        --self.gui:pop_scissor_label()
        self:draw()
        -- love.graphics.setScissor()
    end
end

--绘图
function fold_container:draw()
    if not self.visible then return end
    if self.hover then
        --  print(1)
    end

    -- 绘制背景
    love.graphics.setColor(self.backgroundColor)

    love.graphics.rectangle("fill", self.x, self.y, self.width, self.titleBarHeight)
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.titleBarHeight)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    --love.graphics.rectangle("fill", 0, 0, 5, 5, 5)
    local cx = self.x + self.width / 2
    local cy = self.y + self.titleBarHeight / 2
    -- 绘制文本
    love.graphics.setColor(self.textColor)
    local font = self:get_font(self.font, self.textSize)
    local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    love.graphics.print(self.text, cx - textWidth / 2, cy - textHeight / 2)
    --
    local rx = self.x + self.width - 5
    if self.is_unfold then --展开状态
        --绘制展开按钮
        love.graphics.polygon("fill", rx, cy + textHeight / 4, rx - textHeight,
            cy + textHeight / 4, rx - textHeight / 2,
            cy - textHeight / 4)
    else --收起状态
        --绘制展开按钮
        love.graphics.polygon("fill", rx, cy - textHeight / 4, rx - textHeight,
            cy - textHeight / 4, rx - textHeight / 2,
            cy + textHeight / 4)
    end
    -- 绘制扩展菜单项
    --love.graphics.setFont(self.font)
    --绘图偏移 绘图转化为局部坐标
    --love.graphics.push()
    -- love.graphics.translate(self.x, self.y + self.height)
    if self.is_unfold then --展开状态
        love.graphics.rectangle("line", self.x, self.y,
            self.extension_width,
            self.extension_height)
    end
    -- love.graphics.pop()
end

function fold_container.point_in_rect(x, y, rectX, rectY, width, height) --点是否在矩形内
    return x >= rectX
        and x <= rectX + width
        and y >= rectY
        and y <= rectY + height
end

--额外带标题栏需要重写传递给子视图的位置
--全局点转换相对点
function fold_container:get_local_Position(x, y, child)
    local parent = self.parent
    local x1, y1 = x - self.x, y - self.y
    if child then
        y1 = y - self.y - self.titleBarHeight
    end
    if parent then
        return parent:get_local_Position(x1, y1)
    else
        return x1, y1;
    end
end

--相对点转换全局点
function fold_container:get_world_Position(x, y, child)
    local parent = self.parent
    local x1, y1 = x + self.x, y + self.y
    if child then
        y1 = y + self.y + self.titleBarHeight
    end
    if parent then
        return parent:get_world_Position(x1, y1)
    else
        return x1, y1;
    end
end

-- 检测点全局点是否在视图内
-- 判断鼠标是否在视图内使用此函数
--需要额外判断选项的位置

function fold_container:containsPoint(x, y)
    -- local absX, absY = self:get_world_Position(0, 0, self)
    local x1, y1 = self:get_local_Position(x, y, self)
    --print(x, y, x1, y1)
    --父视图可以回传空参数 拦截点击事件
    if x1 and y1 then
        --print(absX)
        if x1 >= 0 and x1 <= self.width and
            y1 >= -self.titleBarHeight and y1 <= self.height - self.titleBarHeight then
            return true
        end
    end
    return false
end

function fold_container:on_hover()
    -- print("获取焦点")
end

function fold_container:on_click(id, x, y, dx, dy, istouch, pre)
    local x1, y1 = self:get_local_Position(x, y)
    --print(x1, y1)
    --只有点击按钮才回触发折叠展开
    --print(self.y)
    if self.point_in_rect(x1, y1, 0, 0,
            self.width,
            self.titleBarHeight) then
        --print(1)

        if not self.is_unfold then
            --显示子视图
            self.is_unfold = true
            self:set_children_visible(true)
            self:set_height(self.titleBarHeight + self.contentHeight)
        else
            --隐藏子视图
            self.is_unfold = false
            self:set_children_visible(false)
            self:set_height(self.titleBarHeight)
        end
    end
    -- print(self.is_unfold)
end

return fold_container;
