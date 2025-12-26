--[[
    上下文菜单组件 (Context Menu)
    右键菜单，支持嵌套子菜单
    作者: 北极企鹅 & AI优化
    时间: 2025
]]

local view = require(lumenGui_path .. ".view.view")

local context_menu = view:new()
context_menu.__index = context_menu

-- 菜单项类
local MenuItem = {}
MenuItem.__index = MenuItem

function MenuItem:new(options)
    local item = {
        label = options.label or "",
        icon = options.icon,
        action = options.action,
        submenu = options.submenu,
        separator = options.separator or false,
        disabled = options.disabled or false,
        height = options.separator and 5 or 28,
        textSize = 14,
        textColor = {0, 0, 0, 1},
        hoverColor = {0.2, 0.5, 0.9, 1},
        disabledColor = {0.6, 0.6, 0.6, 1},
        isHover = false
    }
    setmetatable(item, self)
    return item
end

function MenuItem:draw(x, y, width, font)
    if self.separator then
        -- 绘制分隔线
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.setLineWidth(1)
        love.graphics.line(x + 5, y + 2.5, x + width - 5, y + 2.5)
        return
    end
    
    -- 绘制背景
    if self.isHover and not self.disabled then
        love.graphics.setColor(self.hoverColor)
        love.graphics.rectangle("fill", x, y, width, self.height)
    end
    
    -- 绘制文本
    local textColor = self.disabled and self.disabledColor or self.textColor
    love.graphics.setColor(textColor)
    love.graphics.setFont(font)
    love.graphics.print(self.label, x + 10, y + (self.height - font:getHeight()) / 2)
    
    -- 绘制子菜单箭头
    if self.submenu then
        love.graphics.print(">", x + width - 20, y + (self.height - font:getHeight()) / 2)
    end
end

function MenuItem:isPointInside(px, py, x, y, width)
    return px >= x and px <= x + width and
           py >= y and py <= y + self.height
end

-- 上下文菜单构造函数
function context_menu:new(tab)
    local new_obj = view.new(self, tab)
    new_obj.type = "context_menu"
    
    -- 菜单特有属性
    new_obj.items = {}                      -- 菜单项列表
    new_obj.width = tab.width or 200        -- 菜单宽度
    new_obj.minWidth = tab.minWidth or 150  -- 最小宽度
    new_obj.padding = tab.padding or 5      -- 内边距
    new_obj.shadow = tab.shadow ~= false    -- 是否显示阴影
    new_obj.autoClose = tab.autoClose ~= false  -- 点击后自动关闭
    new_obj.parentMenu = nil                -- 父菜单
    new_obj.activeSubmenu = nil             -- 当前激活的子菜单
    new_obj._layer = 10                     -- 菜单在高层级
    
    -- 默认样式
    if not tab.backgroundColor then
        new_obj.backgroundColor = {0.95, 0.95, 0.95, 1}
    end
    if not tab.borderColor then
        new_obj.borderColor = {0.5, 0.5, 0.5, 1}
    end
    
    -- 默认不可见，需要调用 show() 显示
    new_obj.visible = false
    
    -- 从选项创建菜单项
    if tab.items then
        for _, itemOptions in ipairs(tab.items) do
            new_obj:addItem(itemOptions)
        end
    end
    
    return new_obj
end

-- 添加菜单项
function context_menu:addItem(options)
    if type(options) == "string" then
        options = {label = options}
    end
    
    local item = MenuItem:new(options)
    table.insert(self.items, item)
    
    -- 更新菜单高度
    self:updateSize()
    
    return item
end

-- 添加分隔线
function context_menu:addSeparator()
    return self:addItem({separator = true})
end

-- 更新菜单大小
function context_menu:updateSize()
    local totalHeight = self.padding * 2
    local maxWidth = self.minWidth
    
    -- 获取字体
    local font = self.gui and self.gui.font_manger and 
                 self.gui.font_manger:get_font(self.font, 14) or 
                 love.graphics.getFont()
    
    for _, item in ipairs(self.items) do
        totalHeight = totalHeight + item.height
        
        if not item.separator then
            local textWidth = font:getWidth(item.label) + 30
            if item.submenu then
                textWidth = textWidth + 20
            end
            maxWidth = math.max(maxWidth, textWidth)
        end
    end
    
    self.width = math.max(maxWidth, self.width)
    self.height = totalHeight
