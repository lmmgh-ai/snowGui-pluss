--获取包的路径
lumenGui_path = ...

--local Slab = require(lumenGui_path .. '.API')

local lumenGui = require(lumenGui_path .. ".gui")
local API = require(lumenGui_path .. ".API")
API.__index = API

return setmetatable({
    new = function() return lumenGui:new() end,
    lumenGui = lumenGui,

}, API)
