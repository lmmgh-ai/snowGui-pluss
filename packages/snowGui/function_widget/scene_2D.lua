local camera     = require(lumenGui_path .. ".libs.Camera.Camera")
---
local view       = require(lumenGui_path .. ".view.view")
local scene_2D   = view:new()
scene_2D.__index = scene_2D
function scene_2D:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type            = "scene_2D", --类型
        text            = "scene_2D",
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.8, 0.8, 1, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 0.6, 0.6, 1, 1 },
        borderColor     = { 0, 0, 0, 1 },
        --
        camera          = nil, --相机对象
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

--当被添加到gui系统后回调
--可以访问gui访问parent
function scene_2D:on_create()
    --已视图为边界初始摄像机
    self.camera = camera:new()
    --统一api设置摄像机视口
    local camera = self.camera
    -- print(x, y)
    --print(self.width)
    camera.viewport = self
end

--初始
function scene_2D:init()

end

function scene_2D:update(dt)
    local camera = self.camera
    -- camera:update(dt)
end

--绘制网格相关 待优化旋转后显示问题
function scene_2D:draw_grid()
    local camera = self.camera
    local viewport = camera.viewport
    camera.gridSize = 64 --标准大小
    --网格实时大小
    local gridSize = 64
    local text_size = 1
    if camera.scale <= 0.2 then
        gridSize = camera.gridSize * 16
        text_size = 2.7
    elseif camera.scale <= 0.4 then
        gridSize = camera.gridSize * 8
        text_size = 2
    elseif camera.scale <= 0.6 then
        gridSize = camera.gridSize * 4
        text_size = 1.5
    elseif camera.scale <= 0.8 then
        gridSize = camera.gridSize * 2
        text_size = 1.2
    end

    --
    local bound = camera.bounds
    local left = bound.left
    local right = bound.right
    local top = bound.top
    local bottom = bound.bottom

    --绘制视口
    --love.graphics.rectangle("fill", left + 10, top + 10, right - left - 20, bottom - top - 20)
    --  print(dump(bound))
    -- 计算可见的网格线范围
    -- 偏移一个距离
    local startX = math.floor(left / gridSize) * gridSize - (gridSize)
    local startY = math.floor(top / gridSize) * gridSize - (gridSize)
    local finishX = math.floor(right / gridSize) * gridSize + (gridSize)
    local finishY = math.floor(bottom / gridSize) * gridSize + (gridSize)
    --print(finishX, finishY)
    --
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5) -- 网格颜色
    love.graphics.setLineWidth(1)
    --
    for x = startX, finishX, gridSize do
        -- 绘制垂直线
        love.graphics.line(x, startY, x, finishY)
    end
    for y = startY, finishY, gridSize do
        -- 绘制水平线
        love.graphics.line(startX, y, finishX, y)
    end
    for x = startX, finishX, gridSize do
        for y = startY, finishY, gridSize do
            love.graphics.circle("fill", x, y, 2) --绘制交点
        end
    end


    -- 绘制中心轴
    love.graphics.setColor(0.5, 0.5, 1, 0.7) -- 蓝色中心线
    love.graphics.setLineWidth(2)
    local font = self:get_font(self.font, self.textSize)
    local textHeight = font:getHeight()
    local textwidth = font:getWidth("0000") --4位数宽度

    --绘制原点
    love.graphics.circle("fill", 0, 0, 5)

    --绘制x轴
    if startY < 0 and finishY > 0 then --轴在屏幕内
        love.graphics.line(startX, 0, finishX, 0)
        --绘制坐标 刻度
        for x = startX, finishX, gridSize do
            --love.graphics.print(string.format("%d", x), x, 0)
            love.graphics.printf(string.format("%d", x), x, 0, textwidth, "left", 0, text_size, text_size)
        end
    elseif startY + gridSize > 0 then --轴在屏幕下方
        for x = startX, finishX, gridSize do
            --love.graphics.print(string.format("%d", x), x, top)
            love.graphics.printf(string.format("%d", x), x, top, textwidth, "left", 0, text_size, text_size)
        end
    elseif finishY - gridSize < 0 then --轴在屏幕上方
        for x = startX, finishX, gridSize do
            -- love.graphics.print(string.format("%d", x), x, bottom - textHeight)
            love.graphics.printf(string.format("%d", x), x, bottom - textHeight, textwidth, "left", 0, text_size,
                text_size)
        end
    end


    --绘制Y轴
    if startX < 0 and finishX > 0 then
        love.graphics.line(0, startY, 0, finishY)
        --绘制坐标 刻度
        for y = startY, finishY, gridSize do
            -- love.graphics.print(string.format("%d", y), 0, y)
            love.graphics.printf(string.format("%d", y), 0, y, textwidth, "left", 0, text_size, text_size)
        end
    elseif startX + gridSize > 0 then --轴在屏幕右侧
        for y = startY, finishY, gridSize do
            -- love.graphics.print(string.format("%d", y), left, y)
            love.graphics.printf(string.format("%d", y), left, y, textwidth, "left", 0, text_size, text_size)
        end
    elseif finishX - gridSize < 0 then --轴在屏幕左侧
        for y = startY, finishY, gridSize do
            --love.graphics.print(string.format("%d", y), right - textwidth, y)
            love.graphics.printf(string.format("%d", y), right - textwidth, y, textwidth, "left", 0, text_size, text_size)
        end
    end
