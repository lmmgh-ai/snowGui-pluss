-- 事件总线模块
local events_system = {
    -- 存储所有事件订阅者
    _subscribers = {},
    -- 存储一次性订阅者标记
    _onceFlags = {},
    -- 存储事件统计信息
    _stats = {
        totalEvents = 0,
        activeSubscriptions = 0
    }
}
--创建新对象
function events_system:new()
    self.__index = self
    local obj = {
        -- 存储所有事件订阅者
        _subscribers = {},
        -- 存储一次性订阅者标记
        _onceFlags = {},
        -- 存储事件统计信息
        _stats = {
            totalEvents = 0,
            activeSubscriptions = 0
        }
    }
    return setmetatable(obj, self)
end

-- 生成唯一ID
local function generateId()
    return tostring({}):sub(8) -- 使用表地址作为唯一ID
end

--[[
    订阅事件
    @param eventName 事件名称
    @param callback 回调函数
    @param isOnce 是否一次性订阅，默认为false
    @return 订阅ID，可用于取消订阅
]]
function events_system:subscribe(eventName, callback, isOnce, subscriber)
    if type(eventName) ~= "string" or type(callback) ~= "function" then
        error("参数错误: eventName必须是字符串, callback必须是函数")
    end

    -- 初始化事件订阅者列表
    if not self._subscribers[eventName] then
        self._subscribers[eventName] = setmetatable({}, { __mode = "k" })
    end

    -- 生成唯一ID
    --local subId = generateId()
    local subId = subscriber or generateId()
    -- 存储订阅信息
    self._subscribers[eventName][subId] = callback

    -- 如果是一次性订阅，记录标记
    if isOnce then
        if not self._onceFlags[eventName] then
            self._onceFlags[eventName] = {}
        end
        self._onceFlags[eventName][subId] = true
    end

    -- 更新统计
    self._stats.activeSubscriptions = self._stats.activeSubscriptions + 1

    return subId
end

--[[
    持续订阅事件
    @param eventName 事件名称
    @param callback 回调函数
    @return 订阅ID，可用于取消订阅
]]
function events_system:on(eventName, callback, subscriber)
    return self:subscribe(eventName, callback, false, subscriber)
end

--[[
    一次性订阅事件
    @param eventName 事件名称
    @param callback 回调函数
    @return 订阅ID，可用于取消订阅
]]
function events_system:once(eventName, callback, subscriber)
    return self:subscribe(eventName, callback, true, subscriber)
end

--[[
    发布事件
    @param eventName 事件名称
    @param ... 传递给监听器的参数
]]
function events_system:publish(eventName, ...)
    if not self._subscribers[eventName] then
        return -- 没有订阅者，直接返回
    end

    -- 更新统计
    self._stats.totalEvents = self._stats.totalEvents + 1

    -- 复制当前订阅者列表，防止在遍历过程中修改
    local subscribers       = {}
    for id, callback in pairs(self._subscribers[eventName]) do
        subscribers[id] = callback
    end

    -- 遍历所有订阅者
    for id, callback in pairs(subscribers) do
        -- 使用pcall包裹执行，防止单个监听器出错影响其他监听器
        local success, err = pcall(callback, ...)
        if not success then
            print(string.format(" 事件监听器执行错误: %s, 错误: %s", eventName, err))
        end

        -- 如果是一次性订阅，执行后立即取消
        if self._onceFlags[eventName] and self._onceFlags[eventName][id] then
            self:unsubscribeById(eventName, id)
        end
    end
    --[[
    -- 自动清理没有订阅者的事件类型
    if not next(self._subscribers[eventName]) then
        self._subscribers[eventName] = nil
        self._onceFlags[eventName] = nil
    end
    ]]
end

--[[
    通过订阅ID取消订阅
    @param eventName 事件名称
    @param subId 订阅ID
]]
function events_system:unsubscribeById(eventName, subId)
    if not self._subscribers[eventName] then
        return
    end

    if self._subscribers[eventName][subId] then
        self._subscribers[eventName][subId] = nil
        self._stats.activeSubscriptions     = self._stats.activeSubscriptions - 1
    end

    if self._onceFlags[eventName] and self._onceFlags[eventName][subId] then
        self._onceFlags[eventName][subId] = nil
    end

    -- 自动清理没有订阅者的事件类型
    if not next(self._subscribers[eventName]) then
        self._subscribers[eventName] = nil
        self._onceFlags[eventName] = nil
    end
end

--[[
    通过事件名称取消所有订阅
    @param eventName 事件名称
]]
function events_system:unsubscribeAll(eventName)
    if not self._subscribers[eventName] then
        return
    end

    -- 更新统计
    local count = 0
    for _ in pairs(self._subscribers[eventName]) do
        count = count + 1
    end
    self._stats.activeSubscriptions = self._stats.activeSubscriptions - count

    self._subscribers[eventName]    = nil
    self._onceFlags[eventName]      = nil
end

--[[
    获取统计信息
    @return 包含统计信息的表
]]
function events_system:getStats()
    -- 计算活跃事件类型数量
    local eventTypes = 0
    for _ in pairs(self._subscribers) do
        eventTypes = eventTypes + 1
    end

    return {
        totalEvents = self._stats.totalEvents,
        activeSubscriptions = self._stats.activeSubscriptions,
        activeEventTypes = eventTypes
    }
end

--[[
    清除所有订阅
]]
function events_system:clearAll()
    self._subscribers = {}
    self._onceFlags = {}
    self._stats = {
        totalEvents = self._stats.totalEvents, -- 保留总事件计数
        activeSubscriptions = 0,
        activeEventTypes = 0
    }
end

-- 返回模块
return events_system
--[[

-- 初始化事件总线
local EventBus = require("EventSystem")

-- 订阅事件
local subId1 = EventBus:on("playerMove", function(x, y)
    print("玩家移动到了1:", x, y)
end)
local subId = EventBus:on("playerMove", function(x, y)
    print("玩家移动到了2:", x, y)
end)
-- 一次性订阅
EventBus:once("levelUp", function(level)
    print("恭喜升级到:", level)
end)

-- 发布事件
EventBus:publish("playerMove", 100, 200) -- 会触发回调
EventBus:publish("levelUp", 5)           -- 会触发回调
EventBus:publish("levelUp", 6)           -- 不会触发回调，因为是一次性订阅

-- 取消订阅
EventBus:unsubscribeById("playerMove", subId1)

-- 获取统计信息
local stats = EventBus:getStats()
print("活跃订阅数:", stats.activeSubscriptions)

-- 清除所有订阅
EventBus:clearAll()

]]

--[[

设计说明
性能优化：
使用表存储订阅者，查找和删除操作都是O(1)复杂度
每个事件类型独立存储，发布事件时只遍历相关监听器
使用唯一ID标识监听器，取消订阅效率高
高级功能：
错误处理：每个监听器的执行都使用pcall包裹
内存管理：自动清理没有订阅者的事件类型
统计功能：可以通过getStats获取当前订阅情况
全局清理：使用clearAll可以一次性清除所有订阅
接口设计：
on: 持续订阅
once: 一次性订阅
publish: 发布事件
unsubscribeById: 通过ID取消订阅
unsubscribeAll: 取消某事件的所有订阅
getStats: 获取统计信息
clearAll: 清除所有订阅
这个实现完全符合你的要求，并且具有良好的性能和可靠性。

]]