end

-- 显示菜单
function context_menu:show(x, y)
    self.x = x
    self.y = y
    self.visible = true
    
    -- 确保菜单在屏幕内
    if self.gui then
        local screenW, screenH = self.gui:get_window_wh()
        
        if self.x + self.width > screenW then
            self.x = screenW - self.width - 10
        end
        
        if self.y + self.height > screenH then
            self.y = screenH - self.height - 10
        end
    end
    
    -- 触发显示回调
    if self.on_show then
        self:on_show()
    end
end

-- 隐藏菜单
function context_menu:hide()
    self.visible = false
    
    -- 隐藏所有子菜单
    if self.activeSubmenu then
        self.activeSubmenu:hide()
        self.activeSubmenu = nil
    end
    
    -- 触发隐藏回调
    if self.on_hide then
        self:on_hide()
    end
end

-- 切换显示状态
function context_menu:toggle(x, y)
    if self.visible then
        self:hide()
    else
        self:show(x, y)
    end
end

-- 点击事件
function context_menu:on_click(id, x, y, dx, dy, istouch, pre)
    local gx, gy = self:get_global_position()
    local currentY = gy + self.padding
    
    -- 检查点击了哪个菜单项
    for i, item in ipairs(self.items) do
        if not item.separator and not item.disabled then
            if item:isPointInside(x, y, gx, currentY, self.width) then
                if item.submenu then
                    -- 显示子菜单
                    self:showSubmenu(item, gx + self.width, currentY)
                elseif item.action then
                    -- 执行操作
                    item.action(item)
                    
                    -- 自动关闭
                    if self.autoClose then
                        self:closeAll()
                    end
                end
                
                return
            end
        end
        
        currentY = currentY + item.height
    end
end

-- 显示子菜单
function context_menu:showSubmenu(item, x, y)
    -- 隐藏当前激活的子菜单
    if self.activeSubmenu then
        self.activeSubmenu:hide()
    end
    
    -- 创建子菜单（如果不存在）
    if not item.submenuInstance then
        item.submenuInstance = context_menu:new({
            items = item.submenu,
            gui = self.gui
        })
        item.submenuInstance.parentMenu = self
        if self.gui then
            self.gui:add_view(item.submenuInstance)
        end
    end
    
    -- 显示子菜单
    item.submenuInstance:show(x, y)
    self.activeSubmenu = item.submenuInstance
end

-- 关闭所有菜单
function context_menu:closeAll()
    local root = self
    while root.parentMenu do
        root = root.parentMenu
    end
    root:hide()
end

-- 鼠标移动事件
function context_menu:on_hover(x, y)
    local gx, gy = self:get_global_position()
    local currentY = gy + self.padding
    
    -- 更新悬停状态
    for _, item in ipairs(self.items) do
        if not item.separator then
            item.isHover = item:isPointInside(x, y, gx, currentY, self.width)
        end
        currentY = currentY + item.height
    end
end

-- 绘制
function context_menu:draw()
    if not self.visible then return end
    
    local gx, gy = self:get_global_position()
    
    -- 绘制阴影
    if self.shadow then
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", gx + 3, gy + 3, self.width, self.height)
    end
    
    -- 绘制背景
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", gx, gy, self.width, self.height)
    
    -- 绘制边框
    love.graphics.setColor(self.borderColor)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", gx, gy, self.width, self.height)
    
    -- 获取字体
    local font = self.gui and self.gui.font_manger and 
                 self.gui.font_manger:get_font(self.font, 14) or 
                 love.graphics.getFont()
    
    -- 绘制菜单项
    local currentY = gy + self.padding
    for _, item in ipairs(self.items) do
        item:draw(gx, currentY, self.width, font)
        currentY = currentY + item.height
    end
    
    -- 绘制子视图
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

-- 更新
function context_menu:update(dt)
    view.update(self, dt)
    
    -- 检测外部点击以关闭菜单
    if self.visible and self.autoClose then
        -- 这个逻辑需要在 GUI 层面实现
    end
end

return context_menu
