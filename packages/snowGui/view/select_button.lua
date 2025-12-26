local view = require (lumenGui_path .. ".view.view")
local select_button = view:new()
select_button.__index = select_button
function select_button:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type               = "select_button", --类型
        text               = "select_button",
        textColor          = { 0, 0, 0, 1 },
        hoverColor         = { 0.8, 0.8, 1, 1 },
        pressedColor       = { 0.6, 1, 1, 1 },
        backgroundColor    = { 0.6, 0.6, 1, 1 },
        borderColor        = { 0, 0, 0, 1 },
        --
        out_circle_color   = { 0.8, 0.8, 0.8 }, --外圆颜色
        inner_circle_color = { 0.2, 0.6, 1 },   --内圆颜色
        radius             = 8,                 -- 圆形按钮半径
        itemHeight         = 20,                --元素高度
        max_text_width     = 0,                 --元素文字最大宽度
        gap                = 10,                --优化间隔
        items              = {
            { text = "select_button" },

        },                     --标签集合
        out_items          = { --输出标签
            --text = false,
        },
        --
        x                  = 0,
        y                  = 0,
        width              = 50,
        height             = 50,
        --
        parent             = nil, --父视图
        name               = "",  --以自己内存地址作为唯一标识
        id                 = "",  --自定义索引
        children           = {},  -- 子视图列表
        _layer             = 1,   --图层
        _draw_order        = 1,   --默认根据 数值越大在当前图层越在前(目前视图在图层1起作用)
        gui                = nil, --管理器索引
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

--初始化
function select_button:init()
    for i, item in ipairs(self.items) do
        item.is_select = false; --初始化被选择元素状态
    end
end

function select_button:on_create(...)
    --更新选择视图
    self:update_item() --更新宽高
end

--重写自定义输出函数
function select_button:self_to_table(key, value, out_table)
    -- print(key)
    if key == "items" then
        out_table.items = value
        -- print(out_table.items)
    end
end

--添加标签
function select_button:add_text(text)
    if type(text) == "string" then
        table.insert(self.items, { text = text, is_select = false })
        self.out_items[text] = false
    elseif type(text) == "table" then
    end
end

--增加新选项调整控件宽高
function select_button:update_item()
    self.height = #self.items * self.itemHeight
    local max_text_width = 0
    local font = self:get_font(self.font, self.textSize)

    for i, c in ipairs(self.items) do
        if max_text_width ~= 0 then
            if tonumber(font:getWidth(c.text)) >= max_text_width then
                max_text_width = tonumber(font:getWidth(c.text))
            end
        else
            max_text_width = tonumber(font:getWidth(c.text))
        end
    end
    self.max_text_width = max_text_width
    self.width = self.itemHeight + max_text_width + self.gap * 3
end

--绘图
function select_button:draw()
    if not self.visible then return end


    love.graphics.setColor(self.backgroundColor)
    -- 绘制背景
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 1)
    love.graphics.setColor(self.borderColor)
    -- 绘制边框
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 1)

    if self.isPressed then
        love.graphics.setColor(self.pressedColor)
    elseif self.isHover then
        love.graphics.setColor(self.hoverColor)
    else
        love.graphics.setColor(self.backgroundColor)
    end

    -- 设置线条宽度
    --love.graphics.setLineWidth(2)
    local font = self:get_font(self.font, self.textSize)
    --local textWidth = font:getWidth(sel.text)
    local textHeight = font:getHeight()
    for i, sel in pairs(self.items) do
        local itemHeight = self.itemHeight --元素高度
        local gap = self.gap
        local radius = textHeight - 4      --宽高

        -- 绘制外圆
        local x = self.x
        local y = self.y + ((i * itemHeight) - itemHeight)
        local rx = x + itemHeight / 2 + textHeight
        local ry = y + itemHeight / 2
        --

        local lx = self.x + self.width - self.max_text_width - 4
        local ly = ry - textHeight / 2
        if sel.is_select then
            -- 如果被选中，绘制实心圆
            love.graphics.setColor(self.inner_circle_color) -- 蓝色
            love.graphics.circle("fill", rx, ry, radius)
            love.graphics.setColor(1, 1, 1)                 -- 白色边框
            love.graphics.circle("line", rx, ry, radius)
        end
        -- 如果未被选中，绘制空心圆
        love.graphics.setColor(self.out_circle_color) -- 灰色
        love.graphics.circle("line", rx, ry, radius)
        --love.graphics.rectangle("line", x, y, itemHeight, itemHeight, 5)
        love.graphics.setColor(self.textColor)
        love.graphics.print(sel.text, lx, ly)
    end
end

--根据点击位置获取点击选项
function select_button:get_count(x1, y1) --获取鼠标焦点元素
    local fact_y = y1
    local height = self.itemHeight       --元素真实高度
    return (fact_y - (fact_y % height)) / height + 1
end

function select_button:on_click(id, x, y, dx, dy, istouch, pre)
    -- body
    --self:destroy()
    local x1, y1 = self:get_local_Position(x, y) --获取局部点
    local count = self:get_count(x1, y1)         --判断项
    local sel = self.items[count]
    local out_items = self.out_items             --输出项
    if sel then                                  --判断项存在
        if sel.is_select then
            sel.is_select = false
            out_items[sel.text] = false
        else
            sel.is_select = true
            out_items[sel.text] = true
        end
        return self:change_state(self.out_items) --执行回调
    else
        assert(false, "select_button 错误")
    end

    --print(self:get_local_Position(x, y))
end

--获取具体标签状态
function select_button:get_select(text) --根据标签获取状态
    return self.out_items[text];
end

--返回所有选中标签
function select_button:get_items() --获取所有选中标签
    return self.out_items;
end

----------------回调
--状态被改变时调用函数

function select_button:change_state(out_items)
    --items
    --如何索引状态 sellects.text
    --否定状态 nil or false
end

return select_button;
