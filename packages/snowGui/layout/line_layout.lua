local view = require(lumenGui_path .. ".view.view")
local line_layout = view:new()
line_layout.__index = line_layout

--[[
--子视图属性
layout_weight--小于0自适应 0 按自身比例 >0按权重分配
layout_margin--子视图外边距限制
layout_margin_top
layout_margin_right
layout_margin_left
layout_margin_bottom
--自身属性
--优先级高于其余4个属性
padding--边框内边距 限制子视图在自身位置
padding_top
padding_right
padding_left
padding_bottom
]]

function line_layout:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        text            = "line_layout",
        type            = "line_layout",
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.8, 0.8, 1, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 0.6, 0.6, 1, 1 },
        borderColor     = { 0, 0, 0, 1 },
        orientation     = "vertical", --horizontal,vertical--子视图布局方向
        gravity         = "top|left", --子视图重力
        padding         = 0,          --布局内边距(单边)
        padding_top     = 0,
        padding_right   = 0,
        padding_left    = 0,
        padding_bottom  = 0,
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

function line_layout:init()
    --初始化内边距
    if self.padding then
        if not self.padding_top then
            self.padding_top = self.padding
        end
        if not self.padding_right then
            self.padding_right = self.padding
        end
        if not self.padding_left then
            self.padding_left = self.padding
        end
        if not self.padding_bottom then
            self.padding_bottom = self.padding
        end
    end
    --初始化子视图 边距
end

function line_layout:draw()
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

--初始化子视图外边框边界属性
function line_layout:init_child_layout_margin(child_view)
    if child_view.layout_margin then
        if not self.layout_margin_top then
            self.layout_margin_top = self.layout_margin
        end
        if not self.layout_margin_right then
            self.layout_margin_right = self.layout_margin
        end
        if not self.layout_margin_left then
            self.layout_margin_left = self.layout_margin
        end
        if not self.layout_margin_bottom then
            self.layout_margin_bottom = self.layout_margin
        end
    end
end

--重写添加子视图或子视图改变宽高后回调
function line_layout:change_from_self(child_view) --改变子视图数量后的回调 适用需要对子视图数量更新做出反应的视图
    --self:update_weiht()
    --print(123)
    --初始化子视图外边框边界属性
    if child_view then
        self:init_child_layout_margin(child_view)
    end
    --自身宽高适应子视图
    self:adapt_children_wh()
    --更新重力
    self:update_gravity()
    return true, true --返回true 通知父视图子视图自身做出改变
end

--重写当子视图改变尺寸 回调
function line_layout:change_from_children(child_view)
    if child_view then
        self:init_child_layout_margin(child_view)
    end
    --自身宽高适应子视图
    -- self:adapt_children_wh()
    --更新重力
    self:update_gravity()
    return true
end

--按指定间隔字符分割
function line_layout:string_segmentation(str, reps)
    local resultStrList = {}
    string.gsub(str, '[^' .. reps .. ']+', function(w)
        --table.insert(resultStrList, w)
        resultStrList[w] = 0
    end)
    return resultStrList
end

--将字字符串转化为表
--线性布局重力 字符安装指定的先后顺序执行 类似手摇晃箱子 调整里边的方块
function line_layout:gravity_string_analysis(str)
    -- body
    local str = string.lower(str) --将参数大写转为小写
    return self:string_segmentation(str, "|")
end

