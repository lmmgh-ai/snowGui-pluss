-- SceneManager.lua  - 场景管理器

local SceneManager        = {}
SceneManager.__index      = SceneManager

-- 全局共享变量表
SceneManager.sharedData   = {}

-- 场景栈
SceneManager.sceneStack   = {}

-- 当前活动场景
SceneManager.currentScene = nil

-- 场景缓存表
SceneManager.sceneCache   = {}

-- 场景配置
SceneManager.config       = {
    defaultLoadingTime = 0.5, -- 默认加载时间（秒）
    enableSceneCache = true   -- 是否启用场景缓存
}

-- 场景生命周期方法定义
local SCENE_LIFECYCLE     = {
    "load",          -- 初始化
    "update",        -- 更新
    "draw",          -- 绘制
    "keypressed",    -- 键盘按下
    "keyreleased",   -- 键盘释放
    "mousepressed",  -- 鼠标按下
    "mousereleased", -- 鼠标释放
    "wheelmoved",    -- 鼠标滚轮
    "textinput",     -- 文本输入
    "resize",        -- 窗口大小改变
    "focus",         -- 焦点变化
    "visible",       -- 可见性变化
    "quit"           -- 退出
}


--沙盒模式加载场景
function SceneManager:create_sandbox_scene(scenePath, params)
    --
    love.__index = love
    --初始化
    local env = {
        --场景管理相关
        -- 提供访问共享数据的方法
        sharedData = self.sharedData,
        -- 参数传递
        params = params or {},
        -- 生命周期状态
        isDestroyed = false,
        -- 沙盒场景可使用love api初始化
        love = setmetatable({}, love),
        --设置场景管理
        SceneManager = self,
    }


    -- 白名单：只允许安全的函数和模块
    local white_list = {
        -- 基础类型
        type = type,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        tonumber = tonumber,
        tostring = tostring,
        print = print,

        math = math,
        string = string,
        table = table,
        require = require,
        -- dump = dump,
        load = load,
        -- 安全模块（可选择性开放）

        --gui = require(lumenGui_path .. ".gui"):new(),
        --File = File, --文件系统


    }
    white_list.__index = white_list
    -- 设置环境
    setmetatable(env, white_list)
    -- 设置超时保护
    local code = love.filesystem.read(scenePath .. ".lua")
    --print(code)
    local co = coroutine.create(function()
        local func, err = load(code, "sandbox_code", "t", env)
        if not func then
            print("编译错误: " .. err)
            return nil, "编译错误: " .. err
        end

        -- 使用pcall保护执行
        local success, result = pcall(func)
        if success then
            return result
        else
            print("运行时错误: " .. result)
            return nil, "运行时错误: " .. result
        end
    end)
    local success, result = coroutine.resume(co)
    --print(success, result)
    if not success then
        print("执行错误: " .. result)
        return nil, "执行错误: " .. result
    end

    return {
        module = result,
        env = env,
        path = scenePath,
        cacheMode = false -- 默认不缓存
    }
end

-- 启动新的沙盒场景Activity(路径加载)
function SceneManager:start_sandbox_activity(scenePath, params, cacheMode)
    -- 如果当前有场景，先暂停它

    if self.currentScene and self.currentScene.env then
        local env = self.currentScene.env
        if env.onPause then
            env.onPause()
        end
        -- 将当前场景压入栈
        table.insert(self.sceneStack, self.currentScene)
    end

    -- 显示加载页面


    -- 检查缓存
    local sceneKey = scenePath .. (cacheMode and "_cached" or "")
    local newScene

    if cacheMode and self.config.enableSceneCache and self.sceneCache[sceneKey] then
        -- 使用缓存的场景
        newScene            = self.sceneCache[sceneKey]
        newScene.env.params = params or {}
        newScene.cacheMode  = cacheMode

        -- 调用onRestart而不是onCreate
        if newScene.module.onRestart then
            newScene.module.onRestart(newScene.env)
        end
    else
        -- 创建新沙盒场景
        newScene           = self:create_sandbox_scene(scenePath, params)
        newScene.cacheMode = cacheMode or false

        -- print(dump(newScene))
        --调用场景的load方法
        local env_love     = newScene.env.love
        if rawget(env_love, "load") then
            env_love.load(newScene.env)
        end

        -- 缓存场景（如果需要）
        if cacheMode and self.config.enableSceneCache then
            self.sceneCache[sceneKey] = newScene
        end
    end

    -- 调用onStart和onResume
    local env = newScene.env
    if env.onStart then
        env.onStart(newScene.env)
    end
    if env.onResume then
        env.onResume(newScene.env)
    end

    self.currentScene = newScene
