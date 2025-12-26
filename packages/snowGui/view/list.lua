local view = require(lumenGui_path .. ".view.view")
local list = view:new()
list.__index = list
function list:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type            = "list", --类型
        items           = {
            -- { text = "", onClick = function(self,count,view) end }
        }, --首次初始化 tab转化items
        contentItems    = {

        },                                    --子项
        contentHeight   = 0,                  -- 内容总高度（大于容器高度）
        offsetY         = 0,                  -- 当前滚动偏移量
        dragStartY      = 0,                  -- 拖动起始位置
        scrollSpeed     = 10,                 -- 滚轮滑动速度
        isDragging      = false,              -- 拖动状态标记
        isPressed       = false,              --点击标志
        gap             = 0,                  --元素间隔
        itemHeight      = 80,                 --元素宽高
        hover_ele       = nil,                --焦点元素
        pressed_ele     = nil,                --点击元素
        text_size       = 15,                 --文字大小
        bar_max_time    = 300,                --滚动条自动隐藏延时
        bar_on_time     = 0,                  --滚动条时间标识
        bar_visible     = false,              --滚动条显示标识
        hoverColor      = { 0.8, 0.8, 1, 1 }, --获取焦点颜色
        pressedColor    = { 0.6, 1, 1, 0.8 }, --点击时颜色
        backgroundColor = { 0.6, 0.6, 1, 1 }, --背景颜色
        borderColor     = { 0, 0, 0, 1 },     --边框颜色
        --
        x               = 0,
        y               = 0,
        width           = 100,
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

function list:init()

end

