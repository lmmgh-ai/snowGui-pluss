local dialog = require(lumenGui_path .. ".container.dialog")
local File = require (lumenGui_path .. ".libs.nativefs")
--
local file_select_dialog = dialog:new()
--并非继承view而是继承window
file_select_dialog.__index = file_select_dialog
function file_select_dialog:new(tab)
    local new_obj = {
        type              = "file_select_dialog",
        text              = "",
        x                 = 100,
        y                 = 100,
        width             = 300,
        height            = 180,
        title             = "提示", --头部标记
        title_height      = 30, --头部高度
        bottom_bar_height = 50, --底栏高度
        modal             = false, -- 是否模态遮罩 遮蔽后弹窗占领屏幕
        buttons           = {}, --按钮合集
        button_width      = 30,
        button_height     = 20,
        button_gap        = 10,
        --
        browsing_path     = "",  --当前浏览的路径
        select_file       = nil, --选中的文件or文件夹
        file_list         = {},  -- 当前的文件列表
        scrollOffset      = 0,
        maxVisibleItems   = 5,   --最多显示几项
        itemHeight        = 20,
        --列表大小
        list_x            = 0,
        list_y            = 0,
        list_width        = 50,
        list_height       = 50,
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

function file_select_dialog:init()
    self:init_buttons()
    self:set_path("./")
end

function file_select_dialog:on_create()
    --将对话框居中
    local ww, wh = self:get_window_wh()
    self.x = (ww - self.width) / 2
    self.y = (wh - self.height) / 2
    --print(self.x)
end

--获取选择路径
function file_select_dialog:get_select_path(...)
    -- body
    return self.select_file.path
end

--设置路径
function file_select_dialog:set_path(path)
    --获取路径列表
    local items, path = self:get_directory_list(path)
    --清空当前文件列表
    self.file_list = {}
    --print(path)
    -- 添加"返回上级目录"选项（如果不是根目录）
    if path ~= "/" and path ~= "" then
        --获取当前浏览文件夹父路径
        local parent_path = self:get_parent_directory(path)
        table.insert(self.file_list, {
            name = "..",
            path = self:get_parent_directory(path),
            type = "directory",
            displayText = "[../]"
        })
    end

    -- 添加其他项

    for _, item in ipairs(items) do
        --print(item.name)
        local item1 = {
            name = item.name,
            path = item.path,
            type = item.type,
        }
        if item.type == "file" then
            item1.displayText = item.name
        elseif item.type == "directory" then
            item1.displayText = "[" .. item.name .. "]"
        else
            item1.displayText = item.name
        end
        --print(self.file_list, dump(item1))
        table.insert(self.file_list, item1)
    end
end

--[[
列出指定目录的内容
@param path: 要列出的目录路径
@return 包含文件信息的表
--]]
function file_select_dialog:get_directory_list(path)
    local items = {}
    if path:find("./") then
        --路径分割符转义
        path = string.gsub(path, "%./", File.getWorkingDirectory())
        --print(path)
    elseif path == "/" then
        -- 使用love.filesystem 枚举目录（仅限游戏目录内）
        -- 注意：Love2D的安全限制，只能访问游戏相关目录
        --local files = love.filesystem.getDirectoryItems(path)
    end
    --转义分隔符
    path = string.gsub(path, '\\', '/')
    --print(path)
    -- path = path or File.getDriveList()[3]
    --获取文件列表
    local files = File.getDirectoryItemsInfo(path)
    for _, file in ipairs(files) do
        file.path = path .. "/" .. file.name
        table.insert(items, file)
    end
    --简单排序
    --item格式
    --[[{
                ["size"] = 15354,
                ["modtime"] = 1718292033,
                ["type"] = "file",directory
                ["name"] = "nativefs.lua",
        }]]
    return items, path
end

--[[
获取父级目录路径
@param path: 当前路径
@return 父级目录路径
--]]
function file_select_dialog:get_parent_directory(path)
    local parts = {}
    for part in string.gmatch(path, "[^/]+") do
        table.insert(parts, part)
    end

    if #parts <= 1 then
        return "/"
    else
        table.remove(parts)
        return table.concat(parts, "/")
    end
end

function file_select_dialog:content_draw()
    if not self.visible then
        return
    end
    local font = self:get_font(self.font, self.textSize)
    local textHeight = font:getHeight()
    -- 绘制背景
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    -- 绘制边框
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    -- 绘制标题
    love.graphics.setColor(self.textColor)
    love.graphics.print(" 文件选择器", self.x + 10, self.y + 10)

    -- 绘制文件列表背景
    local listY = self.y + self.title_height
    local listHeight = self.height - 80
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x + 5, listY, self.width - 10, listHeight)

    -- 绘制文件列表
    local startIndex = self.scrollOffset + 1
    local endIndex = math.min(startIndex + self.maxVisibleItems - 1, #self.file_list)

    for i = startIndex, endIndex do
        local item = self.file_list[i]
        local itemY = listY + (i - startIndex) * self.itemHeight

        -- 绘制选中或悬停效果
        if i == self.hoveredIndex then
            love.graphics.setColor(self.hoverColor)
            love.graphics.rectangle("fill", self.x + 5, itemY, self.width - 10, self.itemHeight)
        elseif self.select_file and item.path == self.select_file.path then
            love.graphics.setColor(self.hoverColor)
            love.graphics.rectangle("fill", self.x + 5, itemY, self.width - 10, self.itemHeight)
        end

        -- 绘制文本
        love.graphics.setColor(self.textColor)
        love.graphics.print(item.displayText, self.x + 10, itemY + 5)
    end

    -- 绘制滚动条（如果需要）
    if #self.file_list > self.maxVisibleItems then
        local scrollbarHeight = (self.maxVisibleItems / #self.file_list) * listHeight
        local scrollbarY = listY + (self.scrollOffset / #self.file_list) * listHeight

        love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
        love.graphics.rectangle("fill", self.x + self.width - 15, scrollbarY, 10, scrollbarHeight)
    end


    -- 显示选中文件信息
    if self.select_file then
        love.graphics.setColor(self.textColor)
        -- 绘制当前路径
        -- love.graphics.printf(self.browsing_path, self.x + 10, self.y + self.height - textHeight * 2, self.width - 20,"left")
        love.graphics.print(" 已选择: " .. self.select_file.name, self.x + 10, self.y + self.height - textHeight)
    end
end

function file_select_dialog:mousepressed(id, x, y, dx, dy, istouch, pre)
    local x1, y1 = self:get_local_Position(x, y)
    --按钮确认
    for _, btn in ipairs(self.buttons) do
        if self.point_in_rect(x1, y1, btn.x, btn.y, btn.width, btn.height) then
            btn.pressed = true
            if not btn:on_click(btn, self, self.gui) then
                self:on_click_button(button)
            end
        end
    end
    -- 处理列表点击事件
    local listY = self.y + self.title_height
    local listHeight = self.height
    if x >= self.x and x <= self.x + self.width and
        y >= listY and y <= listY + listHeight then
        local relativeY = y - listY
        local index = math.floor(relativeY / self.itemHeight) + 1 + self.scrollOffset

        if index > 0 and index <= #self.file_list then
            local item = self.file_list[index]
            --print(1, item)
            if id == 1 then -- 左键点击
                print(item.path, dump(item))
                --如果是文件夹
                if item.type == "directory" then
                    -- 进入目录

                    self.browsing_path = item.path
                    self:set_path(item.path)
                    self.scrollOffset = 0
                    self.select_file = item
                    --如果是文件
                elseif item.type == "file" then
                    -- 选择文件
                    self.select_file = item
                else
                    -- 选择文件
                    self.select_file = item
                end
            elseif id == 2 then -- 右键点击
                if not item.type then
                    self.select_file = item
                end
            end
        end
    end
end

function file_select_dialog:mousereleased(id, x, y, dx, dy, istouch, pre)
    if not self.visible then return end
    --处理按钮
    for _, btn in ipairs(self.buttons) do
        if btn.pressed and self.point_in_rect(x, y, btn.x, btn.y, btn.width, btn.height) then
            btn.pressed = false
            if btn.on_click then btn.on_click(self) end
            self:close()
        else
            btn.pressed = false
        end
    end
end

function file_select_dialog:mousemoved(id, x, y, dx, dy, istouch, pre)
    local x1, y1 = self:get_local_Position(x, y)
    for _, btn in ipairs(self.buttons) do
        btn.hovered = self.point_in_rect(x1, y1, btn.x, btn.y, btn.width, btn.height)
    end

    -- 更新列表悬停状态
    local listY = self.y + self.title_height
    local listHeight = self.height
    --
    if x >= self.x and x <= self.x + self.width and
        y >= listY and y <= listY + listHeight then
        local relativeY = y - listY
        local index = math.floor(relativeY / self.itemHeight) + 1 + self.scrollOffset
        if index > 0 and index <= #self.file_list then
            self.hoveredIndex = index
        else
            self.hoveredIndex = nil
        end
    else
        self.hoveredIndex = nil
    end
end

function file_select_dialog:wheelmoved(id, x, y)
    -- 滚动文件列表
    self.scrollOffset = self.scrollOffset - y
    -- 限制滚动范围
    local maxScroll   = math.max(0, #self.file_list - self.maxVisibleItems)
    self.scrollOffset = math.max(0, math.min(maxScroll, self.scrollOffset))
end

--点击任何一个按钮回调
--如果按钮自定义函数返回true 则不执行此回调
function dialog:on_click_button(button)
    self:destroy()
end

return file_select_dialog
