local view = require(lumenGui_path .. ".view.view")
local title_menu = view:new()
title_menu.__index = title_menu
function title_menu:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type            = "title_menu", --类型
        text            = "title_menu",
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.8, 0.8, 1, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 0.6, 1, 1, 1 },
        borderColor     = { 0, 0, 0, 1 },
        --
        items           = {
            {
                text = "文件2",
                items = {
                    {
                        text = "新建2",
                        items = {
                            { text = "新建3" },
                            { text = "另存3" },
                            { text = "退出3" },
                        }
                    },
                    {
                        text = "另存2",
                        items = {
                            { text = "新建3" },
                            { text = "另存3" },
                            { text = "退出3" },
                        }
                    },
                    { text = "退出2" },
                },
                --[[
                on_click = function(self, gui)
                love.event.quit()
                end
                ]]
            },
            {
                text = "视图1",
                items = {
                    { text = "新建2" },
                    { text = "另存2" },
                    { text = "退出2" },
                }
            },
            { text = "设置1" },
            { text = "编辑1" },
            { text = "关于1" },
        },
        extension       = {},  --扩展点击区域
        item_width      = 100, --扩展选项的宽
        item_height     = 30,  --扩展选项的高
        --
        x               = 0,
        y               = 0,
        width           = 50,
        height          = 50,
        --
        parent          = nil, --父视图
        text            = "",  --以自己内存地址作为唯一标识
        id              = "",  --自定义索引
        children        = {},  -- 子视图列表
        _layer          = 1,   --图层
        _draw_order     = 2,   --默认根据 数值越大在当前图层越在前(目前视图在图层1起作用)
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

function title_menu:init()

end

function title_menu:on_create(...)
    -- body
    --初始解析item
    self:update_items()
end

--当自身尺寸被父视图改变 响应
function title_menu:change_from_parent(parent)
    self:update_items() --更新item位置
end

--将itme列表解析子函数
local function update(f_item, layer, x, y, width, height)
    if f_item then
        local c_h = 0
        for i, item in ipairs(f_item) do
            item.x = x
            item.y = c_h + y
            item.width = width
            item.height = height
            item.is_unfold = false;
            item.serial_number = i; --当前序列号
            item.layer = layer + 1; --当前层级 父层级＋1
            f_item.count = i        --子项总数索引

            c_h = c_h + height
            if item.items then
                update(item.items, item.layer, item.x + width, item.y + item.height / 2, width, height)
            end
        end
        f_item.x = x
        f_item.y = y
        f_item.width = width
        f_item.height = c_h
    end
end

--将itme列表解析
function title_menu:update_items()
    local screenWidth = love.graphics.getWidth()
    self.width = screenWidth
    local font = self:get_font(self.font, self.textSize)
    local textHeight = font:getHeight() + 10
    self.height = textHeight
    local c_w = 0
    --扫描顶栏菜单项并赋予他们位置
    for i, item in ipairs(self.items) do
        local textWidth = font:getWidth(item.text) + 10
        local textHeight = textHeight
        item.x = c_w + self.x
        item.y = self.y
        item.width = textWidth
        item.height = textHeight
        item.is_unfold = false; --是否展开
        item.serial_number = i; --当前序列号
        item.layer = 1;         --当前层级1
        self.items.count = i;   --数量
        --
        c_w = c_w + textWidth
        -- print(item.x, item.y)

        update(item.items, item.layer, item.x, item.y + self.height, self.item_width, self.item_height)

        --print(c_w,textWidth)
    end
end

--绘图
function title_menu:draw()
    if not self.visible then return end


    -- 绘制菜单背景
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)


    -- 绘制菜单项

    local font = self:get_font(self.font, self.textSize)
    for i, item in ipairs(self.items) do
        -- 设置颜色

        --绘制选中背景
        if item.is_unfold then
            love.graphics.setColor(self.hoverColor)
            love.graphics.rectangle("fill", item.x, item.y, item.width, item.height, 5)
        end
        -- 绘制文本
        love.graphics.setColor(self.textColor)
        local textHeight = font:getHeight()
        local textWidth = font:getWidth(item.text)
        -- love.graphics.print(item.text, item.x, item.y)
        love.graphics.print(item.text, item.x + (item.width - textWidth) / 2, item.y + (item.height - textHeight) / 2)
    end
    for i, item1 in ipairs(self.extension) do
        for i, item in ipairs(item1) do
            local tx, ty = item.x, item.y
            love.graphics.setColor(self.backgroundColor)
            love.graphics.rectangle("fill", tx, ty, item.width, item.height, 2)
            love.graphics.setColor(self.borderColor)
            love.graphics.rectangle("line", tx, ty, item.width, item.height, 2)
            --绘制选中背景
            if item.is_unfold then
                love.graphics.setColor(self.hoverColor)
                love.graphics.rectangle("fill", item.x, item.y, item.width, item.height, 5)
            end
            -- 绘制文本
            love.graphics.setColor(self.textColor)
            local textHeight = font:getHeight()
            local textWidth = font:getWidth(item.text)

            love.graphics.print(item.text, item.x + (item.width - textWidth) / 2, item.y + (item.height - textHeight) / 2)
            --绘制菜单展开标识
            if item.items then
                local x = item.x + item.width - 10
                local y = item.y + item.height / 2
                love.graphics.polygon("fill", x - 10, y - textHeight / 4, x - 10,
                    y + textHeight / 4, x,
                    y)
            end
        end
    end
