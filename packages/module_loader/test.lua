-- 使用示例

-- 假设你的模块保存在 my_module.lua
-- 内容如下:
--[[
local mod = {};
local value1 = 1
mod.new = 123
function mod:fun1(value1, value2)
    -- 内容
    return value1 + value2
end
mod.fun2 = function(value1, value2)
    -- 内容
    return value1 * value2
end
return mod
]]
--

local module_loader = require("module_loader")

-- 加载模块
local mod = module_loader.load_with_metadata_v2("mod.lua")

-- 查看所有函数定义
print("=== 所有函数定义 ===")
for func_name, func_info in pairs(mod.__fun) do
    print("\n函数名: " .. func_name)
    print("源定义:")
    print(func_info.original)
    print("\n解析定义:")
    print(func_info.parsed)
    print("---")
end

-- 查看特定函数
print("\n=== 查看 fun1 ===")
module_loader.print_function_info(mod, "fun1")

print("\n=== 查看 fun2 ===")
module_loader.print_function_info(mod, "fun2")

-- 访问 __fun 属性
print("\n=== 直接访问 __fun ===")
print("fun1 的原始定义:")
print(mod.__fun.fun1.original)
print("\nfun1 的解析定义:")
print(mod.__fun.fun1.parsed)
