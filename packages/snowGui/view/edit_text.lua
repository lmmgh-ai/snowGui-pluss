local view = require(lumenGui_path .. ".view.view")
local utf8 = require("utf8")
utf8.sub = function(str, start_pos, end_pos)
    local len = utf8.len(str)
    if not len then
        error("Invalid UTF-8 string")
    end

    start_pos = start_pos or 1
    end_pos = end_pos or len

    -- 处理负数索引
    if start_pos < 0 then
        start_pos = len + start_pos + 1
    end
    if end_pos < 0 then
        end_pos = len + end_pos + 1
    end

    -- 边界检查
    start_pos = math.max(1, math.min(start_pos, len + 1))
    end_pos = math.max(0, math.min(end_pos, len))

    if start_pos > end_pos then
        return ""
    end

    local start_byte = utf8.offset(str, start_pos)
    local end_byte = utf8.offset(str, end_pos + 1)

    if not start_byte then
        return ""
    end

    if not end_byte then
        return string.sub(str, start_byte)
    else
        return string.sub(str, start_byte, end_byte - 1)
    end
end



-- 纯文本编辑器类
local edit_text = view:new()
edit_text.__index = edit_text

function edit_text:new()
    --这种创建对象方式 保证一些独立属性在继承同一个父对象也不受影响
    local new_obj = {
        type            = "edit_text", --类型
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.9, 0.9, 0.9, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 255, 255, 255, 1 },
        borderColor     = { 0, 0, 0, 1 },
        -- 文本内容（按行存储）
        lines           = { "" },
        -- 光标位置
        cursorX         = 1,
        cursorY         = 1,
        -- 选择范围
        selectStartX    = nil,
        selectStartY    = nil,
        selectEndX      = nil,
        selectEndY      = nil,
        -- 视图相关
        scrollX         = 0,
        scrollY         = 0,
        lineHeight      = 16,
        charWidth       = 8,
        -- 功能开关
        autoWrap        = false, -- 自动换行
        showLineNumbers = true,  -- 显示行号
        autoIndent      = true,  -- 自动缩进
        -- 行号栏宽度
        lineNumberWidth = 40,
        -- 拖拽选择时的定时器
        dragTimer       = 0,
        dragInterval    = 0.1,
        cursorColor     = { 0, 0, 1, 1 }, -- 光标颜色
        cursorBlinkTime = 0,              -- 光标闪烁计时器
        ------
        x               = 0,
        y               = 0,
        width           = 200,
        height          = 200,
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

--初始回调可以访问父视图 gui
function edit_text:on_create()
    self:setText(self.text)
end

-- 获取指定行的字符数量（考虑UTF-8）
function edit_text:getLineCharCount(lineNum)
    if lineNum > #self.lines or lineNum < 1 then
        return 0
    end
    return utf8.len(self.lines[lineNum]) or 0
end

-- 获取指定位置的字符宽度（用于处理中文等多字节字符）
function edit_text:getCharWidth(char)
    local font = self:get_font(self.font, self.textSize)
    return font:getWidth(char)
end

