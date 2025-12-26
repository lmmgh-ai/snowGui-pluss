local view = require(lumenGui_path .. ".view.view")
local image = view:new()
image.__index = image


-- 缩放模式枚举
image.SCALE_TYPES = {
    CENTER = 1,        -- 居中显示，不缩放
    CENTER_CROP = 2,   -- 保持宽高比缩放，使图片完全覆盖控件区域
    CENTER_INSIDE = 3, -- 保持宽高比缩放，使图片完全显示在控件内
    FIT_XY = 4,        -- 不保持宽高比，拉伸填满控件
    FIT_START = 5,     -- 保持宽高比，对齐左上角
    FIT_END = 6,       -- 保持宽高比，对齐右下角
    FIT_CENTER = 7     -- 保持宽高比，居中显示(同CENTER_INSIDE)
}

--图片缓存池是否创建
if not _G.image_buffer then
    --首次加载
    _G.image_buffer = setmetatable({}, {})
    local base64_icon = require(lumenGui_path .. ".icon")
    --加载默认图片
    local decodedData = love.data.decode("data", "base64", base64_icon)
    -- 创建ImageData
    local success, imageData = pcall(love.image.newImageData, decodedData)
    -- 创建Image
    local success, ima = pcall(love.graphics.newImage, imageData)
    --添加默认索引 icon 默认缓存
    local key = love.data.encode("string", "hex", love.data.hash("md5", "icon"))
    image_buffer[key] = { mode = "base64", path = base64_icon, image_obj = ima }
end
--新建
function image:new(tab)
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type            = "image", --类型
        text            = "image",
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.8, 0.8, 1, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 0.6, 0.6, 1, 1 },
        borderColor     = { 0, 0, 0, 1 },
        --
        -- 加载图片
        image_path      = nil, --图片的来源
        image           = nil, --love.graphics.newImage(path),
        imgWidth        = nil, --self.image:getWidth(),
        imgHeight       = nil, --self.image:getHeight(),
        -- 缩放相关属性
        scaleType       = 7 or image.SCALE_TYPES.FIT_CENTER,
        scaleX          = 1,
        scaleY          = 1,
        drawOffsetX     = 0,
        drawOffsetY     = 0,
        originX         = 0,
        originY         = 0,
        --其他属性
        color           = { 1, 1, 1, 1 },
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

--初始化
function image:init()
    if self.image_path then
        return self:set_image(self.image_path)
    end
    --未设置图片使用默认
    if not self.image and not self.image_path then
        -- local b = self:load_Base64_image(default_base64)
        --print(love.data.encode("string", "hex", love.data.hash("md5", default_base64)))
        return self:set_image("icon", "base64")
    end
end

--当被set_wh等api修改宽高时更新
--如果返回值为true 则通知父视图与子视图
--默认不通知 只有需要响应手动通知
function image:change_from_self(child_view)
    --
    --根据缩放模式更新
    self:updateScaleParams()
    --返回两个参数 true通知父布局更新 true通知子视图更新
    return false, false;
end

--设置图片
function image:set_image(path, mode)
    local path            = path or "icon" --设置为初始图片
    local mode            = mode or "path"

    local ima, path, mode = self:check_buffer(path, mode)
    self.image            = ima             --设置图片对象
    self.imgWidth         = ima:getWidth()  --获取图片宽
    self.imgHeight        = ima:getHeight() --获取图片高

    -- print(123)
    --更新缩放模式
    self:updateScaleParams()
end

--检查图片池中缓存 避免重复加载图片
--base64模式 path为字符数据
function image:check_buffer(path, mode)
    local image_buffer = _G.image_buffer
    --获取键值
    local key = love.data.encode("string", "hex", love.data.hash("md5", path))

    --检查表中索引
    if image_buffer[key] then
        --缓存存在 返回
        local buffer = image_buffer[key]
        return buffer.image_obj, buffer.path, buffer.mode
    else
        --缓存不存在 添加后返回
        if string.lower(mode) == "path" then
            local image = self:load_image(path)
            --添加缓存
            self:add_to_buffer(image, path, "path")
            return image, path, "path"
        elseif string.lower(mode) == "base64" then
            local image = self:load_Base64_image(path)
            --添加缓存
            self:add_to_buffer(image, path, "base64")
            return image, path, "base64"
        else
            assert(false, "type erro")
        end
    end
end

--添加到缓存
--base64模式 path为字符数据
function image:add_to_buffer(image_obj, path, mode)
    local image_buffer = _G.image_buffer
    if string.lower(mode) == "path" then
        --路径转换为hex值 作为缓存键值
        local key = love.data.encode("string", "hex", love.data.hash("md5", path))

        image_buffer[key] = setmetatable({ mode = "path", path = path, image_obj = image_obj }, { __mode = "v" })
    elseif string.lower(mode) == "base64" then
        --数据转换为hex值 作为缓存键值
        local key = love.data.encode("string", "hex", love.data.hash("md5", path))
        --base64 时path是它的字符数据
        image_buffer[key] = setmetatable({ mode = "base64", path = path, image_obj = image_obj }, { __mode = "v" })
    end