end

-- 结束当前场景并返回结果
function SceneManager:finish(result)
    if not self.currentScene then return end
    local env = self.currentScene.env
    -- 调用onPause和onStop
    if env.onPause then
        env.onPause(self.currentScene.env)
    end
    -- 根据缓存模式决定是否调用onDestroy
    if not self.currentScene.cacheMode then
        if env.onDestroy then
            env.onDestroy(self.currentScene.env)
        end
        env.isDestroyed = true
    else
        -- 缓存模式下不销毁，只暂停
        if env.onStop then
            env.onStop(self.currentScene.env)
        end
    end

    -- 返回到上一个场景
    local previousScene = table.remove(self.sceneStack)
    if previousScene then
        self.currentScene = previousScene
        local env = previousScene.env
        -- 调用onRestart或onResume
        if env.onRestart then
            env.onRestart(previousScene.env)
        end
        if env.onResume then
            env.onResume(previousScene.env)
        end

        -- 传递返回结果
        if env.onActivityResult then
            env.onActivityResult(previousScene.env, result)
        end
    else
        -- 没有上一个场景，退出应用
        print("没有上一个场景，退出应用")
        --self:quit()
        -- love.event.quit()
    end
end

-- 初始化场景管理器
function SceneManager:init(startScene, params)
    self:startActivity(startScene, params, false)
end

--场景总管理退出回调
function SceneManager:quit()

end

-- Love2D 回调转发
function SceneManager:update(dt)
    -- 更新加载页面
    if self.loadingScene and self.loadingScene.isActive then
        if self.loadingScene.update then
            self.loadingScene.update(dt)
        end
        return
    end

    -- 更新当前场景
    local env_love = self.currentScene.env.love
    if self.currentScene and rawget(env_love, "update") then
        env_love.update(dt)
    end
end

function SceneManager:draw()
    -- 绘制当前场景
    local env_love = self.currentScene.env.love
    if self.currentScene and rawget(env_love, "draw") then
        env_love.draw()
    end
end

-- 输入事件转发
function SceneManager:keypressed(key)
    local env_love = self.currentScene.env.love
    if self.currentScene and rawget(env_love, "keypressed") then
        env_love.keypressed(key)
    end
end

function SceneManager:keyreleased(key)
    local env_love = self.currentScene.env.love
    if self.currentScene and rawget(env_love, "keyreleased") then
        env_love.keyreleased(self.currentScene.env, key, scancode)
    end
end

function SceneManager:mousepressed(x, y, id, istouch, pressure)
    --
    local env_love = self.currentScene.env.love
    if self.currentScene and rawget(env_love, "mousepressed") then
        env_love.mousepressed(x, y, id, istouch, pressure)
    end
end

function SceneManager:mousereleased(x, y, id, istouch, pressure)
    local env_love = self.currentScene.env.love
    if self.currentScene and rawget(env_love, "mousereleased") then
        env_love.mousereleased(x, y, id, istouch, pressure)
    end
end

function SceneManager:mousemoved(x, y, dx, dy, istouch) --鼠标滑动
    local env_love = self.currentScene.env.love
    if self.currentScene and rawget(env_love, "mousemoved") then
        env_love.mousemoved(x, y, dx, dy, istouch)
    end
end

function SceneManager:wheelmoved(x, y)
    local env_love = self.currentScene.env.love
    if self.currentScene and rawget(env_love, "wheelmoved") then
        env_love.wheelmoved(x, y)
    end
end

function SceneManager:textinput(text)
    local env_love = self.currentScene.env.love
    if self.currentScene and rawget(env_love, "textinput") then
        env_love.textinput(text)
    end
end

function SceneManager:resize(w, h)
    local env_love = self.currentScene.env.love
    if self.currentScene and rawget(env_love, "resize") then
        env_love.resize(self.currentScene.env, w, h)
    end
end

function SceneManager:focus(f)
    local env_love = self.currentScene.env.love
    if self.currentScene and rawget(env_love, "focus") then
        env_love.focus(f)
    end
end

function SceneManager:visible(v)
    local env_love = self.currentScene.env.love
    if self.currentScene and rawget(env_love, "visible") then
        env_love.visible(v)
    end
end

function SceneManager:quit()
    local env_love = self.currentScene.env.love
    print(love, env_love)
    if self.currentScene and rawget(env_love, "quit") then
        env_love.quit(self.currentScene.env)
    end
end

return SceneManager