-- 将屏幕坐标转换为文本坐标
--鼠标
function edit_text:screenToTextCoord(screenX, screenY)
    local x, y = screenX, screenY

    -- 考虑滚动偏移
    x = x + self.scrollX
    y = y + self.scrollY

    -- 计算行号
    local lineNum = math.floor(y / self.lineHeight) + 1
    lineNum = math.max(1, math.min(lineNum, #self.lines))
    -- print(1, ":", x)
    -- 如果显示行号，需要减去行号栏宽度
    if self.showLineNumbers then
        x = x - self.lineNumberWidth
    end
    --print(2, ":", x)
    -- 计算列位置
    local line = self.lines[lineNum] or ""
    local charPos = 1
    --print(3, line)
    if line ~= "" then
        local currentX = 0
        local i = 1

        -- 逐字符计算位置，正确处理UTF-8字符
        while i <= #line do
            local byte = string.byte(line, i)
            local charByteCount = 1

            -- 判断UTF-8字符长度
            if byte >= 0xF0 then
                charByteCount = 4
            elseif byte >= 0xE0 then
                charByteCount = 3
            elseif byte >= 0xC0 then
                charByteCount = 2
            end

            local char = string.sub(line, i, i + charByteCount - 1)
            local charWidth = self:getCharWidth(char)
            --  print(char, charWidth)
            -- 如果当前位置已经超过鼠标点击位置，则返回上一个位置

            if currentX - charWidth / 2 > x then --前半
                -- print("31", currentX + charWidth / 2, x)
                --  print(32, i, utf8.offset(line, 1, i))
                --  charPos = utf8.offset(line, 1, i) or (i + charByteCount)
                charPos = charPos - 1
                break
            elseif currentX > x then
                charPos = charPos - 1
            elseif currentX >= x then --前半
            end

            currentX = currentX + charWidth
            charPos = charPos + 1
            i = i + charByteCount
            --print(31, currentX)
            -- 防止无限循环
            if i > #line + 1 then
                break
            end
        end
    end
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(line)
    --print(4, textWidth)
    --print(5, charPos, lineNum)
    return charPos, lineNum
end

-- 获取可视区域内的行范围
function edit_text:getVisibleLines()
    local startLine = math.floor(self.scrollY / self.lineHeight) + 1
    local endLine = math.floor((self.scrollY + self.height) / self.lineHeight) + 1
    startLine = math.max(1, startLine)
    endLine = math.min(#self.lines, endLine)
    return startLine, endLine
end

-- 绘制编辑器
function edit_text:draw()
    --love.graphics.setFont(self.font)
    local font = self:get_font(self.font, self.textSize)
    -- 绘制背景
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    -- 获取可见行范围
    local startLine, endLine = self:getVisibleLines()

    -- 绘制选中区域
    love.graphics.setColor(0.7, 0.8, 1)
    self:drawSelection(startLine, endLine)

    -- 绘制文本和行号
    love.graphics.setColor(self.textColor)
    for i = startLine, endLine do
        local y = (i - 1) * self.lineHeight - self.scrollY + self.y
        -- 绘制文本
        local textX = self.showLineNumbers and self.lineNumberWidth or 0
        textX = textX - self.scrollX + self.x
        love.graphics.print(self.lines[i], textX, y)
        --绘制行号背景
        -- love.graphics.setColor(self.backgroundColor)
        --love.graphics.rectangle("fill", self.x, self.y, self.lineNumberWidth, self.height)

        -- 绘制行号
        if self.showLineNumbers then
            --love.graphics.print(tostring(i), 5, y)
            love.graphics.printf(tostring(i), 5 + self.x, y, self.lineNumberWidth * 0.6, "right")
        end
    end

    --绘制边框
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.setColor(self.textColor)
    --绘制文字
    love.graphics.print(string.format(" R:%d/%d C:%d auto:%s | N:%s",
            self.cursorY, #self.lines, self.cursorX,
            self.autoWrap and "on" or "off",
            self.showLineNumbers and "on" or "off"),
        self.x, self.y + self.height - font:getHeight())
    -- 绘制光标
    if self.cursorBlinkTime % 1 < 0.5 then
        self:drawCursor()
    end
end

-- 绘制选中区域
function edit_text:drawSelection(startLine, endLine)
    if not self:hasSelection() then return end

    local startX, startY, endX, endY = self:getNormalizedSelection()

    for i = startLine, endLine do
        local y = (i - 1) * self.lineHeight - self.scrollY

        if i >= startY and i <= endY then
            local line = self.lines[i]
            local textX = self.showLineNumbers and self.lineNumberWidth or 0
            textX = textX - self.scrollX

            if startY == endY then
                -- 单行选择
                local startPixel = self:getTextPositionInPixels(line, startX)
                local endPixel = self:getTextPositionInPixels(line, endX)
                love.graphics.rectangle("fill", textX + startPixel, y, endPixel - startPixel, self.lineHeight)
            elseif i == startY then
                -- 选择起始行
                local startPixel = self:getTextPositionInPixels(line, startX)
                local linePixelWidth = self:getTextPositionInPixels(line, self:getLineCharCount(i) + 1)
                love.graphics.rectangle("fill", textX + startPixel, y, linePixelWidth - startPixel, self.lineHeight)
            elseif i == endY then
                -- 选择结束行
                local endPixel = self:getTextPositionInPixels(line, endX)
                love.graphics.rectangle("fill", textX, y, endPixel, self.lineHeight)
            else
                -- 中间完整行
                local linePixelWidth = self:getTextPositionInPixels(line, self:getLineCharCount(i) + 1)
                love.graphics.rectangle("fill", textX, y, linePixelWidth, self.lineHeight)
            end
        end
    end
end

-- 获取文本位置对应的像素位置（正确处理UTF-8）
function edit_text:getTextPositionInPixels(text, charPos)
    if charPos <= 1 then return 0 end

    local pixelPos = 0
    local currentChar = 1
    local i = 1

    while i <= #text and currentChar < charPos do
        local byte = string.byte(text, i)
        local charByteCount = 1

        if byte >= 0xF0 then
            charByteCount = 4
        elseif byte >= 0xE0 then
            charByteCount = 3
        elseif byte >= 0xC0 then
            charByteCount = 2
        end

        local char = string.sub(text, i, i + charByteCount - 1)
        pixelPos = pixelPos + self:getCharWidth(char)
        currentChar = currentChar + 1
        i = i + charByteCount
    end

    return pixelPos
end

-- 绘制光标
function edit_text:drawCursor()
    -- 只在没有选择时绘制光标
    if self:hasSelection() then return end

    local cursorPixelX = self:getTextPositionInPixels(self.lines[self.cursorY], self.cursorX)
    local cursorScreenX = cursorPixelX
    if self.showLineNumbers then
        cursorScreenX = cursorScreenX + self.lineNumberWidth
    end
    -- print(self.x)
    cursorScreenX = cursorScreenX - self.scrollX + 200 --self.x

    local cursorY = (self.cursorY - 1) * self.lineHeight - self.scrollY + self.y

    -- 确保光标在可视区域内才绘制
    if cursorScreenX >= (self.showLineNumbers and self.lineNumberWidth or 0) and
        cursorScreenX <= self.width and
        cursorY >= 0 and cursorY <= self.height then
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(2)
        love.graphics.line(cursorScreenX, cursorY, cursorScreenX, cursorY + self.lineHeight)
    end
end

-- 检查是否有文本选择
function edit_text:hasSelection()
    return self.selectStartX ~= nil and self.selectEndX ~= nil
end

-- 获取标准化的选择范围（确保start <= end）
function edit_text:getNormalizedSelection()
    if not self:hasSelection() then return 0, 0, 0, 0 end

    local startX, startY, endX, endY = self.selectStartX, self.selectStartY, self.selectEndX, self.selectEndY

    -- 标准化选择范围
    if startY > endY or (startY == endY and startX > endX) then
        startX, startY, endX, endY = endX, endY, startX, startY
    end

    return startX, startY, endX, endY
end

-- 获取选择的文本
function edit_text:getSelectedText()
    if not self:hasSelection() then return "" end

    local startX, startY, endX, endY = self:getNormalizedSelection()
    local selectedText = ""

    if startY == endY then
        -- 同一行
        local line = self.lines[startY]
        selectedText = string.sub(line, utf8.offset(line, startX), utf8.offset(line, endX) - 1)
    else
        -- 多行选择
        local firstLine = self.lines[startY]
        selectedText = string.sub(firstLine, utf8.offset(firstLine, startX)) .. "\n"

        for i = startY + 1, endY - 1 do
            selectedText = selectedText .. self.lines[i] .. "\n"
        end

        local lastLine = self.lines[endY]
        selectedText = selectedText .. string.sub(lastLine, 1, utf8.offset(lastLine, endX) - 1)
    end

    return selectedText
end

-- 删除选择的文本
function edit_text:deleteSelection()
    if not self:hasSelection() then return false end

    local startX, startY, endX, endY = self:getNormalizedSelection()

    if startY == endY then
        -- 同一行删除
        local line         = self.lines[startY]
        local startByte    = utf8.offset(line, startX)
        local endByte      = utf8.offset(line, endX)
        self.lines[startY] = string.sub(line, 1, startByte - 1) .. string.sub(line, endByte)
        self.cursorX       = startX
        self.cursorY       = startY
    else
        -- 跨行删除
        local firstLine = self.lines[startY]
        local lastLine = self.lines[endY]

        -- 合并首尾行
        local startByte = utf8.offset(firstLine, startX)
        local endByte = utf8.offset(lastLine, endX)
        local mergedLine = string.sub(firstLine, 1, startByte - 1) .. string.sub(lastLine, endByte)

        -- 移除中间的行
        for i = endY, startY + 1, -1 do
            table.remove(self.lines, i)
        end

        self.lines[startY] = mergedLine
        self.cursorX       = startX
        self.cursorY       = startY
    end

    -- 清除选择状态
    self:clearSelection()
    --调用改变回调
    self:on_change_text(self:getText())
    return true
end

-- 清除选择状态
function edit_text:clearSelection()
    self.selectStartX = nil
    self.selectStartY = nil
    self.selectEndX   = nil
    self.selectEndY   = nil
end

-- 插入文本
function edit_text:insertText(text)
    -- 如果有选择则先删除
    if self:deleteSelection() then
        -- 已经删除了选择的内容
    end

    -- 处理换行符
    local linesToInsert = {}
    for line in string.gmatch(text, "([^\r\n]*)[\r\n]?") do
        if line ~= nil then
            table.insert(linesToInsert, line)
        end
    end

    -- 如果只有一行，简单插入
    --if #linesToInsert == 1 then
    print(111)
    local line               = self.lines[self.cursorY]
    local cursorByte         = utf8.offset(line, self.cursorX) or (#line + 1)
    self.lines[self.cursorY] = string.sub(line, 1, cursorByte - 1) ..
        linesToInsert[1] .. string.sub(line, cursorByte)
    self.cursorX             = self.cursorX + utf8.len(linesToInsert[1] or "")
    -- end
    --[[
    else
        -- 多行插入
        local currentLine        = self.lines[self.cursorY]
        local cursorByte         = utf8.offset(currentLine, self.cursorX) or (#currentLine + 1)
        local beforeCursor       = string.sub(currentLine, 1, cursorByte - 1)
        local afterCursor        = string.sub(currentLine, cursorByte)

        -- 更新当前行
        self.lines[self.cursorY] = beforeCursor .. linesToInsert[1]

        -- 插入新行
        for i = 2, #linesToInsert do
            table.insert(self.lines, self.cursorY + i - 1, linesToInsert[i])
        end

        -- 更新最后一行
        local lastInsertedLineIndex       = self.cursorY + #linesToInsert - 1
        self.lines[lastInsertedLineIndex] = self.lines[lastInsertedLineIndex] .. afterCursor

        -- 更新光标位置
        self.cursorY                      = lastInsertedLineIndex
        self.cursorX                      = utf8.len(linesToInsert[#linesToInsert] or "") + 1
    end
]]

    --滚动到光标
    -- self:scrollToCursor()
    --调用改变回调
    self:on_change_text(self:getText())
end

-- 删除字符
function edit_text:deleteChar(direction)
    -- 如果有选择则删除选择内容
    if self:hasSelection() then
        self:deleteSelection()
        return
    end

    local line = self.lines[self.cursorY]
    local lineLength = self:getLineCharCount(self.cursorY)

    if direction == "left" then
        -- 向左删除
        if self.cursorX > 1 then
            -- 同行删除
            local prevCharByte       = utf8.offset(line, self.cursorX - 1)
            local currentCharByte    = utf8.offset(line, self.cursorX)
            self.lines[self.cursorY] = string.sub(line, 1, prevCharByte - 1) .. string.sub(line, currentCharByte)
            self.cursorX             = self.cursorX - 1
        elseif self.cursorY > 1 then
            -- 合并到上一行
            local prevLine = self.lines[self.cursorY - 1]
            local prevLineLength = self:getLineCharCount(self.cursorY - 1)
            self.lines[self.cursorY - 1] = prevLine .. line
            table.remove(self.lines, self.cursorY)
            self.cursorY = self.cursorY - 1
            self.cursorX = prevLineLength + 1
        end
    elseif direction == "right" then
        -- 向右删除
        if self.cursorX <= lineLength then
            -- 同行删除
            local currentCharByte    = utf8.offset(line, self.cursorX)
            local nextCharByte       = utf8.offset(line, self.cursorX + 1)
            self.lines[self.cursorY] = string.sub(line, 1, currentCharByte - 1) .. string.sub(line, nextCharByte)
        elseif self.cursorY < #self.lines then
            -- 合并下一行
            local nextLine           = self.lines[self.cursorY + 1]
            self.lines[self.cursorY] = line .. nextLine
            table.remove(self.lines, self.cursorY + 1)
        end
    end

    self:scrollToCursor()
    --调用改变回调
    self:on_change_text(self:getText())
end

-- 移动光标
function edit_text:moveCursor(direction, select)
    local oldX, oldY = self.cursorX, self.cursorY

    if select and not self:hasSelection() then
        self.selectStartX = self.cursorX
        self.selectStartY = self.cursorY
    end

    if direction == "left" then
        if self.cursorX > 1 then
            self.cursorX = self.cursorX - 1
        elseif self.cursorY > 1 then
            self.cursorY = self.cursorY - 1
            self.cursorX = self:getLineCharCount(self.cursorY) + 1
        end
    elseif direction == "right" then
        local lineLength = self:getLineCharCount(self.cursorY)
        if self.cursorX <= lineLength then
            self.cursorX = self.cursorX + 1
        elseif self.cursorY < #self.lines then
            self.cursorY = self.cursorY + 1
            self.cursorX = 1
        end
    elseif direction == "up" then
        if self.cursorY > 1 then
            self.cursorY     = self.cursorY - 1
            local lineLength = self:getLineCharCount(self.cursorY)
            self.cursorX     = math.min(self.cursorX, lineLength + 1)
        end
    elseif direction == "down" then
        if self.cursorY < #self.lines then
            self.cursorY     = self.cursorY + 1
            local lineLength = self:getLineCharCount(self.cursorY)
            self.cursorX     = math.min(self.cursorX, lineLength + 1)
        end
    elseif direction == "home" then
        self.cursorX = 1
    elseif direction == "end" then
        self.cursorX = self:getLineCharCount(self.cursorY) + 1
    end

    if select then
        self.selectEndX = self.cursorX
        self.selectEndY = self.cursorY
    elseif self:hasSelection() then
        self:clearSelection()
    end

    self:scrollToCursor()
end

-- 滚动到光标位置
function edit_text:scrollToCursor()
    local cursorPixelX = self:getTextPositionInPixels(self.lines[self.cursorY], self.cursorX)
    local cursorScreenX = cursorPixelX
    --print(cursorPixelX)
    if self.showLineNumbers then
        cursorScreenX = cursorScreenX + self.lineNumberWidth
    end

    local cursorY = (self.cursorY - 1) * self.lineHeight

    -- 水平滚动
    if cursorScreenX - self.scrollX < 0 then
        self.scrollX = cursorScreenX
    elseif cursorScreenX - self.scrollX > self.width - 20 then
        self.scrollX = cursorScreenX - self.width + 20
    end

    -- 垂直滚动
    if cursorY - self.scrollY < 0 then
        self.scrollY = cursorY
    elseif cursorY - self.scrollY > self.height - self.lineHeight then
        self.scrollY = cursorY - self.height + self.lineHeight
    end

    -- 确保滚动不会超出边界
    self.scrollX = math.max(0, self.scrollX)
    self.scrollY = math.max(0, self.scrollY)
end

-- 插入新行（带自动缩进）
function edit_text:insertNewLine()
    -- 如果有选择则先删除
    if self:deleteSelection() then
        -- 已经删除了选择的内容
    end

    local currentLine = self.lines[self.cursorY]
    local beforeCursor = string.sub(currentLine, 1, utf8.offset(currentLine, self.cursorX) - 1)
    local afterCursor = string.sub(currentLine, utf8.offset(currentLine, self.cursorX))

    -- 设置新行的缩进
    local indent = ""
    if self.autoIndent then
        -- 计算当前行的前导空格数
        local leadingSpaces = string.match(beforeCursor, "^%s*")
        indent = leadingSpaces or ""

        -- 如果光标前有{符号，增加缩进
        if string.find(beforeCursor, "{%s*$") then
            indent = indent .. "    "
        end
    end

    -- 更新当前行
    self.lines[self.cursorY] = beforeCursor

    -- 插入新行
    table.insert(self.lines, self.cursorY + 1, indent .. afterCursor)

    -- 更新光标位置
    self.cursorY = self.cursorY + 1
    self.cursorX = utf8.len(indent) + 1

    self:clearSelection()
    self:scrollToCursor()
    --调用改变回调
    self:on_change_text(self:getText())
end

-- 全选
function edit_text:selectAll()
    self.selectStartX = 1
    self.selectStartY = 1
    self.selectEndX   = self:getLineCharCount(#self.lines) + 1
    self.selectEndY   = #self.lines
    -- 将光标移到末尾
    self.cursorX      = self.selectEndX
    self.cursorY      = self.selectEndY
end

-- 复制
function edit_text:copy()
    local selectedText = self:getSelectedText()
    if selectedText ~= "" then
        love.system.setClipboardText(selectedText)
    end
end

-- 剪切
function edit_text:cut()
    local selectedText = self:getSelectedText()
    if selectedText ~= "" then
        love.system.setClipboardText(selectedText)
        self:deleteSelection()
    end
end

-- 粘贴
function edit_text:paste()
    local clipboardText = love.system.getClipboardText()
    if clipboardText then
        self:insertText(clipboardText)
    end
end

-- 处理按键输入
function edit_text:keypressed(key)
    --处理切换优先级
    if key == "q" then
        print("偏移", self.scrollX)
    end
    if key == "f1" then
        --自动换行
        self:toggleAutoWrap()
        return
    elseif key == "f2" then
        --行号显示
        self:toggleLineNumbers()
        return
    end
    -- 处理组合键
    local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")

    if ctrl then
        if key == "a" then
            -- 全选
            self:selectAll()
        elseif key == "c" then
            -- 复制
            self:copy()
        elseif key == "v" then
            -- 粘贴
            self:paste()
        elseif key == "x" then
            -- 剪切
            self:cut()
        elseif key == "z" then
            -- 撤销（简化实现）
        elseif key == "y" then
            -- 重做（简化实现）
        end
        return
    end

    if key == "left" then
        self:moveCursor("left", shift)
    elseif key == "right" then
        self:moveCursor("right", shift)
    elseif key == "up" then
        self:moveCursor("up", shift)
    elseif key == "down" then
        self:moveCursor("down", shift)
    elseif key == "home" then
        self:moveCursor("home", shift)
    elseif key == "end" then
        self:moveCursor("end", shift)
    elseif key == "backspace" then
        self:deleteChar("left")
    elseif key == "delete" then
        self:deleteChar("right")
    elseif key == "return" or key == "kpenter" then
        self:insertNewLine()
    elseif key == "tab" then
        self:insertText("    ") -- 插入4个空格作为制表符
    end
end

-- 处理文本输入
function edit_text:textinput(text)
    self:insertText(text)
end

-- 处理鼠标按下
function edit_text:mousepressed(id, x, y, dx, dy, istouch, pre)
    if id == 1 then -- 左键
        local x1, y1       = self:get_local_Position(x, y)
        local textX, textY = self:screenToTextCoord(x1, y1)
        -- print(textX, textY)
        self.cursorX       = textX
        self.cursorY       = textY

        -- 处理Shift键的连续选择
        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
            if not self:hasSelection() then
                self.selectStartX = self.cursorX
                self.selectStartY = self.cursorY
            end
            self.selectEndX = self.cursorX
            self.selectEndY = self.cursorY
        else
            self.selectStartX = self.cursorX
            self.selectStartY = self.cursorY
            self.selectEndX   = self.cursorX
            self.selectEndY   = self.cursorY
        end
        --计算鼠标位置
        self:scrollToCursor()
    end
end

-- 处理鼠标释放
function edit_text:mousereleased(id, x, y, dx, dy, istouch, pre)
    if id == 1 then
        -- 如果起始和结束位置相同，则清除选择
        if self.selectStartX == self.selectEndX and self.selectStartY == self.selectEndY then
            self:clearSelection()
        end
    end
end

-- 处理鼠标移动
function edit_text:mousemoved(id, x, y, dx, dy, istouch, pre)
    if self.isDragging then --拖动
        local x1, y1       = self:get_local_Position(x, y)
        local textX, textY = self:screenToTextCoord(x1, y1)
        self.cursorX       = textX
        self.cursorY       = textY
        self.selectEndX    = self.cursorX
        self.selectEndY    = self.cursorY
        self:scrollToCursor()
        --检查是否选中文本
        if self:hasSelection() then
            --调用选中文本回调
            self:select_text(select_text)
        end
    end
end

-- 处理滚轮
function edit_text:wheelmoved(id, x, y)
    if love.keyboard.isDown("lalt") then
        self.scrollX = math.max(0, self.scrollX - y * 10)
        return
    end

    local font = self:get_font(self.font, self.textSize)
    local conH = #self.lines * font:getHeight()
    self.scrollY = math.min(math.max(0, self.scrollY - y * 20), conH)
    --alt加滚轮则横向滚动
end

-- 切换自动换行
function edit_text:toggleAutoWrap()
    self.autoWrap = not self.autoWrap
end

-- 切换行号显示
function edit_text:toggleLineNumbers()
    self.showLineNumbers = not self.showLineNumbers
end

-- 获取完整文本
function edit_text:getText()
    return table.concat(self.lines, "\n")
end

-- 设置文本
function edit_text:setText(text)
    self.lines = {}
    if text == "" then
        self.lines = { "" }
    else
        for line in string.gmatch(text, "([^\r\n]*)[\r\n]?") do
            table.insert(self.lines, line or "")
        end
    end
    self.cursorX = 1
    self.cursorY = 1
    self:clearSelection()
    self.scrollX = 0
    self.scrollY = 0
    self:on_change_text(self:getText())
end

--循环
function edit_text:update(dt)
    -- body
    self.cursorBlinkTime = self.cursorBlinkTime + dt --更新光标闪烁计时器
    self.dragTimer = self.dragTimer + dt             --拖拽时间
end

--
-- 主程序初始化
function edit_text.load()
    -- 示例文本
    local sampleText = [[这是一个支持中文的文本编辑器示例。
它具有以下功能：
1. 支持中文字符显示和输入
2. 鼠标点击定位和拖拽选择
3. 增删改文本操作
4. 自动缩进功能
5. 可切换的自动换行
6. 可切换的行号显示
7. 正确处理UTF-8字符

你可以尝试：
- 输入中英文混合文本
- 使用鼠标选择文本
- 使用Ctrl+C/V/X进行复制粘贴剪切
- 使用方向键、Home、End键导航
- 按Tab键插入缩进
- 按F1切换自动换行
- 按F2切换行号显示
- left alt +鼠标滚轮 横向滚动
]]

    editor:setText(sampleText)
end

--[[
-- 绘制函数
function love.draw()
    editor:draw()

    -- 绘制状态信息
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print(string.format(" 行:%d/%d 列:%d 自动换行:%s 行号:%s",
            editor.cursorY, #editor.lines, editor.cursorX,
            editor.autoWrap and "开" or "关",
            editor.showLineNumbers and "开" or "关"),
        10, editor.height - 30)
end
]]


--当文本被改变时
function edit_text:on_change_text(text)

end

--当选中文本时
function edit_text:select_text(select_text)
    -- body
end

return edit_text