--更新权重
function line_layout:update_weight()
    local ele = self.children --获取子视图
    --print(dump(ele))
    --[[
    if not rawget(self, "w") then --未重写宽
        --窗口宽高
        local dw, dh = love.window.getMode()
        self.w = dw
    end
    if not rawget(self, "h") then --未重写高
        --窗口宽高
        local dw, dh = love.window.getMode()
        self.h = dh;
    end]]
    --抽象了写法 可以自适应水平与垂直
    local abstract_value1 = "height"
    local abstract_value2 = "width"
    if self.orientation then --判断自身布局方向
        if self.orientation == "vertical" then
            abstract_value1 = "height"
            abstract_value2 = "width"
        end
        if self.orientation == "horizontal" then
            abstract_value1 = "width"
            abstract_value2 = "height"
        end
    end

    -- print(self.w, self.h)
    --print(abstract_value1)

    local weight = 0;    --整体权重
    --读取整体权重
    local all_buffer = 0 --子布局绝对宽/高度集合
    --先将子视图宽高储存起来
    for i, c in ipairs(ele) do
        --优先使用子布局的宽高
        -- print(c[abstract_value1])
        --print(i)
        if c.weight then --如果存在权重
            if c.weight ~= -1 and c.weight ~= 0 then
                assert(type(c.weight) == "number", "权重值必须是数字")
                weight = weight + c.weight;
            else
                -- weight = weight + 1;
            end
        else
            if c[abstract_value1] and c[abstract_value1] ~= -1 then
                all_buffer = all_buffer + c[abstract_value1] --储存到整体缓存
                -- print('weight' .. c.weight)
            end
        end
    end
    if weight == 0 then --没有权重 弹出
        return;
    end
    --print(weight, all_buffer)
    --剩余高度
    local fwh = self[abstract_value1] - all_buffer; --自身宽/高减去子元素的权重
    local cwh;                                      --权重均值
    if fwh > 0 then                                 --子布局的绝对宽高度是大于宽高
        --权重均分剩余高度
        cwh = math.floor(fwh / weight);             --1权重的高度
    else
        --权重均分额外高度 超出父布局部分
        cwh = math.floor(math.abs(fwh) / weight); --1权重的高度
    end
    --print(fwh, cwh)
    --分配权重
    for i, c in ipairs(ele) do
        if c[abstract_value1] and c[abstract_value1] ~= -1 then --拥有绝对宽高不参与权重分配
        else
            if c.weight and c.weight ~= -1 and c.weight ~= 0 then
                c[abstract_value1] = c.weight * cwh;
            else
                c[abstract_value1] = cwh;
            end
        end
        --print(c.w)
        if c[abstract_value2] then
            if c[abstract_value2] == -1 then
                c[abstract_value2] = self[abstract_value2]
            end
        else
            c[abstract_value2] = self[abstract_value2]
        end
    end


    --
end

--更新重力
function line_layout:update_gravity()
    local ele = self.children --获取子视图
    -- print(dump2(ele))
    -- print(dump(ele))
    --子视图坐标是相对父视图的

    if self.gravity and type(self.gravity) == "string" then
        local gravity_tab = self:gravity_string_analysis(self.gravity) --解析重力字符
        --print(dump(gravity_tab))
        --print(dump(gravity_tab))
        local padding_top = self.padding_top or 0
        local padding_bottom = self.padding_bottom or 0
        local padding_right = self.padding_right or 0
        local padding_left = self.padding_left or 0
        --首先解析居中属性
        if gravity_tab.center then
            if self.orientation == "vertical" then
                --将横坐标居中
                local max;                --参考
                local cx = self.width / 2 --父布局中心横坐标
                for i, child in ipairs(ele) do
                    child.x = cx - child.width / 2
                end
                --将纵坐标居中
                local ch = 0;               --子布局高度和
                local cey = self.height / 2 --父布局中心纵坐标
                for i, child in ipairs(ele) do
                    local layout_margin_top = child.layout_margin_top or 0
                    local layout_margin_bottom = child.layout_margin_bottom or 0
                    ch = ch + child.height + layout_margin_top + layout_margin_bottom
                end
                local sy = cey - ch / 2 --子布局初始高度
                -- print(sy)


                for i, child in ipairs(ele) do
                    local layout_margin_top = child.layout_margin_top or 0
                    local layout_margin_bottom = child.layout_margin_bottom or 0
                    child.y = sy + layout_margin_top;
                    sy = sy + child.height + layout_margin_top + layout_margin_bottom
                end
            elseif self.orientation == "horizontal" then
                --将纵坐标居中
                local cy = self.height / 2 --父布局中心纵坐标
                for i, child in ipairs(ele) do
                    child.y = cy - child.height / 2
                end
                --将横坐标居中
                local cw = 0              --总宽
                local sw = self.width / 2 --父布局中心横坐标
                for i, child in ipairs(ele) do
                    local layout_margin_left = child.layout_margin_left or 0
                    local layout_margin_right = child.layout_margin_right or 0
                    cw = cw + child.width + layout_margin_right + layout_margin_left;
                end
                local sx = sw - cw / 2 --子布局初始高度
                for i, child in ipairs(ele) do
                    local layout_margin_left = child.layout_margin_left or 0
                    local layout_margin_right = child.layout_margin_right or 0
                    child.x = sx + layout_margin_left;
                    sx = sx + child.width + layout_margin_left + layout_margin_right
                end
            end
        end
        --
        if gravity_tab.left then
            if self.orientation == "vertical" then
                for i, child in ipairs(ele) do
                    --print(dump2(c))
                    -- print(i)
                    local layout_margin_left = child.layout_margin_left or 0
                    child.x = padding_left + layout_margin_left;
                end
            elseif self.orientation == "horizontal" then
                local sx = padding_left
                for i, c in ipairs(ele) do
                    local layout_margin_left = c.layout_margin_left or 0
                    local layout_margin_right = c.layout_margin_right or 0
                    c.x = sx + layout_margin_left;
                    sx = sx + c.width + layout_margin_left + layout_margin_right
                end
            end
        end
        --
        if gravity_tab.right then
            if self.orientation == "vertical" then
                for i, c in ipairs(ele) do
                    local layout_margin_right = c.layout_margin_right or 0
                    c.x = self.width - c.width - padding_right - c.layout_margin_right;
                end
            elseif self.orientation == "horizontal" then --bottom
                local cw = 0;                            --子布局高度和
                for i, c in ipairs(ele) do
                    local layout_margin_left = c.layout_margin_left or 0
                    local layout_margin_right = c.layout_margin_right or 0
                    cw = cw + c.width + layout_margin_right + layout_margin_left
                end
                local sx = self.width - cw - padding_right --子布局初始位置
                for i, c in ipairs(ele) do
                    local layout_margin_left = c.layout_margin_left or 0
                    local layout_margin_right = c.layout_margin_right or 0
                    c.x = sx + layout_margin_left;
                    sx = sx + c.width + layout_margin_left + layout_margin_right
                end
            end
        end
        --
        if gravity_tab.top then
            if self.orientation == "vertical" then
                local sy = padding_top
                for i, c in ipairs(ele) do
                    local layout_margin_top = c.layout_margin_top or 0
                    local layout_margin_bottom = c.layout_margin_bottom or 0
                    c.y = sy + layout_margin_top;
                    sy = sy + c.height + layout_margin_top + layout_margin_bottom
                end
            elseif self.orientation == "horizontal" then --bottom
                for i, c in ipairs(ele) do
                    local layout_margin_top = c.layout_margin_top or 0
                    c.y = padding_top + layout_margin_top;
                end
            end
        end
        --
        if gravity_tab.bottom then
            if self.orientation == "vertical" then
                local ch = 0; --子布局高度和
                for i, c in ipairs(ele) do
                    local layout_margin_top = c.layout_margin_top or 0
                    local layout_margin_bottom = c.layout_margin_bottom or 0
                    ch = ch + c.height + layout_margin_top + layout_margin_bottom
                end
                local sy = self.height - ch - padding_bottom --子布局初始位置
                for i, c in ipairs(ele) do
                    local layout_margin_top = c.layout_margin_top or 0
                    local layout_margin_bottom = c.layout_margin_bottom or 0
                    c.y = sy + layout_margin_top;
                    sy = sy + c.height + layout_margin_top + layout_margin_bottom
                end
            elseif self.orientation == "horizontal" then --bottom
                for i, c in ipairs(ele) do
                    local layout_margin_bottom = c.layout_margin_bottom or 0
                    c.y = self.height - c.height - padding_bottom - layout_margin_bottom;
                end
            end
        end
    else
        --assert(false,"重力解析错误:"..)
    end
