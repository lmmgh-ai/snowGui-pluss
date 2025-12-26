local view = require (lumenGui_path .. ".view.view")
local text = view:new()
text.__index = text
function text:new(tab)
    --这种创建对象方式 保证一些独立属性因为继承问题不会共用
    local new_obj = {
        type           = "text", --类型
        text           = "text",
        text_x         = 0,
        text_y         = 0,
        textColor      = { 0, 0, 0, 1 },         --文字颜色
        text_cache     = nil,                    --当文字被省略后原文字被存在这个变量中
        text_copy      = false,                  --是否允许复制文本
        text_align     = "center",               --left, center, right 文本对齐方式
        text_max_lines = 1,                      --最大显示行数
        text_ellipsis  = "left",                 --start middle end 省略前段中间结尾 size_to_fit 自适
        text_adapt     = "container_adapt_text", --text_adapt_container container_adapt_text 容器适应字体 字体适应容器
        --
        x              = x or 0,
        y              = y or 0,
        width          = width or 50,
        height         = height or 50,
        --
        parent         = nil, --父视图
        name           = "",  --以自己内存地址作为唯一标识
        id             = "",  --自定义索引
        children       = {},  -- 子视图列表
        _layer         = 1,   --图层
        _draw_order    = 1,   --默认根据 数值越大在当前图层越在前(目前视图在图层1起作用)
        gui            = nil, --管理器索引
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
    return new_obj
end

function text:init()
    --local font = love.graphics.newFont(self.textSize) -- 创建20px大小的字体
    --love.graphics.setFont(font)            -- 设置为当前字体
    -- self.font = font
    --love.graphics.setFont(font)
    --self:update_text_xy() --更新字体显示位置
    --self:adapt_text()
end

--初始对象回调
function text:on_create()
    --此初始化需要访问父类
    self:adapt_text()
end

--控件大小适应字体
function text:wh_adapt_textSize()

end

--字体大小适应控件
--单行
function text:textSize_adapt_wh()
    local manager = self.gui:get_font_manger()
    for i, font in ipairs(manager:get_default_font()) do

    end
end

function text:update_text_xy() --更新字体显示位置
    --初始化字体
    local font = self:get_font(self.font, self.textSize)

    -- 获取文本宽度和高度
    local text_width = tonumber(font:getWidth(self.text))
    local text_height = tonumber(font:getHeight()) -- 获取字体行高（单行高度）
    --设置文本居中显示
    self.text_x = (self.x + (self.width / 2)) - (text_width / 2)
    self.text_y = (self.y + (self.height / 2)) - (text_height / 2)
end

--解析字符串属性
function text:adapt_text(...)
    local text = tostring(self.text);

    ----------
    local font = self:get_font(self.font, self.textSize)

    -- 获取文本宽度和高度
    local text_width = tonumber(font:getWidth(text))
    local text_height = tonumber(font:getHeight()) -- 获取字体行高（单行高度）
    --local w, h = self:get_window_wh()              --窗口宽高
    -----
    local parent = self.parent or self.gui
    --print(self.width, text_width, parent)
    --print(self.width, parent.w, text_width)
    if self.text_adapt == "container_adapt_text" then
        if self.width >= text_width then
            --判断视图是否宽于字符串
            --print(self.id)
            self.height = text_height * self.text_max_lines
        else
            -- local n = ((text_width - (text_width % self.width)) / self.width) + 1
            if self.width * self.text_max_lines >= text_width then --判断视图满足最大行数是否宽于字符串
                local n = ((text_width - (text_width % self.width)) / self.width) + 1
                --print(parent.w, parent.id, text_width, n)

                self.height = text_height * n
            elseif parent.width * self.text_max_lines >= text_width then --文本宽度小于父视图
                self.width = text_width
                self.height = text_height * self.text_max_lines
            else
                -- text_max_lines = 1, --最大显示行数
                --  text_ellipsis = "end", --start middle end 省略前段中间结尾 size_to_fit 自适应多行
                self.text_cache = self.text;                               --缓存字符串
                local c_len = text_width / #self.text                      --取单个字符宽度
                local max_w = math.floor(self.text_max_lines * self.width) --视图可以显示最大宽度
                local max_str = (max_w - (max_w % c_len)) / c_len          --最大可以显示多少字符
                local text;
                if max_str < 3 then
                    text = "?"
                elseif self.text_ellipsis == "end" then
                    text = string.sub(self.text, 1, max_str - 3) .. "..." --根据规则截取字符串
                elseif self.text_ellipsis == "middle" then
                    --local text = string.sub(text, 1, max_str - 3) .. "..." --根据规则截取字符串
                elseif self.text_ellipsis == "start" then
                    local str_l = #self.text
                    text = "..." .. string.sub(self.text, str_l - max_str - 3, str_l) --根据规则截取字符串
                elseif self.text_ellipsis == "size_to_fit" then
                    local n = ((text_width - (text_width % parent.width)) / parent.width) + 1
                    --print(parent.w, parent.id, text_width, n)
                    self.width = parent.width
                    self.height = text_height * n
                    return
                else
                end
                self.text = text
                self.height = self.text_max_lines * text_height
                --print(c_len, max_w, max_str, text)
            end

            --[[
        if parent.w >= text_width then --判断父视图是否宽于字符串
            self.width = parent.w
        else
            local n = ((text_width - (text_width % parent.w)) / parent.w) + 1
            print(parent.w, parent.id, text_width, n)
            self.width = parent.w
            self.height = text_height * n
        end]]
        end
    elseif self.text_adapt == "text_adapt_container" then
        if self.height > text_height then
            self.textSize = math.floor(self.height / 2)
            local font = self:get_font(self.font, self.textSize)

            --
            local text_width = tonumber(font:getWidth(self.text))
            local text_height = tonumber(font:getHeight(self.text))
            --print(text_width, text_height)
            self.width = text_width
            self.height = text_height
        else

        end
    end
end

function text:draw()
    --绘制背景
    if self.isPressed then
        love.graphics.setColor(self.pressedColor)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5)
    elseif self.isHover then
        love.graphics.setColor(self.hoverColor)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5)
    else
        -- love.graphics.setColor(self.backgroundColor)
    end
    --文字
    love.graphics.setColor(self.textColor)
    local font = self:get_font(self.font, self.textSize)
    local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    --love.graphics.print(self.text, self.x + (self.width - textWidth) / 2, self.y + (self.height - textHeight) / 2)

    love.graphics.printf(self.text, self.x + self.text_x, self.y + self.text_y, self.width, self.text_align, 0)
end

--获取文字
function text:get_text()
    return self.text
end

return text;
