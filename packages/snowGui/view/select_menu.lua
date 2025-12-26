local view = require (lumenGui_path .. ".view.view")
local select_menu = view:new()
select_menu.__index = select_menu
function select_menu:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type                = "select_menu", --类型
        text                = "select_menu",
        textColor           = { 0, 0, 0, 1 },
        hoverColor          = { 0.8, 0.8, 1, 1 },
        pressedColor        = { 0.6, 1, 1, 1 },
        backgroundColor     = { 0.6, 0.6, 1, 1 },
        borderColor         = { 0, 0, 0, 1 },
        --
        select_button_color = { 0.2, 0.6, 1 }, --选择小按钮颜色
        items               = {
            { text = "select_menu" },
            --[[
            { text = "文件1" },
            { text = "编辑1" },
            { text = "关于1" },
            { text = "设置1" },
            { text = "编辑1" },
            { text = "关于1" },
             ]]
        },
        is_unfold           = false, --是否展开扩展区域
        extension           = {},    --扩展点击区域 可以是表 是对象
        item_height         = 20,    --选项的高
        --
        x                   = 0,
        y                   = 0,
        width               = 100,
        height              = 20,
        -----必须重写属性
        parent              = nil, --父视图
        name                = "",  --以自己内存地址作为唯一标识
        id                  = "",  --自定义索引
        children            = {},  -- 子视图列表
        _layer              = 1,   --图层
        _draw_order         = 1,   --默认根据 数值越大在当前图层越在前(目前视图在图层1起作用)
        gui                 = nil, --管理器索引
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

function select_menu:init()
    self:update_items() --初始元素
    for _, item in ipairs(self.items) do
        if self.text == item.text then
            return --终止函数
        end
    end
    assert((#self.items > 0), "select_menu not items")
    self.text = self.items[1].text  --初始选择
    self.items[1].is_presses = true --初始点击为选择
    self:on_select_item(self.text)  --选择改变回调
end

--重写自定义输出函数
function select_menu:self_to_table(key, value, out_table)
    -- print(key)
    if key == "items" then
        out_table.items = value
        -- print(out_table.items)
    end
end

--为items中元素更新/添加属性
function select_menu:update_items()
    --local screenWidth = love.graphics.getWidth()
    local f_item = self.items
    local width = self.width
    local height = self.item_height
    local c_h = 0 --元素总高
    for i, item in ipairs(f_item) do
        item.x = 0
        item.y = c_h + self.height
        item.width = width
        item.height = height
        item.is_presses = false;
        f_item.count = i
        c_h = c_h + height
    end
    f_item.x = 0
    f_item.y = self.height
    f_item.width = width
    f_item.height = c_h
    --print(dump(f_item))
end

--绘图
function select_menu:draw()
    if not self.visible then return end


    -- 绘制背景
    love.graphics.setColor(self.backgroundColor)

    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5)
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 3)
    --love.graphics.rectangle("fill", 0, 0, 5, 5, 5)
    local cx = self.x + self.width / 2
    local cy = self.y + self.height / 2
    -- 绘制文本
    love.graphics.setColor(self.textColor)
    local font = self:get_font(self.font, self.textSize)
    local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    love.graphics.print(self.text, cx - textWidth / 2, cy - textHeight / 2)
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
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    if self.is_unfold then --展开状态
        local items = self.items
        -- 绘制菜单背景
        love.graphics.setColor(self.backgroundColor)
        love.graphics.rectangle("fill", items.x, items.y, items.width, items.height, 5)
        love.graphics.setColor(self.borderColor)
        love.graphics.rectangle("line", items.x, items.y, items.width, items.height, 5)
        for i, item in ipairs(items) do
            -- 绘制文本
            love.graphics.setColor(self.textColor)
            local textWidth = font:getWidth(item.text)
            local textHeight = font:getHeight()
            love.graphics.print(item.text, item.x + (item.width - textWidth) / 2, item.y + (item.height - textHeight) / 2)
            if item.is_presses then --被选中
                --选择按钮
                love.graphics.setColor(self.select_button_color)
                love.graphics.circle("fill", item.x + item.height / 2,
                    item.y + item.height / 2, item.height / 4)
            end
        end
    end
    love.graphics.pop()
end

function select_menu.point_in_rect(x, y, rectX, rectY, width, height) --点是否在矩形内
    return x >= rectX
        and x <= rectX + width
        and y >= rectY
        and y <= rectY + height
end

-- 检测点全局点是否在视图内
-- 判断鼠标是否在视图内使用此函数
--需要额外判断选项的位置
function select_menu:containsPoint(x, y)
    -- local absX, absY = self:get_world_Position(0, 0, self)
    local x1, y1 = self:get_local_Position(x, y, self)
    --print(x, y, x1, y1)
    --父视图可以回传空参数 拦截点击事件
    if x1 and y1 then
        --print(absX)
        if x1 >= 0 and x1 <= self.width and
            y1 >= 0 and y1 <= self.height then
            return true
        else
            if self.is_unfold then                                                                                                  --展开状态
                if self.point_in_rect(x1, y1, self.extension.x, self.extension.y, self.extension.width, self.extension.height) then --点是否在矩形内
                    return true
                end
            end
        end
    else
        return false
    end
end

function select_menu:on_hover()
    -- print("获取焦点")
end

function select_menu:off_hover()
    -- print("失去焦点")
    --self.extension = {};
    if love.system.getOS() == "Windows" then --window 独占
        self.is_unfold = false
    end
end

function select_menu:on_click(id, x, y, dx, dy, istouch, pre)
    local x1, y1 = self:get_local_Position(x, y)
    self.is_unfold = not self.is_unfold
    if self.is_unfold then
        --将展开视图置顶
        self:set_hover_view()
        self.extension = self.items
        --self:set_hover_view()
    else
        self.extension = {}
    end
    -- print(13)
    --点击扩展区域
    if not self.point_in_rect(x1, y1, 0, 0, self.width, self.height) then
        for i, item in ipairs(self.items) do
            if type(item) == "table" then
                --print("展开", item.name)
                if self.point_in_rect(x1, y1, item.x, item.y, item.width, item.height) then
                    item.is_presses = true
                    self.text = item.text
                    self:on_select_item(item.text)
                else --其余的重置
                    -- print(item.name)
                    item.is_presses = false
                end
            end
        end
    end
end

--选择的text改变时调用
function select_menu:on_select_item(text) --元素点击事件
    -- body
    --print(count, text)
end

return select_menu;