end

function title_menu.point_in_rect(x, y, rectX, rectY, width, height) --点是否在矩形内
    return x >= rectX
        and x <= rectX + width
        and y >= rectY
        and y <= rectY + height
end

-- 检测点全局点是否在视图内
-- 判断鼠标是否在视图内使用此函数
function title_menu:containsPoint(x, y)
    local absX, absY = self:get_world_Position(0, 0)


    if x >= absX and x <= absX + self.width and
        y >= absY and y <= absY + self.height then
        --print(x, y, x1, y1)
        return true
    else
        for i, item in ipairs(self.extension) do
            local x1, y1 = self:get_local_Position(x, y)
            -- print(dump(item))
            if self.point_in_rect(x, y, item.x, item.y, item.width, item.height) then --点是否在矩形内
                return true
            end
        end
    end
    return false
end

function title_menu:on_hover()
    -- print("获取焦点")
end

if love.system.getOS() == "Windows" then
    function title_menu:off_hover()
        -- print("失去焦点")
        --清除所有状态
        self:empty()
    end
end
--清除所有状态
function title_menu:empty()
    --清空所有扩展并将所有扩展点击清零
    for i, item in ipairs(self.items) do
        item.is_unfold = false
    end
    for i, item in ipairs(self.extension) do
        for i, item in ipairs(item) do
            item.is_unfold = false
        end
    end
    self.extension = {}
end

function title_menu:mousepressed(id, x, y, dx, dy, istouch, pre)
    -- print(123)
    local x1, y1 = self:get_local_Position(x, y)
    --local item={}
    --扫描顶栏
    --点击在顶栏内
    -- print(#self.extension)
    --self:set_hover_view()
    if self.point_in_rect(x, y, self.x, self.y, self.width, self.height) then         --点是否在矩形内
        for i, item in ipairs(self.items) do
            if self.point_in_rect(x, y, item.x, item.y, item.width, item.height) then --点是否在矩形内
                if item.items then
                    item.is_unfold = not item.is_unfold
                    --item=item;
                    --项目展开 子项添加到扩展菜单
                    if item.is_unfold then
                        self.extension = {}
                        --1级菜单
                        table.insert(self.extension, 1, item.items)
                        --print(#self.extension)
                        --print(dump(self.extension))
                    else --清空所有扩展并将所有扩展点击清零
                        for i, item in ipairs(self.extension) do
                            for i, item in ipairs(item) do
                                item.is_unfold = false
                            end
                        end
                        self.extension = {}
                    end
                elseif item.on_click then
                    item.on_click(self, self.gui)
                else
                    for i, item in ipairs(self.extension) do
                        for i, item in ipairs(item) do
                            item.is_unfold = false
                        end
                    end
                    self.extension = {}
                    print("未拥有点击事件:" .. item.text)
                end
            else
                item.is_unfold = false --清空顶栏其他焦点
            end
        end
    else
        --扫描 扩展菜单
        --反向扫描
        local extension = self.extension
        for i = #extension, 1, -1 do
            local items = extension[i]
            --确认点击 如果未被点击则消除
            if self.point_in_rect(x, y, items.x, items.y, items.width, items.height) then --扫描扩展菜单
                --扫描被点击的扩展菜单
                for i, item in ipairs(items) do
                    if self.point_in_rect(x, y, item.x, item.y, item.width, item.height) then --点是否在矩形内
                        --有选项的一侧展开 一侧点击事件
                        --print(x, y, item.x, item.y, item.width, item.height)
                        --如果点击右侧区域 并且拥有子菜单项
                        if x > (item.x + item.width) * 0.7 and item.items then
                            -- print("展开菜单")
                            item.is_unfold = true

                            --添加子项到扩展菜单
                            self.extension[item.layer] = item.items
                            --清除其他展开
                            for i, item1 in ipairs(items) do
                                if item ~= item1 then
                                    item1.is_unfold = false
                                end
                            end
                        else --触发点击事件
                            --清除所有状态
                            self:empty()
                            --如果拥有点击事件 则执行
                            if item.on_click then
                                item.on_click(self, self.gui)
                            else
                                print("未拥有点击事件:" .. item.text)
                            end
                        end
                        return
                    end
                end
            else
                --清除父视图展开
                if self.extension[i - 1] then
                    -- self.extension[i - 1][item.serial_number].is_unfold = false
                end
                --删除此项
                table.remove(self.extension, i)
            end
        end
    end

    --print(dump(self.items))

    -- print(x, y)
    -- body
    --self:destroy()
    --print(self:get_local_Position(x, y))
end

return title_menu;