end

--删除缓存
--base64模式 path为字符数据
function image:remove_buffer(path)
    local image_buffer = _G.image_buffer
    --获取键值
    local key = love.data.encode("string", "hex", love.data.hash("md5", path))
    --检查表中索引
    if image_buffer[key] then
        image_buffer[key] = nil
    end
end

--加载路径图片
function image:load_image(path)
    --错误抓取
    local success, ima = pcall(love.graphics.newImage, path)
    -- print(success, ima)
    if success then
        return love.graphics.newImage(path)
    else
        assert(false, "load image error form :", path)
    end
end

--加载base64图片
function image:load_Base64_image(base64String)
    local decodedData = love.data.decode("data", "base64", base64String)

    -- 创建ImageData
    local success, imageData = pcall(love.image.newImageData, decodedData)
    if not success then
        print("Failed to create ImageData from Base64:", imageData)
        return false
    end

    -- 创建Image
    local success, ima = pcall(love.graphics.newImage, imageData)
    if not success then
        print("Failed to create Image from ImageData:")
        return false
    end
    return ima
end

-- 更新缩放参数(根据当前缩放模式)
function image:updateScaleParams()
    local imgW, imgH = self.imgWidth, self.imgHeight
    local viewW, viewH = self.width, self.height

    if self.scaleType == self.SCALE_TYPES.CENTER then
        -- 居中显示原始大小
        self.scaleX      = 1
        self.scaleY      = 1
        self.drawOffsetX = (viewW - imgW) / 2
        self.drawOffsetY = (viewH - imgH) / 2
    elseif self.scaleType == self.SCALE_TYPES.CENTER_CROP then
        -- 保持宽高比，缩放至完全覆盖控件
        local scale      = math.max(viewW / imgW, viewH / imgH)
        self.scaleX      = scale
        self.scaleY      = scale
        self.drawOffsetX = (viewW - imgW * scale) / 2
        self.drawOffsetY = (viewH - imgH * scale) / 2
    elseif self.scaleType == self.SCALE_TYPES.CENTER_INSIDE
        or self.scaleType == self.SCALE_TYPES.FIT_CENTER then
        -- 保持宽高比，缩放至完全显示在控件内
        local scale      = math.min(viewW / imgW, viewH / imgH)
        self.scaleX      = scale
        self.scaleY      = scale
        self.drawOffsetX = (viewW - imgW * scale) / 2
        self.drawOffsetY = (viewH - imgH * scale) / 2
    elseif self.scaleType == self.SCALE_TYPES.FIT_XY then
        -- 不保持宽高比，拉伸填满控件
        self.scaleX      = viewW / imgW
        self.scaleY      = viewH / imgH
        self.drawOffsetX = 0
        self.drawOffsetY = 0
    elseif self.scaleType == self.SCALE_TYPES.FIT_START then
        -- 保持宽高比，对齐左上角
        local scale      = math.min(viewW / imgW, viewH / imgH)
        self.scaleX      = scale
        self.scaleY      = scale
        self.drawOffsetX = 0
        self.drawOffsetY = 0
    elseif self.scaleType == self.SCALE_TYPES.FIT_END then
        -- 保持宽高比，对齐右下角
        local scale      = math.min(viewW / imgW, viewH / imgH)
        self.scaleX      = scale
        self.scaleY      = scale
        self.drawOffsetX = viewW - imgW * scale
        self.drawOffsetY = viewH - imgH * scale
    end
end

-- 修改后的绘制方法
function image:draw()
    if not self.visible then return end

    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4])
    -- 绘制图片(应用缩放和偏移)
    love.graphics.draw(self.image,
        self.drawOffsetX + self.x,
        self.drawOffsetY + self.y,
        0,
        self.scaleX,
        self.scaleY)
    --绘制控件参考边框
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
end

-- 设置缩放模式后需要更新参数
function image:setScaleType(scaleType)
    if self.SCALE_TYPES[scaleType] then
        self.scaleType = self.SCALE_TYPES[scaleType]
    else
        self.scaleType = scaleType
    end
    self:updateScaleParams()
end

-- 设置控件尺寸时也需要更新缩放参数
function image:setSize(width, height)
    self.width  = width or self.width
    self.height = height or self.height
    self:updateScaleParams()
end

-- 更新方法(用于处理动画等)
function image:update(dt)
    -- 可以在这里添加动画逻辑
end

function image:on_click(id, x, y, dx, dy, istouch, pre)
    -- body
    --self:destroy()
    print(self.type, self:get_local_Position(x, y))
end

return image;
