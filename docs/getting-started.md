# Claude Code 快速开始指南

> 5 分钟上手 Claude Code

## 🚀 安装

### macOS / Linux / WSL
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### Windows PowerShell
```powershell
irm https://claude.ai/install.ps1 | iex
```

## 🎯 首次使用

```bash
cd your-project
claude
```

## 💡 常用命令

### 1. 修复 Bug
```bash
claude "fix the login bug"
```

### 2. 编写测试
```bash
claude "write tests for the auth module"
```

### 3. 代码审查
```bash
claude "review this PR for security issues"
```

### 4. 重构代码
```bash
claude "refactor this code to be more maintainable"
```

### 5. Git 操作
```bash
claude "commit my changes"
claude "create a PR for this feature"
```

## 📝 项目配置

创建 `CLAUDE.md` 文件：

```markdown
# 项目名称

## 技术栈
- React + TypeScript
- Node.js + Express
- PostgreSQL

## 编码规范
- 使用 ESLint + Prettier
- 遵循 Airbnb Style Guide

## 常用命令
```bash
npm install
npm run dev
npm test
```
```

## 🔧 高级功能

### 自定义命令 (Skills)

创建 `.claude/skills/review.md`：
```markdown
# Code Review

Review the current changes for:
- Security issues
- Code quality
- Best practices
- Performance
```

使用：
```bash
claude /review
```

### 自动化 Hooks

创建 `.claude/hooks.json`：
```json
{
  "afterEdit": {
    "command": "prettier --write ${file}"
  }
}
```

### 多代理协作

```bash
claude "create a landing page with 3 sections, use 3 sub-agents to work in parallel"
```

## 📱 远程控制

### 从手机继续
```bash
# 在本地启动
claude

# 在手机浏览器访问
# https://claude.ai/code
```

### 转移会话
```bash
# 转移到桌面应用
/desktop

# 从远程拉取
/teleport
```

## 🔗 有用链接

- [完整文档](https://code.claude.com/docs/en/overview)
- [快速开始](https://code.claude.com/docs/en/quickstart)
- [常见工作流](https://code.claude.com/docs/en/common-workflows)
- [社区指南](README.md)

---

*需要帮助？查看 [完整指南](README.md) 或 [监控设置](MONITORING.md)*
