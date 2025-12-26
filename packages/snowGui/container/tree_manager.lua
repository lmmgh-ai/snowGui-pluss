local view = require (lumenGui_path .. ".view.view")
local tree_manager = view:new()

tree_manager.__index = tree_manager

-- 构造函数 这些属性 可以被继承
function tree_manager:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type               = "tree_manager",
        -- 树配置参数
        indent             = 20, -- 缩进量
        line_height        = 25, -- 行高
        --单行宽度使用视图宽度
        node_icon_size     = 16, -- 节点图标尺寸
        open_icon          = "▲", -- 折叠图标
        close_icon         = "▼", -- 展开图标
        selected_color     = { 0.2, 0.4, 0.8, 1 }, -- 选中颜色

        -- 树数据结构
        root               = { -- 根节点
            id = "root",
            text = "根节点",
            children = {},
            expanded = true,
            node_type = "folder",
            children = nil,                                      --子视图
            depth = nil,                                         --层级
        },
        all_nodes          = setmetatable({}, { __mode = "v" }), -- 所有节点快速索引
        visible_nodes      = setmetatable({}, { __mode = "v" }), -- 可视节点缓存
        selected_node      = nil,                                -- 当前选中节点
        dragging_node      = nil,                                --拖动的节点
        goal_node          = nil,                                --拖动到的节点
        is_dragging_node   = false,                              --是否在拖拽节点
        node_from_alien    = false,                              --拖动节点启用后 确认是否来自外部
        mx                 = 0,                                  --拖动后鼠标位置
        my                 = 0,                                  --拖动后鼠标位置
        --
        contentHeight      = 0,                                  -- 内容总高度（大于容器高度）
        offsetY            = 0,                                  -- 当前滚动偏移量
        contentWidth       = 0,                                  -- 内容总宽度（大于容器高度）
        offsetX            = 0,                                  -- 当前滚动偏移量
        scrollSpeed        = 10,                                 -- 滚轮滑动速度
        v_slider           = {
            x      = 0,
            y      = 0,
            width  = 50,
            height = 50,
        }, --竖向的滑块
        v_slider_visible   = true,
        h_slider           = {
            x      = 0,
            y      = 0,
            width  = 50,
            height = 50,
        },                          --横向的滑块
        h_slider_visible   = true,
        slider_orientation = "v",   --滚动方向 v纵向 h横向
        bar_wh             = 15,    --滑块宽高
        --
        isDragging         = false, -- 拖动状态标记
        isPressed          = false, --点击标志
        --
        x                  = 0,
        y                  = 0,
        width              = 200,
        height             = 400,
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

-- 节点类型定义
tree_manager.node_types = {
    folder = {
        icon = "📁",
        color = { 0.8, 0.8, 0.2, 1 }
    },
    file = {
        icon = "📄",
        color = { 0.7, 0.7, 0.9, 1 }
    },
    custom = {
        icon = "⭐",
        color = { 0.9, 0.6, 0.3, 1 }
    }
}

-- 初始化树管理器
function tree_manager:init()
    self:build_node_index()
    self:calculate_layout()
    self:update_visible_nodes()
    self:slider_init()
end

--初始化滑块
function tree_manager:slider_init()
    -- body
    local bar_wh = self.bar_wh
    local v_slider = self.v_slider
    local h_slider = self.h_slider
    --竖向滑块
    --print(self.height, self.contentHeight)
    if self.height < self.contentHeight then
        v_slider.x = self.x + self.width - bar_wh
        v_slider.y = self.y
        v_slider.width = bar_wh
        v_slider.height = self.height * (self.height / self.contentHeight) --按视图比例
        self.v_slider_visible = true;
    else
        v_slider.x = self.x + self.width - bar_wh
        v_slider.y = self.y
        v_slider.width = bar_wh
        v_slider.height = self.height
        --print(self.height, self.contentHeight)
        self.v_slider_visible = false;
    end
    --横向滑块
    if self.width < self.contentWidth then
        h_slider.x = self.x
        h_slider.y = self.y + self.height - bar_wh
        h_slider.width = self.width * (self.width / self.contentWidth)
        h_slider.height = bar_wh --按视图比例
        self.h_slider_visible = true
    else
        h_slider.x = self.x
        h_slider.y = self.y + self.height - bar_wh
        h_slider.width = self.width
        h_slider.height = bar_wh --按视图比例
        self.h_slider_visible = false
    end
    -- print(dump(self.v_slider))
