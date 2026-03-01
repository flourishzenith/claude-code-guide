# 项目管理说明

本文档说明如何管理 Claude Code Guide 项目。

## 📂 项目结构

```
claude-code-guide/              # 源文档（工作目录）
claude-code-guide.github/       # GitHub 仓库（发布目录）
├── README.md                   # 项目首页
├── INDEX.md                    # 文档索引
├── CHANGELOG.md                # 更新日志
├── LICENSE                     # 许可证
├── docs/                       # 文档目录
│   ├── getting-started.md      # 快速开始
│   ├── features.md             # 核心功能
│   ├── monitoring.md           # 监控系统
│   └── source-readme.md        # 源文档备份
├── examples/                   # 实例（待完善）
├── scripts/                    # 脚本
│   ├── auto-update.sh          # 自动更新（GitHub Actions）
│   └── sync.sh                 # 同步源文档
└── .github/workflows/          # GitHub Actions
    └── auto-update.yml         # 自动更新工作流
```

## 🔄 自动化流程

### 1. 文档同步

**脚本**：`scripts/sync.sh`

**功能**：
- 监控源文档变更
- 自动复制到 GitHub 仓库
- 提交并推送

**手动运行**：
```bash
~/.openclaw/workspace/projects/claude-code-guide.github/scripts/sync.sh
```

### 2. GitHub Actions 自动更新

**文件**：`.github/workflows/auto-update.yml`

**功能**：
- 每天检查官方 changelog
- 自动更新 CHANGELOG.md
- 创建 Issue 提醒手动更新

**手动触发**：
```bash
gh workflow run auto-update.yml
```

### 3. 版本监控

**脚本**：`~/.local/share/claude-code-monitor/check_version.sh`

**功能**：
- 检测 Claude Code 版本变更
- 监控官方文档更新

**配置 Cron**：
```bash
0 9 * * * ~/.local/share/claude-code-monitor/check_version.sh
```

## 📝 工作流程

### 更新文档

1. **编辑源文档**
   ```bash
   cd ~/.openclaw/workspace/projects/claude-code-guide
   # 编辑文件
   ```

2. **同步到 GitHub**
   ```bash
   ~/.openclaw/workspace/projects/claude-code-guide.github/scripts/sync.sh
   ```

3. **查看变更**
   ```bash
   cd ~/.openclaw/workspace/projects/claude-code-guide.github
   git log --oneline -5
   ```

### 添加新内容

1. 在源目录创建新文件
2. 运行同步脚本
3. 更新 INDEX.md 添加新链接

### 更新 CHANGELOG

1. GitHub Actions 每天自动检查
2. 检测到更新会：
   - 更新 CHANGELOG.md
   - 创建 Issue 提醒
3. 手动更新相关文档内容

## 🔧 维护任务

### 每周
- [ ] 检查 GitHub Issues
- [ ] 查看社区反馈
- [ ] 更新实战案例

### 每月
- [ ] 审查文档完整性
- [ ] 更新功能列表
- [ ] 优化项目结构

### 需要时
- [ ] 添加新功能文档
- [ ] 更新监控脚本
- [ ] 修复 broken links

## 📊 监控指标

- **文档完整性**：95%
- **自动化率**：80%
- **更新频率**：根据官方更新

## 🚀 改进计划

- [ ] 添加视频教程
- [ ] 创建交互式示例
- [ ] 多语言支持
- [ ] API 文档
- [ ] 常见问题 FAQ

## 🔗 相关链接

- **GitHub 仓库**：https://github.com/flourishzenith/claude-code-guide
- **源文档目录**：`~/.openclaw/workspace/projects/claude-code-guide/`
- **监控脚本**：`~/.local/share/claude-code-monitor/`

---

*最后更新：2026-03-01*