--可以访问外部对象
function list:on_create()
    local gap = self.gap --元素间隙
    local font = self:get_font(self.font, self.textSize)
    local textHeight = font:getHeight()
    self.itemHeight = textHeight * 2
    --
    local itemHeight = self.itemHeight --元素高度

    --首次初始化 tab转化实体对象
    if self.items then
        for i, item in ipairs(self.items) do
            local y = (i - 1) * itemHeight + (i * gap) -- 垂直位置
            local height = itemHeight                  -- 方块高度
            --print(y)
            table.insert(self.contentItems, {
                x = 0,
                width = self.width,
                y = y,
                height = height,
                color = self.backgroundColor,
                text = item.text,
                onClick = item.onClick
            })
        end
    end
    --设置元素总高
    local i = #self.contentItems
    self.contentHeight = gap + ((i - 1) * gap) + i * itemHeight --设置内容高度

    -- print(#self.contentItems)
end

--重写自定义输出函数
function list:self_to_table(key, value, out_table)
    -- print(key)
    if key == "items" then
        out_table.items = value
        -- print(out_table.items)
    end
end

--多平台适配加载 迭代函数
if love.system.getOS() == "Windows" then --鼠标焦点支持
    function list:update(dt)
        --print(123)
        self.offsetY = math.max(0, math.min(
            self.offsetY,
            self.contentHeight - self.height
        ))
        if self.hover then --有焦点开始自动更新焦点item
            local x, y = love.mouse.getPosition()
            local x1, y1 = self:get_local_Position(x, y)
            if self.hover_ele then                                         --存在焦点元素
                local items = self.contentItems                            --元素总表
                local count = self:get_count(x1, y1)                       --获取焦点元素
                if self.hover_ele == count then                            --还是此元素
                else                                                       --不是此元素
                    if items[self.hover_ele] and items[count] then         --焦点元素存在
                        items[self.hover_ele].color = self.backgroundColor --取消焦点颜色
                        items[count].color = self.hoverColor               --设置焦点颜色
                        self.hover_ele = count;                            --设置焦点元素
                        return self:change_hover(count, items[count].text) --调用回调
                    end
                end
            else                                         --不存在焦点元素
                local items = self.contentItems          --元素总表
                local count = self:get_count(x1, y1)     --获取焦点元素
                -- print(count, x1, y1)
                if items[count] then                     --元素存在
                    self.hover_ele = count
                    items[count].color = self.hoverColor --设置颜色
                end
            end
        end
        --自动滚动条更新时间
        if self.bar_visible then
            if self.bar_on_time >= 0 then
                self.bar_on_time = self.bar_on_time - (dt * 1000); --时间迭代
            else
                self.bar_visible = false;                          --隐藏滚动条
            end
        end
    end
elseif love.system.getOS() == "Android" then --多点触控支持
    function list:update(dt)
        --print(123)
        self.offsetY = math.max(0, math.min(
            self.offsetY,
            self.contentHeight - self.height
        ))

        --自动滚动条更新时间
        if self.bar_visible then
            if self.bar_on_time >= 0 then
                self.bar_on_time = self.bar_on_time - (dt * 1000); --时间迭代
            else
                self.bar_visible = false;                          --隐藏滚动条
            end
        end
    end
end

--绘图
function list:draw()
    local gui = self.gui
    -- === 1. 绘制容器背景 ===
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(0, 0, 0)
    --love.graphics.circle("fill", love.mouse.getX(), love.mouse.getY(), 50)
    -- 启用模板测试
    -- local x, y = self:get_world_Position(self.x, self.y)
    -- print(self.x, self.y)
    -- gui:push_scissor(self.x, self.y, self.width, self.height)


    --  love.graphics.setStencilTest("greater", 1)

    -- === 3. 绘制内容（应用滑动偏移） ===
    for i, item in ipairs(self.contentItems) do
        -- 计算世界坐标（应用滚动偏移）
        local itemY = self.y + item.y - self.offsetY - self.gap / 2

        -- 仅绘制可见元素（性能优化）
        if itemY < self.y + self.height and
            itemY + item.height > self.y then
            love.graphics.setColor(item.color)
            love.graphics.rectangle("fill",
                self.x,
                itemY,
                item.width,
                item.height
            )
            --绘制分割线
            love.graphics.setColor(0, 0, 0)
            love.graphics.line(self.x, itemY - self.gap / 2, self.x + item.width, itemY - self.gap / 2)
            local font = self:get_font(self.font, self.textSize)
            local text_width = tonumber(font:getWidth(item.text))
            local text_height = tonumber(font:getHeight()) -- 获取字体行高（单行高度）
            local text_x = (self.x + (item.width / 2)) - (text_width / 2)
            local text_y = (itemY + (item.height / 2)) - (text_height / 2)
            -- 显示text 居中显示
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(item.text, text_x, text_y)
        end
    end


    -- === 5. 绘制UI辅助信息 ===
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line",
        self.x, self.y,
        self.width, self.height
    )
    love.graphics.setColor(1, 1, 1, 0.5)
    -- 在draw函数中添加：--绘制滚动条
    if self.bar_visible then
        if self.height < self.contentHeight then
            local barHeight = self.height * (self.height / self.contentHeight)
            local barY = self.y + (self.offsetY / self.contentHeight) * self.height
            love.graphics.rectangle("fill", self.x + self.width - 10, barY, 8, barHeight, 2)
        end
    end
    --关闭模板测试
    --love.graphics.setStencilTest()
    --gui:pop_scissor()
    -- 显示滚动提示
    --[[
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Scroll  Offset: " .. math.floor(self.offsetY), self.x, self.y + self.height + 10)
    love.graphics.print("Drag  or use Mouse Wheel", self.x, self.y + self.height + 20)
]]
end

--显示滚动条
function list:display_bar()
    self.bar_visible = true               --显示滚动条
    self.bar_on_time = self.bar_max_time; --赋值延时时间
end

--根据点击获取点击元素
function list:get_count(x1, y1)               --获取鼠标焦点元素
    local fact_y = y1 + self.offsetY
    local height = self.itemHeight + self.gap --元素真实高度

    return (fact_y - (fact_y % height)) / height + 1
end

