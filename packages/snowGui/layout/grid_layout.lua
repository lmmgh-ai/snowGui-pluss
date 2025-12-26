local view = require (lumenGui_path .. ".view.view")
local grid_layout = view:new()
grid_layout.__index = grid_layout

--[[
子视图属性
layout_grid="cols|rows|horizontal_lenght|vertical_length"
--
layout_weight--小于0自适应 0 按自身比例 >0按权重分配
layout_margin--子视图外边距限制
layout_margin_top
layout_margin_right
layout_margin_left
layout_margin_bottom
]]

function grid_layout:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        text            = "grid_layout",
        type            = "grid_layout",
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.8, 0.8, 1, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 0.6, 0.6, 1, 1 },
        borderColor     = { 0, 0, 0, 1 },
        --
        cellWidth       = 32, -- 单元格宽度
        cellHeight      = 32, -- 单元格高度
        cols            = 10, -- 网格列数
        rows            = 10, -- 网格行数
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

function grid_layout:init()
    -- print(dump(self:gravity_string_analysis("a|b")))
    self.width = self.cellWidth * self.cols
    self.height = self.cellHeight * self.rows
end

function grid_layout:draw()
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

    -- 绘制网格线
    love.graphics.setColor(0.5, 0.5, 0.5, 1) -- 设置线条颜色为灰色

    -- 绘制垂直线
    for i = 0, self.cols do
        local x = self.x + i * self.cellWidth
        --超出部分自动剪裁
        if x > self.x + self.width then
            break
        end
        love.graphics.line(x, self.y, x, math.min(self.y + self.rows * self.cellHeight, self.y + self.height))
    end

    -- 绘制水平线
    for i = 0, self.rows do
        local y = self.y + i * self.cellHeight
        --超出部分自动剪裁
        if y > self.y + self.height then
            break
        end
        love.graphics.line(self.x, y, math.min(self.x + self.cols * self.cellWidth, self.x + self.width), y)
    end

    -- 绘制文本
    love.graphics.setColor(self.textColor)
    local font = self:get_font(self.font, self.textSize)
    local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    love.graphics.print(self.text, self.x, self.y)
end

--改变来自子视图
function grid_layout:change_from_children(child_view)
    --更新来自子视图
    self:update_children_position(child_view)
end

--重写添加子视图或子视图改变宽高后回调
function grid_layout:change_from_self(child_view) --改变子视图数量后的回调 适用需要对子视图数量更新做出反应的视图
    --初始视图边界
    self:init_child_layout_margin(child_view)
    --初始视图网格属性
    self:update_children_grid_coordinates(child_view)
    --print("grid123")
    --返回true 通知父视图子视图自身做出改变
    return true, true
end

--------------------------
--初始化子视图外边框边界属性
function grid_layout:init_child_layout_margin(child_view)
    if child_view and child_view.layout_margin then
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

--按指定间隔字符分割
function grid_layout:string_segmentation(str, reps)
    local resultStrList = {}
    string.gsub(str, '[^' .. reps .. ']+', function(w)
        --table.insert(resultStrList, w)
        --resultStrList[w] = 0
        table.insert(resultStrList, w)
    end)
    return resultStrList
end

--将字字符串转化为顺序表
function grid_layout:gravity_string_analysis(str)
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

--更新子视图网格坐标
--根据参数更新子视图位置大小
function grid_layout:update_children_grid_coordinates(child_view)
    -- body
    if child_view then
        --获取边距
        local on_top = child_view.layout_margin_top or 0
        local on_bottom = child_view.layout_margin_bottom or 0
        local on_left = child_view.layout_margin_left or 0
        local on_right = child_view.layout_margin_right or 0
        --获取网格布局解析
        local layout_grid = {}
        if child_view.layout_grid then
            -- print(child_view.type)
            --print(child_view.layout_grid)
            layout_grid = self:gravity_string_analysis(child_view.layout_grid)
            --print(dump(layout_grid))
        else
            --默认 "1|1|v|auto"
            local cols = math.ceil(child_view.x / self.cellWidth)
            local rows = math.ceil(child_view.y / self.cellHeight)
            --print(cols, rows)
            child_view.layout_grid = cols .. "|" .. rows .. "|1|1"
            layout_grid = { cols, rows, 1, 1 }
        end
        --
        assert(#layout_grid == 4, "grid string error :", child_view.layout_grid)
        local cols = math.max(math.min(layout_grid[1], self.cols), 1)
        local rows = math.max(math.min(layout_grid[2], self.rows), 1)
        --
        child_view.x = (cols - 1) * self.cellWidth + on_left
        child_view.y = (rows - 1) * self.cellHeight + on_top
        local horizontal_length = math.min(math.max(self.cols - cols + 1, 1), layout_grid[3])
        local vertical_length = math.min(math.max(self.rows - rows + 1, 1), layout_grid[4])
        -- print(self.cols - cols)
        child_view.width = horizontal_length * self.cellWidth - on_left - on_right
        child_view.height = vertical_length * self.cellHeight - on_top - on_bottom
        -- print(child_view.type)
        -- print(cols, rows, horizontal_length, vertical_length)
    end
end

--更新子视图网格坐标
--根据子视图位置大小,更新网格参数
function grid_layout:update_children_position(child_view)
    if child_view then
        local on_top = child_view.layout_margin_top or 0
        local on_bottom = child_view.layout_margin_bottom or 0
        local on_left = child_view.layout_margin_left or 0
        local on_right = child_view.layout_margin_right or 0
        --获取行列号
        local c_row, c_col = self:toGridPosition(child_view.x, child_view.y)
        --  print(child_view.x, child_view.y, c_row, c_col)

        local rows = math.max(math.min(c_row, self.rows), 1)
        local cols = math.max(math.min(c_col, self.cols), 1)
        --更新
        -- child_view.x = (cols - 1) * self.cellWidth + on_left
        --child_view.y = (rows - 1) * self.cellHeight + on_top
        --大小
        local c_g_w = math.ceil(child_view.width / self.cellWidth)
        local c_g_h = math.ceil(child_view.height / self.cellHeight)
        --print(c_row, c_col, c_g_w, c_g_h)
        --child_view.width = c_g_w - on_left - on_right
        --child_view.height = c_g_h * self.cellHeight - on_top - on_bottom
        --赋值子视图网格属性
        child_view.layout_grid = cols .. "|" .. rows .. "|" .. c_g_w .. "|" .. c_g_h
    end
end

-- 将行列坐标转换为视图坐标
-- @param row 行号（从1开始）
-- @param col 列号（从1开始）
-- @return x, y 屏幕坐标
function grid_layout:toScreenPosition(row, col)
    local x = (col - 1) * self.cellWidth
    local y = (row - 1) * self.cellHeight
    return x, y
end

-- 将坐标转换为行列坐标
--视图坐标系
-- @param x x坐标
-- @param y y坐标
-- @return row, col 行列坐标
function grid_layout:toGridPosition(x, y)
    local col = (x) / self.cellWidth + 1
    local row = (y) / self.cellHeight + 1
    return math.floor(row), math.floor(col)
end

function grid_layout:on_click(id, x, y, dx, dy, is_touch, pre)
    -- body
    --self:destroy()
    -- print(self.type, self:get_local_Position(x, y))
    -- print("行坐标", self:toGridPosition(x, y))
    -- print(self:toScreenPosition(2, 2))
end

return grid_layout;
