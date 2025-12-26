--[[
    输入验证和错误处理工具
    提供输入验证、类型检查、错误提示等功能
    作者: 北极企鹅 & AI优化
    时间: 2025
]]

local validator = {}

-- ============================================
-- 类型检查工具
-- ============================================

-- 检查是否为数字
function validator.isNumber(value)
    return type(value) == "number" and value == value  -- 排除 NaN
end

-- 检查是否为字符串
function validator.isString(value)
    return type(value) == "string"
end

-- 检查是否为布尔值
function validator.isBoolean(value)
    return type(value) == "boolean"
end

-- 检查是否为表
function validator.isTable(value)
    return type(value) == "table"
end

-- 检查是否为函数
function validator.isFunction(value)
    return type(value) == "function"
end

-- 检查是否为有效的颜色数组
function validator.isColor(value)
    if not validator.isTable(value) then
        return false
    end
    
    -- 至少需要RGB三个值
    if #value < 3 then
        return false
    end
    
    -- 检查每个值是否在 0-1 范围内
    for i = 1, math.min(4, #value) do
        if not validator.isNumber(value[i]) or value[i] < 0 or value[i] > 1 then
            return false
        end
    end
    
    return true
end

-- 检查是否为有效的位置坐标
function validator.isPosition(x, y)
    return validator.isNumber(x) and validator.isNumber(y)
end

-- 检查是否为有效的尺寸
function validator.isSize(width, height)
    return validator.isNumber(width) and validator.isNumber(height) and
           width >= 0 and height >= 0
end

-- ============================================
-- 范围验证
-- ============================================

-- 检查数字是否在范围内
function validator.inRange(value, min, max)
    if not validator.isNumber(value) then
        return false
    end
    return value >= min and value <= max
end

-- 检查值是否为正数
function validator.isPositive(value)
    return validator.isNumber(value) and value > 0
end

-- 检查值是否为非负数
function validator.isNonNegative(value)
    return validator.isNumber(value) and value >= 0
end

-- ============================================
-- 字符串验证
-- ============================================

-- 检查字符串是否非空
function validator.isNonEmptyString(value)
    return validator.isString(value) and #value > 0
end

-- 检查字符串长度是否在范围内
function validator.stringLength(value, min, max)
    if not validator.isString(value) then
        return false
    end
    return #value >= (min or 0) and #value <= (max or math.huge)
end

-- ============================================
-- 视图属性验证
-- ============================================

-- 验证视图基础属性
function validator.validateViewProperties(view, required)
    local errors = {}
    
    required = required or {}
    
    -- 位置验证
    if view.x ~= nil and not validator.isNumber(view.x) then
        table.insert(errors, "x 必须是数字")
    end
    if view.y ~= nil and not validator.isNumber(view.y) then
        table.insert(errors, "y 必须是数字")
    end
    
    -- 尺寸验证
    if view.width ~= nil and not (validator.isNumber(view.width) or validator.isString(view.width)) then
        table.insert(errors, "width 必须是数字或字符串")
    end
    if view.height ~= nil and not (validator.isNumber(view.height) or validator.isString(view.height)) then
        table.insert(errors, "height 必须是数字或字符串")
    end
    
    -- 颜色验证
    if view.backgroundColor and not validator.isColor(view.backgroundColor) then
        table.insert(errors, "backgroundColor 必须是有效的颜色数组 {r,g,b,a}")
    end
    if view.borderColor and not validator.isColor(view.borderColor) then
        table.insert(errors, "borderColor 必须是有效的颜色数组 {r,g,b,a}")
    end
    if view.textColor and not validator.isColor(view.textColor) then
        table.insert(errors, "textColor 必须是有效的颜色数组 {r,g,b,a}")
    end
    
    -- 检查必需属性
    for _, prop in ipairs(required) do
        if view[prop] == nil then
            table.insert(errors, string.format("缺少必需属性: %s", prop))
        end
    end
    
    return #errors == 0, errors
end

-- 验证进度条属性
function validator.validateProgressBar(options)
    local errors = {}
    
    if options.min and not validator.isNumber(options.min) then
        table.insert(errors, "min 必须是数字")
    end
    if options.max and not validator.isNumber(options.max) then
        table.insert(errors, "max 必须是数字")
    end
    if options.value and not validator.isNumber(options.value) then
        table.insert(errors, "value 必须是数字")
    end
    
    -- 范围验证
    if options.min and options.max and options.min >= options.max then
        table.insert(errors, "min 必须小于 max")
    end
    if options.value and options.min and options.value < options.min then
        table.insert(errors, "value 不能小于 min")
    end
    if options.value and options.max and options.value > options.max then
        table.insert(errors, "value 不能大于 max")
    end
    
    return #errors == 0, errors
end

-- 验证滑块属性
function validator.validateSlider(options)
    return validator.validateProgressBar(options)
end

-- ============================================
-- 错误处理
-- ============================================

-- 错误级别
validator.ErrorLevel = {
    WARNING = "WARNING",
    ERROR = "ERROR",
    FATAL = "FATAL"
}

-- 错误记录器
validator.errorLog = {
    enabled = true,
    maxEntries = 100,
    entries = {}
}

-- 记录错误
function validator.errorLog:add(level, message, context)
    if not self.enabled then
        return
    end
    
    local entry = {
        level = level,
        message = message,
        context = context,
        timestamp = os.time(),
        trace = debug.traceback("", 2)
    }
    
    table.insert(self.entries, entry)
    
    -- 限制日志大小
    if #self.entries > self.maxEntries then
        table.remove(self.entries, 1)
    end
    
    -- 打印到控制台
    local prefix = string.format("[%s]", level)
    if context then
        print(prefix, message, "Context:", context)
    else
        print(prefix, message)
    end
    
    -- 致命错误抛出异常
    if level == validator.ErrorLevel.FATAL then
        error(message, 2)
    end
end

-- 警告
function validator.warn(message, context)
    validator.errorLog:add(validator.ErrorLevel.WARNING, message, context)
end

-- 错误
function validator.error(message, context)
    validator.errorLog:add(validator.ErrorLevel.ERROR, message, context)
end

-- 致命错误
function validator.fatal(message, context)
    validator.errorLog:add(validator.ErrorLevel.FATAL, message, context)
end

-- 获取错误日志
function validator.errorLog:getEntries(level)
    if not level then
        return self.entries
    end
    
    local filtered = {}
    for _, entry in ipairs(self.entries) do
        if entry.level == level then
            table.insert(filtered, entry)
        end
    end
    return filtered
end

-- 清空错误日志
function validator.errorLog:clear()
    self.entries = {}
end

-- ============================================
-- 断言工具
-- ============================================

-- 断言为真
function validator.assert(condition, message, level)
    if not condition then
        level = level or validator.ErrorLevel.ERROR
        validator.errorLog:add(level, message or "Assertion failed")
        return false
    end
    return true
end

-- 断言类型
function validator.assertType(value, expectedType, name, level)
    local actualType = type(value)
    if actualType ~= expectedType then
        local message = string.format(
            "%s 类型错误: 期望 %s, 实际 %s",
            name or "参数",
            expectedType,
            actualType
        )
        validator.errorLog:add(level or validator.ErrorLevel.ERROR, message)
        return false
    end
    return true
end

-- 断言范围
function validator.assertRange(value, min, max, name, level)
    if not validator.inRange(value, min, max) then
        local message = string.format(
            "%s 超出范围: 期望 [%s, %s], 实际 %s",
            name or "参数",
            tostring(min),
            tostring(max),
            tostring(value)
        )
        validator.errorLog:add(level or validator.ErrorLevel.ERROR, message)
        return false
    end
    return true
end

-- 断言非空
function validator.assertNotNil(value, name, level)
    if value == nil then
        local message = string.format("%s 不能为 nil", name or "参数")
        validator.errorLog:add(level or validator.ErrorLevel.ERROR, message)
        return false
    end
    return true
end

-- ============================================
-- 安全调用包装器
-- ============================================

-- 安全调用函数，捕获错误
function validator.safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        validator.error("函数调用失败: " .. tostring(result))
        return nil, result
    end
    return result
end

-- 安全获取表值
function validator.safeGet(table, key, default)
    if not validator.isTable(table) then
        validator.warn("safeGet: table 参数不是表类型")
        return default
    end
    
    local value = table[key]
    return value ~= nil and value or default
end

-- 安全设置表值（带类型检查）
function validator.safeSet(table, key, value, expectedType)
    if not validator.isTable(table) then
        validator.error("safeSet: table 参数不是表类型")
        return false
    end
    
    if expectedType and type(value) ~= expectedType then
        validator.error(string.format(
            "safeSet: 类型错误, 期望 %s, 实际 %s",
            expectedType,
            type(value)
        ))
        return false
    end
    
    table[key] = value
    return true
end

-- ============================================
-- 调试工具
-- ============================================

-- 打印错误统计
function validator.printErrorStats()
    local stats = {
        WARNING = 0,
        ERROR = 0,
        FATAL = 0
    }
    
    for _, entry in ipairs(validator.errorLog.entries) do
        stats[entry.level] = stats[entry.level] + 1
    end
    
    print("=== 错误统计 ===")
    print(string.format("警告: %d", stats.WARNING))
    print(string.format("错误: %d", stats.ERROR))
    print(string.format("致命: %d", stats.FATAL))
    print(string.format("总计: %d", #validator.errorLog.entries))
    print("================")
end

return validator