end

-- 构建节点索引
function tree_manager:build_node_index()
    --重置全体节点索引
    self.all_nodes = {}
    local function traverse(node)
        self.all_nodes[node.id] = node
        if node.children then
            for _, child in ipairs(node.children) do
                traverse(child)
            end
        end
    end
    traverse(self.root)
end

-- 添加新节点
function tree_manager:add_node(parent_id, node_data)
    -- print(self.all_nodes)
    local parent_id = parent_id or "root"
    local parent;
    if type(parent_id) == "string" then
        parent = self.all_nodes[parent_id]
        assert(parent, "Parent node not found")
    end
    --未指定则以自身内存地址为标识
    node_data.id = node_data.id or tostring(node_data) --tostring({}):sub(8) -- 生成唯一ID
    node_data.expanded = node_data.expanded or false

    parent.children = parent.children or {}
    table.insert(parent.children, node_data)
    self.all_nodes[node_data.id] = node_data

    -- 自动展开父节点
    if not parent.expanded then
        parent.expanded = true
    end

    self:calculate_layout()
    self:update_visible_nodes()
    return self.all_nodes[node_data.id]
end

--迁移节点
function tree_manager:move_node(to_node, node_data)
    --print(to_node, node_data)
    local to_node_id = to_node.id
    local node_data_id = node_data.id
    --parent 目标节点
    --node_data 被拖动节点
    local new_parent = to_node --self.all_nodes[parent_id]
    assert(new_parent, "Parent node not found")
    --
    local all_nodes = self.all_nodes
    --节点迭代函数
    local function copy_node(all_nodes, parent, to_node)
        --第一层时创建新节点
        local to_node = to_node or {}
        if parent then
            to_node.text = parent.text or "123"
            to_node.expanded = false
            to_node.node_type = parent.node_type
            --未指定则以自身内存地址为标识
            to_node.id = parent.id or tostring(to_node) --tostring({}):sub(8) -- 生成唯一ID
            to_node.children = setmetatable({}, { __mode = "v" })
            --将之前的覆盖
            assert(all_nodes[parent.id], "节点ID不能为空")
            all_nodes[to_node.id] = to_node
            --print("更新节点", to_node.id, all_nodes[to_node.id])
            --要赋值的节点存在子节点重新赋值
            if parent.children then
                --
                for i, nc in pairs(parent.children) do
                    --table.insert(to_node, node)
                    local node = {}
                    table.insert(to_node.children, node)
                    copy_node(all_nodes, nc, node)
                end
                return to_node
            else
                return to_node
            end
        end
    end

    --删除旧父节点引用
    local old_parent = self:find_parent(node_data_id)
    if old_parent and old_parent.children then
        for i, child in ipairs(old_parent.children) do
            if child.id == node_data_id then
                table.remove(old_parent.children, i)
                break
            end
        end
    end
    --复制全新节点
    local node = copy_node(all_nodes, node_data, {})
    --print(dump(node))
    --添加全新节点添加到全新父节点
    new_parent.children = new_parent.children or {}
    table.insert(new_parent.children, node)
    self.all_nodes[node.id] = node --覆盖id索引
    --更新可视节点
    self:calculate_layout()
    self:update_visible_nodes()
    return node
end

-- 删除节点
function tree_manager:remove_node(node_id)
    local node = self.all_nodes[node_id]
    if not node then return false end

    -- 递归删除子节点
    local function remove_children(n)
        if n.children then
            for _, child in ipairs(n.children) do
                remove_children(child)
                self.all_nodes[child.id] = nil
            end
        end
    end
    remove_children(node)

    -- 从父节点移除
    local parent = self:find_parent(node_id)
    if parent and parent.children then
        for i, child in ipairs(parent.children) do
            if child.id == node_id then
                table.remove(parent.children, i)
                break
            end
        end
    end

    self.all_nodes[node_id] = nil
    if self.selected_node == node_id then
        self.selected_node = nil
    end

    self:calculate_layout()
    self:update_visible_nodes()

    return true
end

-- 展开/折叠所有节点
function tree_manager:set_all_expanded(expanded)
    local function set_expanded(node)
        node.expanded = expanded
        if node.children then
            for _, child in ipairs(node.children) do
                set_expanded(child)
            end
        end
    end

    set_expanded(self.root)
    self:calculate_layout()

    self:update_visible_nodes()
end

