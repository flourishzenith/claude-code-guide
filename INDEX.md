# 📚 Claude Code 使用指南 - 文档索引

> 快速导航到你需要的内容

## 🚀 快速开始

- **[README](README.md)** - 项目介绍和快速开始
- **[快速上手指南](docs/getting-started.md)** - 5分钟开始使用 Claude Code

## 📖 核心文档

### 功能介绍
- **[核心功能](docs/features.md)** - 10大核心功能详解
  - 智能代码理解
  - 自动化任务
  - Bug 修复
  - Git 集成
  - MCP 连接
  - 项目记忆
  - 自定义命令
  - Hooks 钩子
  - 多代理协作
  - 远程控制

### 高级用法
- **[高级特性](docs/advanced.md)** - MCP、Skills、Hooks 深入讲解（待完成）
- **[大规模 Review + 批量 Fix 最佳实践](docs/batch-review-fix-guide.md)** - 避免上下文溢出的工作流程
- **[实战案例](examples/use-cases.md)** - 真实社区案例分析（待完成）

## 🛠️ 运维相关

### 监控和自动化
- **[自动化脚本](scripts/)** - 自动化工具和脚本

### 变更记录
- **[更新日志](CHANGELOG.md)** - 功能变更历史

## 📂 项目结构

```
claude-code-guide/
├── README.md              # 项目介绍
├── INDEX.md               # 本文件
├── CHANGELOG.md           # 更新日志
├── docs/                  # 详细文档
│   ├── getting-started.md # 快速开始
│   ├── features.md        # 核心功能
│   ├── batch-review-fix-guide.md  # 批量 Review + Fix 最佳实践
│   └── advanced.md        # 高级特性
├── examples/              # 实例
│   └── use-cases.md       # 实战案例
├── scripts/               # 脚本
│   └── auto-update.sh     # 自动更新
└── .github/               # GitHub 配置
    └── workflows/
        └── auto-update.yml # GitHub Actions
```

## 🎯 按主题查找

### 学习路径
1. **新手** → [快速开始](docs/getting-started.md)
2. **了解功能** → [核心功能](docs/features.md)
3. **深入学习** → [高级特性](docs/advanced.md)
4. **实战演练** → [实战案例](examples/use-cases.md)

### 常见任务
- **安装配置** → [快速开始](docs/getting-started.md)
- **编写测试** → [核心功能 - 自动化任务](docs/features.md#2-自动化任务)
- **修复 Bug** → [核心功能 - Bug 修复](docs/features.md#3-bug-修复)
- **Git 操作** → [核心功能 - Git 集成](docs/features.md#4-git-集成)
- **项目配置** → [核心功能 - CLAUDE.md](docs/features.md#6-项目记忆-claudemd)
- **自定义命令** → [核心功能 - Skills](docs/features.md#7-自定义命令-skills)
- **自动化工作流** → [核心功能 - Hooks](docs/features.md#8-hooks-钩子)
- **团队协作** → [核心功能 - 多代理](docs/features.md#9-多代理协作)
- **远程开发** → [核心功能 - 远程控制](docs/features.md#10-远程控制)
- **监控更新** → [监控系统](docs/monitoring.md)

## 📊 文档状态

| 文档 | 状态 | 完成度 |
|------|------|--------|
| README | ✅ 完成 | 100% |
| 快速开始 | ✅ 完成 | 100% |
| 核心功能 | ✅ 完成 | 100% |
| 批量 Review + Fix 指南 | ✅ 完成 | 100% |
| 高级特性 | 🚧 进行中 | 60% |
| 实战案例 | 🚧 进行中 | 70% |
| 更新日志 | ✅ 自动更新 | - |

## 🔗 外部资源

### 官方资源
- [Claude Code 官网](https://code.claude.com)
- [官方文档](https://code.claude.com/docs/en/overview)
- [官方 Changelog](https://code.claude.com/docs/en/changelog.md)
- [Agent SDK](https://platform.claude.com/docs/en/agent-sdk/overview)

### 社区
- [Claude Discord](https://discord.gg/clawd)
- [GitHub Discussions](https://github.com/anthropics/claude-code/discussions)
- [X #ClaudeCode](https://x.com/search?q=%23ClaudeCode)

## 🤝 贡献

欢迎贡献内容！查看 [README](README.md#-贡献指南) 了解如何参与。

## 📝 更新计划

- [ ] 完成高级特性文档
- [ ] 添加更多实战案例
- [ ] 视频教程
- [ ] 常见问题 FAQ
- [ ] 中文翻译

---

*回到 [首页](README.md) | 最后更新：2026-03-01*