end

--根据布局方向适应子视图宽高
--竖向 高不小于最子视图之和 宽不小于子视图
function line_layout:adapt_children_wh()
    if self.orientation == "vertical" then
        local mw, ch = 0, 0
        for _, child in ipairs(self.children) do
            --print(mw, child.width)
            --print(child.type)
            if mw < child.width then
                local layout_margin_right = child.layout_margin_right or 0
                local layout_margin_left = child.layout_margin_left or 0
                mw = child.width + layout_margin_right + layout_margin_left
            end
            local layout_margin_top = child.layout_margin_top or 0
            local layout_margin_bottom = child.layout_margin_bottom or 0
            ch = ch + child.height + layout_margin_top + layout_margin_bottom
        end
        if ch > self.height then
            local padding_top = self.padding_top or 0
            local padding_bottom = self.padding_bottom or 0
            self.height = ch + padding_top + padding_bottom
        end
        if mw > self.width then
            local padding_right = self.padding_right or 0
            local padding_left = self.padding_left or 0
            self.weight = mw + padding_right + padding_left
        end
    end
    if self.orientation == "horizontal" then
        local cw, mh = 0, 0
        for _, child in ipairs(self.children) do
            if mh < child.height then
                local layout_margin_top = child.layout_margin_top or 0
                local layout_margin_bottom = child.layout_margin_bottom or 0
                mh = child.height + layout_margin_top + layout_margin_bottom
            end
            local layout_margin_right = child.layout_margin_right or 0
            local layout_margin_left = child.layout_margin_left or 0
            cw = cw + child.width + layout_margin_right + layout_margin_left
        end
        if mh > self.height then
            local padding_top = self.padding_top or 0
            local padding_bottom = self.padding_bottom or 0
            self.height = mh + padding_top + padding_bottom
        end
        if cw > self.width then
            local padding_right = self.padding_right or 0
            local padding_left = self.padding_left or 0
            self.weight = cw + padding_right + padding_left
        end
    end
end

function line_layout:on_click(id, x, y, dx, dy, is_touch, pre)
    -- body
    --self:destroy()
    print(self.type, self:get_local_Position(x, y))
end

return line_layout;