-- 查找节点父节点
function tree_manager:find_parent(node_id)
    for _, node in pairs(self.all_nodes) do
        if node.children then
            for _, child in ipairs(node.children) do
                if child.id == node_id then
                    return node
                end
            end
        end
    end
    return nil
end

-- 计算布局
--返回可视区域总高度 总宽度
function tree_manager:calculate_layout()
    local contentHeight = 0
    local contentWidth = 0
    local b_depth = 0      --缓存缩进级别
    local function calculate(node, depth)
        node.depth = depth --层级
        node.y = contentHeight
        contentHeight = contentHeight + self.line_height
        if depth > b_depth then
            b_depth = depth --缩进量
        end
        if node.expanded and node.children then
            for _, child in ipairs(node.children) do
                calculate(child, depth + 1)
            end
        end
    end

    calculate(self.root, 0)
    --print(contentHeight)
    self.contentHeight = contentHeight
    self.contentWidth = b_depth * self.indent + self.width
    self:slider_init()
    return self.contentHeight, self.contentWidth
end

-- 更新可视节点
function tree_manager:update_visible_nodes()
    --重置可视节点表
    self.visible_nodes = {}


    local function traverse(node)
        table.insert(self.visible_nodes, node)

        if node.expanded and node.children then
            for _, child in ipairs(node.children) do
                traverse(child)
            end
        end
    end

    traverse(self.root)
end

-- 获取选中节点
function tree_manager:get_selected_node()
    return self.all_nodes[self.selected_node]
end

-- 导出树结构
function tree_manager:export_structure()
    local function export_node(node)
        local data = {
            id = node.id,
            text = node.text,
            node_type = node.node_type,
            expanded = node.expanded,
            children = {}
        }

        if node.children then
            for _, child in ipairs(node.children) do
                table.insert(data.children, export_node(child))
            end
        end

        return data
    end

    return export_node(self.root)
end

-- 导入树结构
function tree_manager:import_structure(data)
    self.root = data
    self:build_node_index()
    self:calculate_layout()
    self:update_visible_nodes()
end

-- 绘制树
function tree_manager:draw()
    -- 绘制背景
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    love.graphics.push()
    love.graphics.translate(self.x - self.offsetX, self.y - self.offsetY)
    -- 设置裁剪区域
    love.graphics.setScissor(0, 0, self.width, self.height)
    --绘制节点总边框
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", 0, 0, self.contentWidth, self.contentHeight)
    -- 绘制可见节点
    --通过y向偏移计算节点
    --
    local start_idx = math.max(1, math.floor(self.offsetY / self.line_height) + 1)
    local end_idx = math.min(#self.visible_nodes, start_idx + math.ceil(self.height / self.line_height) + 1)

    --绘制节点
    for i = start_idx, end_idx do
        local node = self.visible_nodes[i]
        if node then
            self:draw_node(node, i - 1)
        end
    end

    --如果拖动节点 则绘制节点
    if self.is_dragging_node and self.dragging_node then
        --print(1)
        local y_pos = self.my - self.line_height / 2 - self.offsetY
        local x_pos = self.mx - self.width / 2 - self.offsetX

        --绘制被拖动节点的边框
        love.graphics.setColor(self.borderColor)
        love.graphics.rectangle("line", x_pos, y_pos, self.width, self.line_height)

        --绘制要拖动节点的边框
        local goal_node = self.goal_node
        if goal_node then
            love.graphics.setColor(self.borderColor)
            love.graphics.rectangle("fill", x_pos, goal_node.y, self.width, self.line_height)
        end
    end

    -- 关闭裁剪
    love.graphics.setScissor()
    love.graphics.pop()





    --绘制滚动条
    --竖向滚动条
    if self.v_slider_visible then
        local v_slider = self.v_slider
        love.graphics.rectangle("line", v_slider.x, v_slider.y, v_slider.width, v_slider.height)
    end
    if self.h_slider_visible then
        local h_slider = self.h_slider
        love.graphics.rectangle("line", h_slider.x, h_slider.y, h_slider.width, h_slider.height)
    end
end

-- 绘制单个节点
function tree_manager:draw_node(node, visible_index)
    --print(node, visible_index)
    local y_pos = visible_index * self.line_height -- self.offsetY % self.line_height
    local x_pos = node.depth * self.indent
    --print(y_pos, x_pos)
    local textHeight = font:getHeight()
    --local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    --字体居中坐标
    local c_y_pos = y_pos + (self.line_height - textHeight) / 2
    -- 绘制选中背景
    if self.selected_node == node.id then
        love.graphics.setColor(self.selected_color)
        love.graphics.rectangle("fill", x_pos, y_pos, self.width, self.line_height)
    end
    -- 绘制展开/折叠图标
    if node.children and #node.children > 0 then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(node.expanded and self.close_icon or self.open_icon,
            x_pos, c_y_pos)
    end

    -- 绘制节点图标
    local node_type = self.node_types[node.node_type] or self.node_types.custom
    love.graphics.setColor(node_type.color)
    love.graphics.print(node_type.icon, x_pos + 20, c_y_pos)

    -- 绘制节点文本
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(node.text, x_pos + 40, c_y_pos)
    --绘制边框
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", x_pos, y_pos, self.width, self.line_height)
end

