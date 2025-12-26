local function import(moduleName)
    -- 获取调用者的文件路径（如：/project/src/main.lua ）
    local callerPath = debug.getinfo(1, "S").source:sub(2)
    local callerDir  = callerPath:match("(.*[/\\])") or "./"

    -- 添加同级目录到Lua模块搜索路径
    package.path     = callerDir .. "?.lua;" .. package.path

    -- 动态加载模块
    return require(moduleName)
end

return import
