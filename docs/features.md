# Claude Code 核心功能

> Claude Code 的 10 大核心功能详解

## 目录

1. [智能代码理解](#1-智能代码理解)
2. [自动化任务](#2-自动化任务)
3. [Bug 修复](#3-bug-修复)
4. [Git 集成](#4-git-集成)
5. [MCP 连接](#5-mcp-连接)
6. [项目记忆](#6-项目记忆-claudemd)
7. [自定义命令](#7-自定义命令-skills)
8. [Hooks 钩子](#8-hooks-钩子)
9. [多代理协作](#9-多代理协作)
10. [远程控制](#10-远程控制)

---

## 1. 智能代码理解

Claude Code 能理解你的整个代码库，进行跨文件分析和编辑。

**特点**：
- 📖 阅读整个项目结构
- 🔍 跨文件依赖分析
- 🎯 精确定位问题代码
- ✏️ 批量编辑多个文件

**示例**：
```bash
claude "分析这个项目的架构，找出所有认证相关的代码"
```

---

## 2. 自动化任务

处理重复性开发任务，节省时间。

**支持的任务**：
- ✅ 编写测试
- ✅ 修复 Lint 错误
- ✅ 解决合并冲突
- ✅ 更新依赖
- ✅ 编写发布说明

**示例**：
```bash
# 为整个项目编写测试
claude "write tests for the auth module, run them, and fix any failures"

# 修复所有 Lint 错误
claude "fix all lint errors in the project"
```

---

## 3. Bug 修复

智能诊断和修复代码问题。

**工作流程**：
1. 📋 接收错误信息或症状描述
2. 🔍 追踪问题根源
3. 💡 分析代码逻辑
4. ✅ 实施修复方案
5. ✅ 验证修复效果

**示例**：
```bash
# 粘贴错误信息
claude "修复这个错误：TypeError: Cannot read property 'user' of undefined"

# 描述症状
claude "用户登录后无法看到个人资料页面"
```

---

## 4. Git 集成

无缝集成 Git 工作流。

**功能**：
- 📦 暂存更改
- 📝 编写提交信息
- 🌳 创建分支
- 🔄 打开 PR
- 📊 代码审查

**示例**：
```bash
# 提交更改
claude "commit my changes with a descriptive message"

# 创建 PR
claude "create a PR for the new feature branch"

# 审查 PR
claude "review this PR for security issues"
```

---

## 5. MCP 连接

通过 Model Context Protocol 连接外部数据源。

**支持的集成**：
- 📄 Google Drive 文档
- 🎫 Jira 工单
- 💬 Slack 数据
- 🗄️ 数据库
- 🔌 自定义工具

**配置示例**：
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-github"]
    }
  }
}
```

**使用**：
```bash
claude "从 Google Drive 读取需求文档并创建对应的 API"
```

---

## 6. 项目记忆 (CLAUDE.md)

在项目根目录创建 `CLAUDE.md` 文件，Claude 会在每次会话开始时读取。

**用途**：
- 📋 设置编码标准
- 🏗️ 记录架构决策
- 📚 指定首选库
- ✅ 定义审查清单
- 🔧 记录构建命令

**模板示例**：
```markdown
# 项目名称

## 技术栈
- 前端：React + TypeScript
- 后端：Node.js + Express
- 数据库：PostgreSQL

## 编码规范
- 使用 ESLint + Prettier
- 遵循 Airbnb Style Guide
- 所有函数必须有 JSDoc 注释

## 架构决策
- 使用分层架构
- API 遵循 RESTful 规范
- 使用 JWT 认证

## 构建命令
```bash
npm install
npm run dev
npm test
npm run build
```
```

---

## 7. 自定义命令 (Skills)

创建可复用的工作流命令。

**创建位置**：`.claude/skills/`

**示例**：
```markdown
# Review PR

Review the current PR for:
- Security issues
- Code quality
- Best practices
- Performance concerns

Provide a summary and actionable feedback.
```

**使用**：
```bash
claude /review-pr
```

**常用 Skills**：
- `/review-pr` - PR 审查
- `/deploy-staging` - 部署到测试环境
- `/fix-lint` - 修复 Lint 问题
- `/generate-docs` - 生成文档

---

## 8. Hooks 钩子

在特定动作前后自动执行命令。

**配置位置**：`.claude/hooks.json`

**示例**：
```json
{
  "afterEdit": {
    "command": "prettier --write ${file}"
  },
  "beforeCommit": {
    "command": "npm run lint"
  },
  "afterTask": {
    "command": "notify 'Task completed'"
  }
}
```

**可用 Hooks**：
- `beforeEdit` - 文件编辑前
- `afterEdit` - 文件编辑后
- `beforeCommand` - 命令执行前
- `afterCommand` - 命令执行后
- `beforeCommit` - 提交前
- `afterTask` - 任务完成后

---

## 9. 多代理协作

创建多个 Claude Code 实例并行工作。

**主代理**：协调工作，分配任务
**子代理**：处理特定子任务

**示例**：
```bash
claude "创建一个落地页，包含：
1. Hero 区域
2. 功能特性
3. 价格表

使用 3 个子代理并行开发每个部分"
```

**优势**：
- ⚡ 并行处理，加快速度
- 🎯 专注特定任务
- 🔄 自动合并结果
- 📊 进度追踪

---

## 10. 远程控制 (Remote Control)

从任何设备继续本地会话。

**功能**：
- 📱 从手机继续工作
- 💻 在浏览器中运行
- 🔄 跨设备会话转移
- 🌐 随时随地访问

**使用方式**：

```bash
# 在本地启动
claude

# 在手机浏览器访问
# https://claude.ai/code

# 转移到桌面应用
/desktop

# 从远程拉取
/teleport
```

---

## 功能对比

| 功能 | Terminal | VS Code | JetBrains | Desktop | Web |
|------|----------|---------|-----------|---------|-----|
| 智能代码理解 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 自动化任务 | ✅ | ✅ | ✅ | ✅ | ✅ |
| Git 集成 | ✅ | ✅ | ✅ | ✅ | ✅ |
| MCP 连接 | ✅ | ✅ | ✅ | ✅ | ✅ |
| CLAUDE.md | ✅ | ✅ | ✅ | ✅ | ✅ |
| Skills | ✅ | ✅ | ✅ | ✅ | ✅ |
| Hooks | ✅ | ✅ | ✅ | ✅ | ✅ |
| 多代理 | ✅ | ❌ | ❌ | ✅ | ✅ |
| 远程控制 | ✅ | ❌ | ❌ | ✅ | ✅ |

---

## 进阶技巧

### 1. 组合使用多个功能

```bash
# 使用 MCP + Git + Skills
claude /deploy-production
# 自动执行：
# 1. 从 Jira 获取需求
# 2. 运行测试
# 3. 创建 PR
# 4. 通知团队
```

### 2. Hooks 自动化

```json
{
  "beforeEdit": "cp ${file} ${file}.backup",
  "afterEdit": "git add ${file} && prettier --write ${file}"
}
```

### 3. 多代理并行

```bash
claude "重构这个项目：
1. Agent 1: 更新数据库层
2. Agent 2: 重构 API 路由
3. Agent 3: 更新前端组件

并行执行，最后合并"
```

---

## 参考资源

- [官方文档](https://code.claude.com/docs/en/overview)
- [CLI 参考](https://code.claude.com/docs/en/cli-reference)
- [常见工作流](https://code.claude.com/docs/en/common-workflows)

---

*回到 [文档索引](../INDEX.md) | [快速开始](getting-started.md)*