end

--绘制坐标系
function scene_2D:coord_draw()
    -- body
    camera = self.camera;
    viewport = camera.viewport --获取世界视口
    local view_size = 60
    local axisLength = 15
    local x = view_size / 2 - self.x
    local y = viewport.height - view_size / 2 - self.y
    --变换坐标系
    love.graphics.push()
    love.graphics.translate(x, y) --变换坐标系
    love.graphics.rotate(camera.rotation)
    --绘制原点
    --love.graphics.circle("fill", x, y, 5)
    --绘制X轴
    love.graphics.setColor(1, 0, 0)
    love.graphics.line(0, 0, axisLength, 0)
    love.graphics.circle("fill", axisLength, 0, 3)
    love.graphics.print("X", axisLength, 0)
    --绘制y轴
    -- 绘制y轴（绿色）
    love.graphics.setColor(0, 1, 0)
    love.graphics.line(0, 0, 0, axisLength)
    love.graphics.circle("fill", 0, axisLength, 3)
    love.graphics.print("Y", 0, axisLength)
    love.graphics.pop()
    --print(x, y)
end

--在场景坐标下绘制虚拟屏幕
function scene_2D:virtual_screen_draw()
    love.graphics.setColor({ 0, 0.5, 1, 1 })
    local virtual_screen = self.camera.virtual_screen
    love.graphics.rectangle("line", virtual_screen.x, virtual_screen.y, virtual_screen.width, virtual_screen.height)
    --绘制分辨率
    local text = virtual_screen.width .. " X " .. virtual_screen.height
    local font = self:get_font(self.font, self.textSie)
    local textWidth = font:getWidth(text)
    love.graphics.print(text, virtual_screen.x + virtual_screen.width - textWidth, virtual_screen.y)
end

function scene_2D:draw()
    if not self.visible then return end
    --
    local camera = self.camera
    -- 绘制背景
    if self.isPressed then
        love.graphics.setColor(self.pressedColor)
    elseif self.isHover then
        love.graphics.setColor(self.hoverColor)
    else
        love.graphics.setColor(self.backgroundColor)
    end
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    -- love.graphics.push()
    --love.graphics.translate(self.x, self.y)
    --摄像机接管绘图 绘图坐标系转化为局部
    camera:attach()
    -- Draw your game here
    self:draw_grid()           --绘制网格
    self:virtual_screen_draw() --绘制虚拟屏幕
    --
    --love.graphics.rectangle("line", camera.screen_x, camera.screen_y, camera.w, camera.h, 5)
    --love.graphics.rectangle("fill", 0, 0, 50, 50)
    camera:detach()   --相机绘图结束
    --绘制相机坐标系标识
    self:coord_draw() --绘制坐标系
    --love.graphics.pop()
    --绘制相机屏幕
    -- love.graphics.rectangle("line", camera.viewport.x, camera.viewport.y, camera.viewport.w, camera.viewport.h)
end

--真实屏幕坐标转化为场景坐标
function scene_2D:world_to_scene_position(x, y)
    local camera = self.camera
    local x, y = self:get_local_Position(x + self.x, y + self.y)
    local x, y = camera:world_to_scene_position(x, y)
    return x, y
end

--场景坐标转化为屏幕坐标
--场景坐标转化为真实屏幕坐标
function scene_2D:scene_to_world_position(x, y)
    local camera = self.camera
    local x, y = camera:scene_to_world_position(x, y)
    local x1, y1 = self:get_world_Position(x, y)
    return x1 - self.x, y1 - self.y
end

function scene_2D:mousepressed(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击
end

function scene_2D:mousereleased(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击

end

function scene_2D:mousemoved(id, x, y, dx, dy, istouch, pre)
    local camera = self.camera
    -- local x, y = self:get_local_Position(x, y)
    -- print(x, y)
    --print(camera:toCameraCoords(0, 0))
    --print("tos" .. camera:worldToScreen(0, 0))
    --print("tow" .. camera:screenToWorld(0, 0))
    --print(camera:toWorldCoords(0, 0))
    if self.isPressed then
        camera:move(dx, dy)
    end
end

function scene_2D:wheelmoved(id, x, y) --滚轮滑动
    local camera = self.camera
    camera:wheel_Scale(-y)
    print("scale:" .. camera.scale)
    --print(dump(camera.bounds))
end

function scene_2D:on_click(id, x, y, dx, dy, istouch, pre)
    -- body
    local camera = self.camera
    --self:destroy()
    --print("stow", self:scene_to_world_position(0, 0))

    print("wtos", self:world_to_scene_position(x, y))
    -- local x, y = camera:scene_to_world_position(0, 0)
    -- local x1, y1 = self:get_world_Position(x, y)
    --print(x, y)
    -- print(self:scene_world_position(0, 0))
end

function scene_2D:keypressed(key)
    -- body
    local camera = self.camera
    if key == "q" then
        camera:rotate_radian(-10)
    elseif key == "e" then
        camera:rotate_radian(10)
    end
    print(dump(camera.bounds))
    print(self:world_to_scene_position(0, 0))
    print(self:world_to_scene_position(0, 200))
end

function scene_2D:object_draw()

end

return scene_2D;
