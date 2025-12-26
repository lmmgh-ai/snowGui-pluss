local module_loader = {}

-- 解析函数定义的工具函数
local function parse_function_definitions(source_code, mod_name)
    local function_defs = {}

    -- 匹配两种函数定义模式
    -- 模式1: function mod:fun_name(params)
    for func_def in source_code:gmatch("(function%s+" .. mod_name .. "%s*:%s*([%w_]+)%s*%(.-%).-end)") do
        local func_name = func_def:match("function%s+" .. mod_name .. "%s*:%s*([%w_]+)")
        if func_name then
            -- 提取原始定义
            local full_match = func_def

            -- 提取参数列表
            local params = full_match:match("%((.-)%)")

            -- 提取函数体
            local body_start = full_match:find("%)") + 1
            local body = full_match:sub(body_start, -4) -- 去掉最后的 "end"

            -- 构造解析后的函数定义（添加 self 参数）
            local parsed_def
            if params and params:match("%S") then
                parsed_def = "function(self, " .. params .. ")" .. body .. "end"
            else
                parsed_def = "function(self)" .. body .. "end"
            end

            function_defs[func_name] = {
                name = func_name,
                original = full_match,
                parsed = parsed_def
            }
        end
    end

    -- 模式2: mod.fun_name = function(params)
    for func_name, func_def in source_code:gmatch(mod_name .. "%.([%w_]+)%s*=%s*(function%s*%(.-%).-end)") do
        -- 这种定义方式不需要自动添加 self
        function_defs[func_name] = {
            name = func_name,
            original = mod_name .. "." .. func_name .. " = " .. func_def,
            parsed = func_def
        }
    end

    return function_defs
end

-- 加载模块并添加 __fun 属性
function module_loader.load_with_metadata(file_path)
    -- 读取源文件
    local file = io.open(file_path, "r")
    if not file then
        error("无法打开文件: " .. file_path)
    end
    local source_code = file:read("*all")
    file:close()

    -- 加载模块
    local mod = dofile(file_path)

    -- 尝试检测模块名称
    local mod_name = source_code:match("local%s+([%w_]+)%s*=%s*{}")
    if not mod_name then
        mod_name = "mod" -- 默认名称
    end

    -- 解析函数定义
    local function_defs = parse_function_definitions(source_code, mod_name)

    -- 添加 __fun 属性
    mod.__fun = function_defs

    return mod
end

-- 更精确的解析版本
function module_loader.load_with_metadata_v2(file_path)
    local file = io.open(file_path, "r")
    if not file then
        error("无法打开文件: " .. file_path)
    end
    local source_code = file:read("*all")
    file:close()

    -- 加载模块
    local mod = dofile(file_path)

    -- 检测模块名
    local mod_name = source_code:match("local%s+([%w_]+)%s*=%s*{}")
    if not mod_name then
        mod_name = "mod"
    end

    local function_defs = {}

    -- 更精确的函数匹配（处理嵌套）
    local function extract_function_body(code, start_pos)
        local depth = 0
        local i = start_pos
        local body_start = nil

        while i <= #code do
            local word = code:sub(i, i + 7)
            if word == "function" then
                if body_start == nil then
                    body_start = i
                end
                depth = depth + 1
                i = i + 8
            elseif code:sub(i, i + 2) == "end" then
                depth = depth - 1
                if depth == 0 then
                    return code:sub(body_start, i + 2)
                end
                i = i + 3
            else
                i = i + 1
            end
        end
        return nil
    end

    -- 解析 function mod:name() 格式
    local pos = 1
    while true do
        local pattern = "function%s+" .. mod_name .. "%s*:%s*([%w_]+)%s*%(([^)]*)%)"
        local start_idx, end_idx, func_name, params = source_code:find(pattern, pos)

        if not start_idx then break end

        local full_def = extract_function_body(source_code, start_idx)

        if full_def then
            -- 提取函数体
            local body = full_def:match("%)%s*(.-)%s*end$")

            -- 构造解析后的定义
            local parsed_def
            if params and params:match("%S") then
                parsed_def = "function(self, " .. params .. ")\n" .. (body or "") .. "\nend"
            else
                parsed_def = "function(self)\n" .. (body or "") .. "\nend"
            end

            function_defs[func_name] = {
                name = func_name,
                original = full_def,
                parsed = parsed_def
            }
        end

        pos = end_idx + 1
    end

    -- 解析 mod.name = function() 格式
    pos = 1
    while true do
        local pattern = mod_name .. "%.([%w_]+)%s*=%s*function%s*%(([^)]*)%)"
        local start_idx, end_idx, func_name, params = source_code:find(pattern, pos)

        if not start_idx then break end

        local func_start = source_code:find("function", start_idx)
        local full_def = extract_function_body(source_code, func_start)

        if full_def then
            function_defs[func_name] = {
                name = func_name,
                original = mod_name .. "." .. func_name .. " = " .. full_def,
                parsed = full_def
            }
        end

        pos = end_idx + 1
    end

    mod.__fun = function_defs

    return mod
end

-- 辅助函数：打印函数定义信息
function module_loader.print_function_info(mod, func_name)
    if not mod.__fun then
        print("模块没有 __fun 属性")
        return
    end

    local func_info = mod.__fun[func_name]
    if not func_info then
        print("未找到函数: " .. func_name)
        return
    end

    print("函数名: " .. func_info.name)
    print("\n源函数定义:")
    print(func_info.original)
    print("\n解析的函数完整定义:")
    print(func_info.parsed)
end

return module_loader