--点击
function list:mousepressed(id, x, y, dx, dy, istouch, pre)
    -- 获取相对点击位置
    local x1, y1 = self:get_local_Position(x, y)
    --赋予元素点击颜色
    if self.hover_ele then                                  --存在焦点元素
        local items = self.contentItems                     --元素总表
        if items[self.hover_ele] then                       --焦点元素存在
            items[self.hover_ele].color = self.pressedColor --点击颜色
        end
    else                                                    --无焦点元素 点击判断                                                    --判断点击元素
        local items = self.contentItems                     --元素总表
        local count = self:get_count(x1, y1)                --获取焦点元素
        if items[count] then                                --元素存在
            --print(items[count])
            self.pressed_ele = count                        --点击元素赋值
            items[count].color = self.pressedColor          --点击颜色
            --print(dump(self.pressedColor))
        end
        --print(dump(items[count].color))
        --print(count)
    end

    self.dragStartY = y             --储存开始拖动位置
    self.startOffset = self.offsetY --点击位置储存
end

--滑动
function list:mousemoved(id, x, y, dx, dy, istouch, pre)
    local x1, y1 = self:get_local_Position(x, y)
    if self.isPressed then --点击
        -- 根据鼠标移动距离更新滚动位置
        self.offsetY = self.startOffset + (self.dragStartY - y)
        self:display_bar() --显示滚动条
    else                   --鼠标移动 不做响应式 做即时 逻辑移至update
    end
end

--失去焦点
function list:off_hover(...)                                   --失去焦点
    if self.hover_ele then                                     --存在焦点元素
        local items = self.contentItems                        --元素总表
        if items[self.hover_ele] then                          --焦点元素存在
            items[self.hover_ele].color = self.backgroundColor --取消焦点颜色
            self.hover_ele = nil                               --焦点赋值为空
        end
    end
end

--抬起
function list:mousereleased(id, x, y, dx, dy, istouch, pre)
    local x1, y1 = self:get_local_Position(x, y)
    local count = self:get_count(x1, y1)                                           --获取焦点元素
    --抬起颜色赋值
    if self.hover_ele then                                                         --存在焦点元素
        local items = self.contentItems                                            --元素总表
        local count = self:get_count(x1, y1)                                       --获取焦点元素
        if self.hover_ele == count then                                            --还是此元素
            items[self.hover_ele].color = self.backgroundColor                     --抬起颜色赋值
        end
    elseif self.pressed_ele then                                                   --存在点击元素
        local items = self.contentItems                                            --元素总表
        if items[self.pressed_ele] then                                            --点击元素存在
            if not self.isDragging then                                            --没拖动执行点击回调
                self:item_on_click(self.pressed_ele, items[self.pressed_ele].text) --执行元素点击回调
            end
            items[self.pressed_ele].color = self.backgroundColor                   --取消点击颜色
            self.pressed_ele = nil                                                 --点击元素赋值为空
        end
        --print(1)
    end
    self.isDragging = false --拖动变量清空
end

--滚轮滚动
function list:wheelmoved(id, x, y) --滚轮滑动
    self.offsetY = self.offsetY - y * self.scrollSpeed
    self:display_bar()             --显示滚动条
end

--拦截点击事件
function list:_on_click(id, x, y, dx, dy, istouch, pre)
    -- body
    local items = self.contentItems  --元素总表
    local hover_ele = self.hover_ele --元素排序
    if items[hover_ele] then         --元素存在执行回调
        --执行点击回调
        if items[hover_ele].onClick then
            return items[hover_ele]:onClick(hover_ele, self)
        end
        return self:item_on_click(hover_ele, items[hover_ele].text)
    end
end

--重写回调
-----------------------------------------------
--鼠标滑动悬停的子元素改变时调用
function list:change_hover(count, text) --鼠标滑动list时item获取焦点时的回调
    --print(count, text)
end

--子元素被点击时调用
function list:item_on_click(count, text) --元素点击事件
    -- body
    --print(count, text)
end

return list;
