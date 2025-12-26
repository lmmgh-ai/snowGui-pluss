-- 2D摄像机系统
-- 特性：
-- 1. 中心矩形坐标系
-- 2. 可设置视口(x,y,w,h)
-- 3. 摄像机原点在视口中心
-- 4. 支持平移、缩放、旋转
-- 5. 提供视口到摄像机坐标系的映射功能

local Camera = {}
Camera.__index = Camera

-- 创建新摄像机
-- @param x 视口x坐标
-- @param y 视口y坐标
-- @param w 视口宽度
-- @param h 视口高度
-- @return 新的摄像机对象
function Camera:new(x, y, width, height)
    local cam    = setmetatable({}, self)

    -- 视口设置(屏幕坐标系)
    cam.viewport = {
        x = x or 0,                                   -- 视口左上角x坐标
        y = y or 0,                                   -- 视口左上角y坐标
        width = width or love.graphics.getWidth(),    -- 视口宽度
        height = height or love.graphics.getHeight(), -- 视口高度
    }


    --print(cam.viewport.centerX, cam.viewport.centerY)
    -- 摄像机变换参数
    cam.x        = 0 -- 摄像机x位置(世界坐标)
    cam.y        = 0 -- 摄像机y位置(世界坐标)
    cam.scale    = 1 -- 缩放因子(1为原始大小)
    cam.rotation = 0 -- 旋转角度(弧度)



    -- 视口边界(摄像机坐标系)视口映射到摄像机坐标系内视图
    cam.bounds = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0
    }

    --在场景中设置一个虚拟屏幕
    cam.virtual_screen = {
        x = 0,
        y = 0,
        width = 800,
        height = 600,
    }

    -- 更新边界
    cam:updateBounds()

    return cam
end

function Camera:get_viewport_crnterXY()
    -- body
    local vx = self.viewport.x
    local vy = self.viewport.y
    local vwidth = self.viewport.width
    local vheight = self.viewport.height
    return vx - vwidth / 2, vy - vheight / 2
end

-- 更新视口边界(用于判断元素是否在屏幕附近)
function Camera:updateBounds()
    local vwidth = self.viewport.width
    local vheight = self.viewport.height

    -- 计算视口在摄像机坐标系中的边界
    -- 考虑缩放和旋转的影响

    -- 视口半宽和半高
    local halfW = vwidth / (2 * self.scale)
    local halfH = vheight / (2 * self.scale)

    -- 计算旋转后的边界
    local cos, sin = math.cos(-self.rotation), math.sin(-self.rotation)

    -- 旋转后的边界点
    local points = {
        { x = -halfW, y = -halfH },
        { x = halfW,  y = -halfH },
        { x = halfW,  y = halfH },
        { x = -halfW, y = halfH }
    }

    -- 初始化边界值
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge

    -- 计算旋转后的边界
    for _, p in ipairs(points) do
        -- 应用旋转
        local rx = p.x * cos - p.y * sin
        local ry = p.x * sin + p.y * cos

        -- 更新最小最大值
        minX = math.min(minX, rx)
        maxX = math.max(maxX, rx)
        minY = math.min(minY, ry)
        maxY = math.max(maxY, ry)
    end

    -- 设置边界(相对于摄像机位置)
    --[[
    self.bounds.left   = self.x + minX
    self.bounds.right  = self.x + maxX
    self.bounds.top    = self.y + minY
    self.bounds.bottom = self.y + maxY
    ]]
    -- print(self.x)
    self.bounds.top = -(self.y + maxY)
    self.bounds.bottom = -(self.y + minY)
    self.bounds.left = -(self.x + maxX)
    self.bounds.right = -(self.x + minX)
end

-- 获取视口映射到场景的真实坐标
-- return 4个点(摄像机坐标)
function Camera:get_Bounds()
    -- 计算视口在摄像机坐标系中的边界
    -- 考虑缩放和旋转的影响
    --local
end

-- 获取摄像机视口边界(世界坐标)
-- @return 左,右,上,下边界
function Camera:getBounds()
    return self.bounds.left, self.bounds.right, self.bounds.top, self.bounds.bottom
end

-- 设置摄像机位置(世界坐标)
-- @param x 世界x坐标
-- @param y 世界y坐标
function Camera:setPosition(x, y)
    self.x = x or self.x
    self.y = y or self.y
    self:updateBounds()
end

-- 移动摄像机(相对当前位置)
-- @param dx x方向移动量
-- @param dy y方向移动量
function Camera:move(dx, dy)
    local dx = dx or 0
    local dy = dy or 0
    local scale = self.scale
    self.x = self.x + (dx / scale)
    self.y = self.y + (dy / scale)
    self:updateBounds()
