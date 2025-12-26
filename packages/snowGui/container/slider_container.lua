local view = require(lumenGui_path .. ".view.view")
local slider_container = view:new()
slider_container.__index = slider_container
function slider_container:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type               = "slider_container", --类型
        text               = "slider_container",
        textColor          = { 0, 0, 0, 1 },
        hoverColor         = { 0.8, 0.8, 1, 1 },
        pressedColor       = { 0.6, 1, 1, 1 },
        backgroundColor    = { 0.6, 0.6, 1, 1 },
        borderColor        = { 0, 0, 0, 1 },
        --
        contentHeight      = 0,  -- 内容总高度（大于容器高度）
        offsetY            = 0,  -- 当前滚动偏移量
        contentWidth       = 0,  -- 内容总宽度（大于容器高度）
        offsetX            = 0,  -- 当前滚动偏移量
        scrollSpeed        = 20, -- 滚轮滑动速度
        v_slider           = {
            x      = 0,
            y      = 0,
            width  = 50,
            height = 50,
        }, --竖向的滑块
        h_slider           = {
            x      = 0,
            y      = 0,
            width  = 50,
            height = 50,
        },                          --横向的滑块
        slider_orientation = "v",   --滚动方向 v纵向 h横向
        bar_wh             = 15,    --滑块宽高
        --
        isDragging         = false, -- 拖动状态标记
        isPressed          = false, --点击标志
        bar_visible        = true,  --滑块是否显示
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
function slider_container:init()

end

function slider_container:on_create(...)
    --self:slider_init() --初始化滑块
end

--重写
--如果返回值为true 则通知父视图与子视图
--默认不通知 只有需要响应手动通知
function slider_container:change_from_self(child_view)
    --
    --更新滑块
    -- print(123)
    self:slider_init() --初始化滑块
    --返回两个参数 true通知父布局更新 true通知自视图更新
    return false, false;
end

--初始化滑块
function slider_container:slider_init()
    local mw, mh = 0, 0
    for _, child in ipairs(self.children) do
        if mw < child.width then
            mw = child.width
        end
        if mh < child.height then
            mh = child.height
        end
    end
    -- print(mh, self.height)
    if mh > self.height then
        self.contentHeight = mh
    end
    if mw > self.width then
        self.contentWidth = mw
    end
    -- body
    local bar_wh = self.bar_wh
    local v_slider = self.v_slider
    local h_slider = self.h_slider
    --竖向滑块
    if self.height < self.contentHeight then
        v_slider.x = self.width - bar_wh
        v_slider.y = 0
        v_slider.width = bar_wh
        v_slider.height = self.height * (self.height / self.contentHeight) --按视图比例
    else
        v_slider.x = self.width - bar_wh
        v_slider.y = 0
        v_slider.width = bar_wh
        v_slider.height = self.height
    end
    --横向滑块
    if self.width < self.contentWidth then
        h_slider.x = 0
        h_slider.y = self.height - bar_wh
        h_slider.width = self.width * (self.width / self.contentWidth)
        h_slider.height = bar_wh --按视图比例
    else
        h_slider.x = 0
        h_slider.y = self.height - bar_wh
        h_slider.width = self.width
        h_slider.height = bar_wh --按视图比例
    end
    -- print(dump(self.v_slider))
end

--如果内容高度改变 改变滑块参数
function slider_container:update_slider()

end

--改变子视图数量后的回调 适用需要对子视图数量更新做出反应的视图
--新增视图后 改变滑动画布大小
function slider_container:change_from_children(child_view)
    self:slider_init() --初始化滑块
end

--迭代子类函数 非专业勿动
--因为是容器 偏移量迭代给子视提
function slider_container:_draw()
    if self.visible then
        local font = self:get_font(self.font, self.textSize)
        love.graphics.setFont(font)
        self:draw()
        -- 绘制子视图
        --绘图偏移
        love.graphics.push()
        love.graphics.translate(self.x - self.offsetX, self.y - self.offsetY)
        -- love.graphics.setScissor(self.x, self.y, self.width, self.height)
        for i, child in pairs(self.children) do
            --print(i)
            child:_draw()
        end
        --  love.graphics.setScissor()
        love.graphics.pop()
    else
    end
end