---获取鼠标碰撞节点
function tree_manager:get_node(x, y)
    -- 计算点击的节点索引
    local node_index = math.floor(y / self.line_height) + 1
    local node = self.visible_nodes[node_index]
    return node
end

-- 处理鼠标事件
function tree_manager:mousepressed(id, x, y, dx, dy, istouch, pre)
    --print(node_index)
    --转化局部坐标
    local x1, y1 = self:get_local_Position(x + self.offsetX, y + self.offsetY)
    --获取节点
    local node = self:get_node(x1, y1)
    if node then
        -- 计算点击区域
        local node_x = node.depth * self.indent

        -- 点击展开/折叠图标
        if x1 >= node_x and x1 <= node_x + 20 then
            node.expanded = not node.expanded
            self:calculate_layout()
            self:update_visible_nodes()
            -- 点击节点文本区域
        elseif x1 >= node_x + 20 then
            self.selected_node = node.id
            --赋值拖动节点
            self.is_dragging_node = true
            self.dragging_node = node
        end


        --被拖动的节点折叠
        -- node.expanded = not node.expanded
        --self:calculate_layout()
        --self:update_visible_nodes()
    end
    -- print(self:calculate_layout())
    return false
end

--- 滑动

function tree_manager:mousemoved(id, x, y, dx, dy, istouch, pre) --滑动回调
    local x1, y1 = self:get_local_Position(x, y)
    --计算滑块位置
    local sw = self.x + self.width
    local sh = self.y + self.height
    local bar_wh = self.bar_wh
    if y1 > sh - bar_wh then
        --  print("横向滚动")
        self.slider_orientation = 'h'
    else --全部为竖向滚动
        -- print("中间滚动")
        self.slider_orientation = 'v'
    end
    --pc端
    --锁定鼠标左键拖动
    if self.isDragging and id == 1 then
        if self.selected_node and self.is_dragging_node then
            --赋值拖动节点
            --self.dragging_node = self:get_node(x + self.offsetX, y + self.offsetY)
            if self.dragging_node then
                local node = self:get_node(x + self.offsetX, y + self.offsetY)
                --print(node.text, node.depth)
                self.goal_node = node
            else
                print("节点错误")
            end
        end
        self.mx = x1
        self.my = y1
        -- print("拖动", dx)
    end
    --print(x, y, self.offsetY)
end

function tree_manager:mousereleased(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击
    if self.is_dragging_node and self.goal_node and self.dragging_node then
        local goal_node = self.goal_node
        local dragging_node = self.dragging_node
        if dragging_node ~= goal_node then
            --print("添加")
            self:move_node(goal_node, dragging_node)
        end
    end
    --清空一下属性
    self.is_dragging_node = false
    self.goal_node = nil
    self.dragging_node = nil
end

-- 处理滚轮事件
function tree_manager:wheelmoved(id, x, y)
    if self.slider_orientation == 'v' then
        if self.contentHeight > self.height then
            --竖向
            self.offsetY = math.min(self.contentHeight - self.height, math.max(0, self.offsetY - y * self.scrollSpeed))
            local v_slider = self.v_slider
            v_slider.y = self.offsetY * (self.height / (self.contentHeight))
        end
    elseif self.slider_orientation == 'h' then
        if self.contentWidth > self.width then
            --横向
            self.offsetX = math.min(self.contentWidth - self.width, math.max(0, self.offsetX - y * self.scrollSpeed))
            local h_slider = self.h_slider
            h_slider.x = self.offsetX * (self.width / (self.contentWidth))
        end
    end
    --print(self.offsetY, self.height)
end

return tree_manager