end

-- 设置缩放
-- @param scale 新的缩放值
function Camera:setScale(scale)
    self.scale = scale or self.scale
    self:updateBounds()
end

--滚轮缩放
-- @param value 一般是滚轮的y值
function Camera:wheel_Scale(value)
    if self.scale - value / 10 > 0.1 then
        self.scale = self.scale - value / 10
    end
    self:updateBounds()
end

-- 设置旋转角度(弧度)
-- @param rotation 新的旋转角度
function Camera:set_radian(rotation)
    self.rotation = rotation or self.rotation
    self:updateBounds()
end

-- 旋转摄像机(相对当前角度)
-- @param dr 旋转增量(弧度)
function Camera:rotate_radian(dr)
    self.rotation = self.rotation + (dr or 0)
    self:updateBounds()
end

-- 设置旋转角度(角度)
-- @param rotation 新的旋转角度
function Camera:set_angle(ang)
    local rotation = math.rad(ang)
    self.rotation = rotation or self.rotation
    self:updateBounds()
end

-- 旋转摄像机(相对当前角度)
-- @param dr 旋转增量(角度)
function Camera:rotate_radian(dr_ang)
    local dr = math.rad(dr_ang)
    self.rotation = self.rotation + (dr or 0)
    self:updateBounds()
end

-- 应用摄像机变换(在绘制前调用)
function Camera:attach()
    love.graphics.push()
    local viewport = self.viewport
    local centerX = viewport.x + viewport.width / 2
    local centerY = viewport.y + viewport.height / 2
    -- 设置视口
    love.graphics.setScissor(viewport.x, viewport.y, viewport.width, viewport.height)
    -- 变换到视口中心
    -- print(centerX, centerY)
    love.graphics.translate(centerX, centerY)

    -- 应用摄像机变换(缩放->旋转->平移)
    love.graphics.scale(self.scale)
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
end

-- 恢复原始状态(在绘制后调用)
function Camera:detach()
    love.graphics.pop()
    love.graphics.setScissor()
end

-- 将世界(屏幕)转换为场景(摄像机)坐标
-- @param worldX 屏幕x坐标
-- @param worldY 世界y坐标
-- @return 场景坐标x, y
function Camera:world_to_scene_position(worldX, worldY)
    -- 转换为相对于视口中心的坐标
    local viewport = self.viewport
    local centerX = viewport.x + viewport.width / 2
    local centerY = viewport.y + viewport.height / 2
    local x = worldX - centerX
    local y = worldY - centerY

    -- 应用逆变换(缩放->旋转)
    local invScale = 1 / self.scale
    x, y = x * invScale, y * invScale

    -- 应用逆旋转
    local cos, sin = math.cos(self.rotation), math.sin(self.rotation)
    local wx = x * cos - y * sin
    local wy = x * sin + y * cos

    -- 加上摄像机位置得到世界坐标
    return wx - self.x, wy - self.y
end

-- 将场景坐标转换为世界坐标
-- @param sceneX 世界x坐标
-- @param sceneY 世界y坐标
-- @return 屏幕坐标x, y

function Camera:scene_to_world_position(sceneX, sceneY)
    -- 转换为相对于摄像机的位置
    local x = sceneX + self.x
    local y = sceneY + self.y

    -- 应用旋转
    local cos, sin = math.cos(-self.rotation), math.sin(-self.rotation)
    local rx = x * cos - y * sin
    local ry = x * sin + y * cos

    -- 应用缩放
    rx, ry = rx * self.scale, ry * self.scale
    local viewport = self.viewport
    local centerX = viewport.x + viewport.width / 2
    local centerY = viewport.y + viewport.height / 2
    -- 转换为屏幕坐标
    return rx + centerX, ry + centerY
end

-- 检查世界坐标是否在视口内(考虑旋转和缩放)
-- @param x 世界x坐标
-- @param y 世界y坐标
-- @param padding 额外的边距(可选)
-- @return 是否在视口内
function Camera:isInView(x, y, padding)
    padding = padding or 0

    -- 转换为摄像机坐标系
    local camX, camY = x - self.x, y - self.y

    -- 应用旋转(反向旋转)
    local cos, sin = math.cos(self.rotation), math.sin(self.rotation)
    local rx = camX * cos - camY * sin
    local ry = camX * sin + camY * cos

    -- 检查是否在视口边界内(考虑缩放)
    local halfW = self.viewport.width / (2 * self.scale) + padding
    local halfH = self.viewport.height / (2 * self.scale) + padding

    return math.abs(rx) <= halfW and math.abs(ry) <= halfH
end

return Camera
