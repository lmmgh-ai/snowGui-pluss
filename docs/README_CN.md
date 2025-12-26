# snowGui-pluss 中文文档索引

欢迎使用 snowGui-pluss！这是一个完整的中文文档导航页面。

## 📖 文档结构

```
snowGui-pluss/
├── README.md              # 英文简介
├── README_CN.md           # 中文主文档（从这里开始！）
└── docs/
    ├── QUICKSTART_CN.md   # 快速入门指南
    ├── API_CN.md          # API 参考文档
    ├── EXAMPLES_CN.md     # 使用示例
    └── ARCHITECTURE_CN.md # 架构设计
```

## 🎯 根据您的需求选择文档

### 我是新手，想快速上手

👉 [快速入门指南](QUICKSTART_CN.md)
- 5分钟快速开始
- 第一个应用程序
- 常见组件使用
- 完整的事件处理模板

### 我想了解项目概况

👉 [中文主文档](../README_CN.md)
- 项目简介和特性
- 系统要求
- 快速开始示例
- 核心概念介绍

### 我需要查找具体的 API

👉 [API 参考文档](API_CN.md)
- GUI 管理器 API
- 所有视图组件详解
- 布局系统完整说明
- 容器组件参考
- 工具库文档

### 我想看实际的代码示例

👉 [使用示例](EXAMPLES_CN.md)
- 基础示例
- 按钮、输入框、列表
- 各种布局示例
- 事件通信
- 自定义组件开发
- 完整应用（计算器、待办事项）

### 我想深入理解框架原理

👉 [架构设计文档](ARCHITECTURE_CN.md)
- 整体架构图
- 核心模块详解
- 设计模式
- 事件和渲染流程
- 内存管理
- 扩展开发指南

## 📚 推荐学习路径

### 路径 1: 快速上手（推荐新手）

1. **[快速入门指南](QUICKSTART_CN.md)** - 跟随教程创建第一个应用
2. **[使用示例](EXAMPLES_CN.md)** - 学习常见组件的使用
3. **[API 参考](API_CN.md)** - 查找需要的具体功能
4. **[架构设计](ARCHITECTURE_CN.md)** - 深入理解原理

### 路径 2: 系统学习（适合有经验的开发者）

1. **[中文主文档](../README_CN.md)** - 了解框架特性和核心概念
2. **[架构设计](ARCHITECTURE_CN.md)** - 理解框架设计思想
3. **[API 参考](API_CN.md)** - 熟悉所有 API
4. **[使用示例](EXAMPLES_CN.md)** - 参考实际应用案例

### 路径 3: 问题驱动（需要快速解决问题）

1. **[快速入门 - 常见问题](QUICKSTART_CN.md#常见问题)** - 查看是否有现成答案
2. **[使用示例](EXAMPLES_CN.md)** - 寻找类似的代码示例
3. **[API 参考](API_CN.md)** - 查找具体 API 的用法
4. **源码** - `packages/snowGui/` - 查看实现细节

## 🔍 快速查找

### 组件查找

| 需求 | 文档位置 | 页面 |
|------|----------|------|
| 按钮 Button | [API_CN.md](API_CN.md#button-按钮) | API 参考 |
| 文本 Text | [API_CN.md](API_CN.md#text-文本) | API 参考 |
| 输入框 InputText | [API_CN.md](API_CN.md#inputtext-输入框) | API 参考 |
| 滑块 Slider | [API_CN.md](API_CN.md#slider-滑块) | API 参考 |
| 列表 List | [API_CN.md](API_CN.md#list-列表) | API 参考 |
| 窗口 Window | [API_CN.md](API_CN.md#window-窗口) | API 参考 |
| 对话框 Dialog | [API_CN.md](API_CN.md#dialog-对话框) | API 参考 |

### 布局查找

| 布局类型 | 文档位置 | 页面 |
|---------|----------|------|
| 线性布局 | [API_CN.md](API_CN.md#linelayout-线性布局) | API 参考 |
| 网格布局 | [API_CN.md](API_CN.md#gridlayout-网格布局) | API 参考 |
| 重力布局 | [API_CN.md](API_CN.md#gravitylayout-重力布局) | API 参考 |
| 帧布局 | [API_CN.md](API_CN.md#framelayout-帧布局) | API 参考 |

### 主题查找

| 主题 | 文档位置 | 页面 |
|------|----------|------|
| 事件处理 | [QUICKSTART_CN.md](QUICKSTART_CN.md#事件处理完整模板) | 快速入门 |
| 自定义组件 | [EXAMPLES_CN.md](EXAMPLES_CN.md#自定义组件) | 使用示例 |
| 布局使用 | [QUICKSTART_CN.md](QUICKSTART_CN.md#使用布局) | 快速入门 |
| 事件系统 | [ARCHITECTURE_CN.md](ARCHITECTURE_CN.md#事件流程) | 架构设计 |
| 性能优化 | [ARCHITECTURE_CN.md](ARCHITECTURE_CN.md#性能优化建议) | 架构设计 |

## 🎓 学习资源

### 内置示例

项目 `experiment/` 目录包含实际运行的示例：

- `test.lua` - 基础框架演示
- `test1.lua` - 视图添加演示（解析式和面向对象）
- `test2.lua` - 视图编辑器
- `test99.lua` - 临时测试文件

要运行这些示例，编辑 `main.lua` 并取消注释相应的 `require` 语句。

### 完整应用示例

在 [使用示例文档](EXAMPLES_CN.md#完整应用示例) 中，我们提供了两个完整的应用示例：

1. **简单计算器** - 展示按钮网格和事件处理
2. **待办事项应用** - 展示列表、输入框和动态视图管理

## 💡 实用技巧

### 快速参考代码片段

#### 创建基础应用模板

```lua
local packages = require("packages")
local snowGui = packages.snowGui
local gui = snowGui:new()

function love.load()
    -- 在这里添加您的组件
end

function love.update(dt)
    gui:update(dt)
end

function love.draw()
    love.graphics.clear(1, 1, 1)
    gui:draw()
end

-- 复制完整的事件处理代码，参见快速入门指南
```

#### 创建带布局的界面

```lua
local layout = snowGui.line_layout:new({
    x = 50, y = 50,
    width = 300, height = 400,
    orientation = "vertical",
    padding = 10
})

for i = 1, 5 do
    local btn = snowGui.button:new({
        text = "按钮 " .. i,
        height = 60,
        layout_margin = 5
    })
    layout:add_view(btn)
end

gui:add_view(layout)
```

## 🐛 故障排查

遇到问题？按以下顺序查找解决方案：

1. **[常见问题](QUICKSTART_CN.md#常见问题)** - 查看最常见的问题
2. **[调试技巧](QUICKSTART_CN.md#调试技巧)** - 学习如何调试
3. **[架构设计](ARCHITECTURE_CN.md#调试技巧)** - 深入的调试方法
4. **示例代码** - 对比您的代码和示例的差异
5. **源码** - 查看 `packages/snowGui/` 的实现

## 📝 文档版本

- **创建日期**: 2025年12月
- **框架版本**: 基于 lmGui 3.1
- **LÖVE2D 版本**: 11.4+

## 🤝 贡献

发现文档有误或需要改进？欢迎提交 Issue 或 Pull Request！

## 📞 获取帮助

- **GitHub Issues**: 提交问题和建议
- **查看源码**: `packages/snowGui/` 目录
- **运行示例**: `experiment/` 目录

---

**祝您使用愉快！开始您的 snowGui-pluss 之旅吧！** 🚀

推荐从 [快速入门指南](QUICKSTART_CN.md) 开始 →