--绘图
function slider_container:draw()
    -- === 1. 绘制容器背景 ===
    love.graphics.setColor(self.backgroundColor)
    --love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(self.borderColor)

    -- === 2. 启用剪裁区域（仅容器内可见） ===
    love.graphics.setScissor(self.x, self.y, self.width, self.height)





    -- === 4. 禁用剪裁区域 ===
    love.graphics.setScissor()
    -- === 5. 绘制UI辅助信息 ===
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line",
        self.x, self.y,
        self.width, self.height
    )
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    -- 在draw函数中添加：--绘制滚动条
    if self.bar_visible then
        --竖向滚动条
        local v_slider = self.v_slider
        love.graphics.rectangle("line", v_slider.x, v_slider.y, v_slider.width, v_slider.height)
        local h_slider = self.h_slider
        love.graphics.rectangle("line", h_slider.x, h_slider.y, h_slider.width, h_slider.height)
    end
    love.graphics.pop()
    --绘制信息
    love.graphics.print(self.text, self.x, self.y)
end

--全局点转换相对点 视图判断时会调用 加上偏移量
--受滑动影响 传递给子视图
function slider_container:get_local_Position(x, y, child)
    local parent = self.parent
    if child then
        x1 = x - self.x + self.offsetX
        y1 = y - self.y + self.offsetY
    else
        x1 = x - self.x
        y1 = y - self.y
    end
    if parent then
        return parent:get_local_Position(x1, y1, self)
    else
        return x1, y1;
    end
end

--相对点转换全局点 受滑动影响  传递给子视图
function slider_container:get_world_Position(x, y, child)
    local parent = self.parent
    local x1 = x + self.x - self.offsetX
    local y1 = y + self.y - self.offsetY
    if parent then
        return parent:get_world_Position(x1, y1, self)
    else
        return x1, y1;
    end
end

--因为改了数据点转换 所以改鼠标在视图内的判断逻辑
function slider_container:containsPoint(x, y)
    --local absX, absY = self:get_world_Position(0, 0, self)
    local x1, y1 = self:get_local_Position(x, y, self)
    --父视图可以回传空参数 拦截点击事件
    if x1 and y1 then
        return x1 >= self.offsetX and x1 <= self.width + self.offsetX and
            y1 >= self.offsetY and y1 <= self.height + self.offsetY
    else
        return false
    end
end

--事件拦截机制 如果此函数返回false 则输入事件不会传递给子视图
--通常用于 父视图区域外不会触发子视图情况
--父视图拦截视图 返回true则不拦截
--拦截视图外的事件 拦截滑块下的事件
function slider_container:_event_intercept(x, y, child)
    --如果在视图内
    --转换局部坐标
    local x1, y1 = self:get_local_Position(x, y, self)
    --点击在视图内
    if x1 >= 0 and x1 <= self.width - self.bar_wh and
        y1 >= 0 and y1 <= self.height - self.bar_wh then
        --print("slider_container" .. "123")
        return true
    else
        return false
    end



    return true
end

--------------------------------------------------------------
--输入回调 在获取[焦点][输入权限][锁定点击]
function slider_container:mousemoved(id, x, y, dx, dy, istouch, pre) --滑动回调
    local x1, y1 = self:get_local_Position(x, y)

    local bar_wh = self.bar_wh
    print(self.height - y1, bar_wh)
    if self.height - y1 < bar_wh then
        print("横向滚动")
        self.slider_orientation = 'h'
    else
        --print("纵向 中间滚动")
        self.slider_orientation = 'v'
    end
    --print(x, y, self.offsetY)
end

--按下
function slider_container:mousepressed(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击

end

--抬起
function slider_container:mousereleased(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击

end

--滚轮滚动
function slider_container:wheelmoved(id, x, y) --滚轮滑动
    -- print(self.contentHeight > self.height)
    if self.slider_orientation == 'v' then
        if self.contentHeight > self.height then
            --竖向
            self.offsetY = math.min(self.contentHeight, math.max(0, self.offsetY - y * self.scrollSpeed))
            local v_slider = self.v_slider
            local sh = self.y + self.height - v_slider.height
            --v_slider.y = math.min(sh, math.max(0, v_slider.y - y))
            v_slider.y = self.offsetY * ((self.height - v_slider.height) / (self.contentHeight))
        end
    elseif self.slider_orientation == 'h' then
        if self.contentWidth > self.width then
            --横向
            self.offsetX = math.min(self.contentWidth, math.max(0, self.offsetX - y * self.scrollSpeed))
            local h_slider = self.h_slider
            local sw = self.x + self.width - h_slider.height
            --v_slider.y = math.min(sh, math.max(0, v_slider.y - y))
            h_slider.x = self.offsetX * ((self.width - h_slider.width) / (self.contentWidth))
        end
    end

    -- print(self.slider_orientation, self.offsetX)
end

function slider_container:on_click(id, x, y, dx, dy, istouch, pre)
    -- body
    --self:destroy()
    print(self.type, self:get_local_Position(x, y))
end

return slider_container;
