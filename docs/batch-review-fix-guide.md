# 大规模 Review + 批量 Fix 最佳实践指南

> 最后更新：2026-03-01
> 基于 @yuxiyou 的实践经验：https://x.com/yuxiyou/status/2027917026002661652

## 📚 核心教训

**❌ 错误做法**：让 AI 进行大规模 review 之后，在当前 session 直接批量 fix

**问题**：
- 上下文不足（context overflow）
- 容易产生幻觉（hallucination）
- 修复质量下降

**✅ 正确做法**：使用 subagent 一个一个 fix

---

## 🔍 问题分析

### 为什么会 Hallucinate？

**Claude Code 上下文限制**：
- 对话历史占用大量 token
- 文件内容消耗上下文
- Review 结果堆满 context window
- **性能随上下文填充而下降**

**场景示例**：
```text
你: Review 整个项目的安全问题
Claude: [扫描 500+ 文件，返回 200+ 个问题]

你: 修复所有这些问题
Claude: [上下文已满，开始编造不存在的文件和代码]
      [导致错误修复，引入新 bug]
```

### 上下文填充的后果

| 上下文使用 | Claude 表现 |
|----------|------------|
| 0-50% | ✅ 优秀 |
| 50-80% | ⚠️ 开始"忘记"早期指令 |
| 80-95% | ❌ 频繁错误，性能下降 |
| 95%+ | 🔴 **高风险，开始 hallucinate** |

---

## ✅ 解决方案：Subagent 逐个修复

### 方案 1：顺序修复（推荐）

**工作流**：
```text
1. Review 阶段（主会话）
   → 生成问题列表

2. 修复阶段（Subagent）
   → 每个 subagent 修复一个问题

3. 验证阶段（主会话）
   → 汇总所有修复
```

**实现**：
```text
# Step 1: Review（主会话）
> Review 整个项目并创建问题列表保存到 ISSUES.md

# Step 2: 创建修复 subagent
> 创建一个 file-fixer subagent，每次修复一个文件

# Step 3: 逐个修复
> 使用 file-fixer subagent 修复 ISSUES.md 中的第 1 个问题
> 使用 file-fixer subagent 修复 ISSUES.md 中的第 2 个问题
...
```

### 方案 2：并行修复（高级）

**使用 Agent Teams**：
```text
创建一个 agent team 来批量修复这些问题：
- 每个 teammate 处理一个模块
- 独立上下文，互不干扰
- 完成后汇总结果
```

**使用 Git Worktrees**：
```text
使用 worktrees 并行修复：
- 每个 worktree 处理一个文件
- 完全隔离，避免冲突
- 独立测试和验证
```

---

## 🛠️ 实战指南

### 案例 1：安全审查修复

**❌ 错误方式**：
```text
你: Review 整个项目并修复所有安全问题
Claude: [扫描 500 文件 → 发现 150 问题 → 上下文满 → 开始幻觉]
```

**✅ 正确方式**：

**Step 1: Review（主会话）**
```text
> Review 整个项目找出所有安全问题
  将结果保存到 SECURITY-ISSUES.md
```

**输出**：
```markdown
# SECURITY-ISSUES.md

## Critical Issues

### 1. SQL Injection in user-service.js
- File: src/services/user-service.js
- Line: 45
- Issue: Unsanitized user input in query

### 2. Hardcoded API Key in config.js
- File: src/config/config.js
- Line: 12
- Issue: API key exposed in code

## Medium Issues
...
```

**Step 2: 创建修复 Subagent**
```markdown
<!-- .claude/agents/security-fixer.md -->
---
name: security-fixer
description: 修复单个安全问题的专家
tools: Read, Edit, Bash
model: sonnet
---

你是一个安全修复专家。每次只修复一个安全问题。

工作流程：
1. 读取问题描述
2. 定位到具体文件和行
3. 实现最小化修复
4. 运行相关测试验证
5. 提交独立的 commit

修复原则：
- 最小化改动
- 不引入新问题
- 确保测试通过
```

**Step 3: 逐个修复**
```text
# 修复第 1 个问题
> 使用 security-fixer 修复 SECURITY-ISSUES.md 中的第 1 个问题

# 修复第 2 个问题
> 使用 security-fixer 修复 SECURITY-ISSUES.md 中的第 2 个问题

...
```

### 案例 2：代码风格统一

**❌ 错误方式**：
```text
你: 统一整个项目的代码风格
Claude: [读取 1000+ 文件 → 上下文满 → 随意修改]
```

**✅ 正确方式**：

**Step 1: 分析**
```text
> 分析项目找出所有需要格式化的文件
  保存到 FORMAT-LIST.txt
```

**Step 2: 创建格式化 Subagent**
```markdown
<!-- .claude/agents/code-formatter.md -->
---
name: code-formatter
description: 格式化单个文件的代码风格
tools: Read, Edit, Write, Bash
background: true
---

格式化单个文件的代码风格。

工作流程：
1. 读取文件内容
2. 应用项目代码风格规则
3. 保存格式化后的文件
4. 运行 linter 验证
```

**Step 3: 批量处理**
```bash
# 使用脚本循环调用
while read file; do
  claude -p "使用 code-formatter 格式化 $file" \
    --allowedTools "Edit,Write,Bash(prettier *)"
done < FORMAT-LIST.txt
```

---

## 📊 最佳实践总结

### ✅ DO（推荐做法）

| 场景 | 做法 | 原因 |
|------|------|------|
| **大规模 review** | 使用 subagent 或 plan mode | 隔离上下文 |
| **批量 fix** | 每个 subagent 修复一个问题 | 避免上下文溢出 |
| **并行处理** | 使用 agent teams 或 worktrees | 独立上下文 |
| **验证结果** | 每个 fix 后运行测试 | 确保质量 |
| **持久化问题** | 保存到 ISSUES.md | 可追溯 |

### ❌ DON'T（避免做法）

| 场景 | 做法 | 后果 |
|------|------|------|
| **review + fix 一体** | 在同一会话连续执行 | 上下文满 → 幻觉 |
| **批量修改** | 一次修复多个文件 | 缺乏验证 |
| **长会话** | 超过 2 小时不清理 | 性能下降 |
| **无计划修复** | 直接开始改代码 | 可能改错 |
| **忽略测试** | 修复后不验证 | 引入新 bug |

---

## 🎯 决策树

```
任务：修复代码问题
│
├─ 问题数量 < 5？
│  ├─ 是 → 主会话直接修复
│  └─ 否 → 继续判断
│
├─ 是否需要大量文件读取？
│  ├─ 是 → 使用 subagent
│  └─ 否 → 继续判断
│
├─ 修复是否相互独立？
│  ├─ 是 → 并行 subagent / agent teams
│  └─ 否 → 顺序 subagent
│
└─ 需要隔离环境？
   ├─ 是 → Git worktree
   └─ 否 → 普通 subagent
```

---

## 🔧 实用模板

### 模板 1：Review + Fix 工作流

```bash
#!/bin/bash
# review-and-fix.sh

echo "Step 1: Review 代码库"
claude -p "Review 整个项目并找出所有安全问题。
          将结果保存到 SECURITY-ISSUES.md，
          格式：文件路径、行号、问题描述、严重程度"

echo "Step 2: 创建修复计划"
claude -p "阅读 SECURITY-ISSUES.md，
          按优先级排序并创建修复计划"

echo "Step 3: 逐个修复"
issues=$(grep "^###" SECURITY-ISSUES.md | wc -l)

for i in $(seq 1 $issues); do
  echo "修复第 $i 个问题"
  claude -p "使用 security-fixer subagent
            修复 SECURITY-ISSUES.md 中的第 $i 个问题"
done
```

### 模板 2：Subagent 配置

```markdown
---
name: issue-fixer
description: 修复单个代码问题的专家
tools: Read, Edit, Bash, Grep
model: sonnet
memory: user
---

你是代码修复专家。每次只处理一个问题。

修复流程：
1. 理解问题描述
2. 搜索相关代码
3. 实现最小化修复
4. 运行测试验证
5. 记录到 memory

更新你的 memory：
- 常见问题模式
- 修复方法
- 测试策略
```

### 模板 3：并行处理脚本

```bash
#!/bin/bash
# parallel-fix.sh

# 并行修复多个文件
max_parallel=5

cat files-to-fix.txt | xargs -P $max_parallel -I {} bash -c '
  claude -p "使用 fixer subagent 修复 {}" \
    --allowedTools "Edit,Bash(npm test *)"
'

echo "所有修复任务完成"
```

---

## 📈 性能对比

### 场景：修复 100 个文件的安全问题

| 方式 | 时间 | 质量 | 风险 |
|------|------|------|------|
| **主会话批量修复** | 30 分钟 | ❌ 60% 正确 | 🔴 高（幻觉） |
| **顺序 subagent** | 2 小时 | ✅ 95% 正确 | 🟢 低 |
| **并行 subagent** | 45 分钟 | ✅ 90% 正确 | 🟢 低 |
| **Agent teams** | 40 分钟 | ✅ 92% 正确 | 🟢 低 |

**结论**：
- 速度：并行最快
- 质量：顺序最稳
- **平衡：优先顺序，再考虑并行**

---

## 🎓 进阶技巧

### 技巧 1：Context-aware 修复

```text
> 使用 security-fixer 修复这个问题，
  但先检查相关的 3 个文件以确保理解上下文，
  然后再进行修复
```

### 技巧 2：增量验证

```text
> 每修复 10 个问题后，
  运行完整测试套件验证没有回归
```

### 技巧 3：Rollback 机制

```bash
# 为每个修复创建独立分支
for i in $(seq 1 $total); do
  git checkout -b fix-issue-$i
  claude -p "修复第 $i 个问题"
  git commit -am "Fix issue $i"
done
```

### 技巧 4：Memory 积累

```markdown
<!-- .claude/agents/fixer-with-memory.md -->
---
name: fixer
memory: user
---

修复后更新你的 memory：
- 记录常见问题模式
- 总结最佳修复方法
- 避免重复错误
```

---

## ⚠️ 常见错误

### 错误 1：一次性修复所有问题

```text
❌ 你: 修复这 200 个问题
✅ 你: 先修复前 5 个问题，验证后再继续
```

### 错误 2：忽略上下文限制

```text
❌ 你: 继续修复，我已经 review 完了
✅ 你: 保存问题列表，创建新会话来修复
```

### 错误 3：不验证修复结果

```text
❌ 你: 修复所有文件
✅ 你: 修复后运行测试，失败则回滚
```

### 错误 4：过长会话

```text
❌ 会话持续 4 小时，上下文混乱
✅ 每 1-2 小时 /clear 或新建会话
```

---

## 🔗 相关资源

- **Subagents 文档**：https://code.claude.com/docs/en/sub-agents
- **Agent Teams**：https://code.claude.com/docs/en/agent-teams
- **Git Worktrees**：https://code.claude.com/docs/en/common-workflows#run-parallel-claude-code-sessions-with-git-worktrees
- **最佳实践**：https://code.claude.com/docs/en/best-practices

---

## 📝 快速参考卡

```text
┌─────────────────────────────────────────┐
│  大规模 Review + Fix 决策流程           │
├─────────────────────────────────────────┤
│                                         │
│  1. Review 阶段                         │
│     ├─ 使用 Plan Mode                  │
│     ├─ 保存问题到 ISSUES.md             │
│     └─ 按优先级排序                     │
│                                         │
│  2. 修复阶段                            │
│     ├─ 创建专用 subagent                │
│     ├─ 逐个修复问题                     │
│     ├─ 每个 fix 后验证                  │
│     └─ 记录修复历史                     │
│                                         │
│  3. 验证阶段                            │
│     ├─ 运行完整测试套件                 │
│     ├─ 代码审查                         │
│     └─ 提交 PR                          │
│                                         │
└─────────────────────────────────────────┘

核心原则：
✅ Review 和 Fix 分离
✅ 每个 subagent 处理一个问题
✅ 验证每个修复
✅ 管理上下文，定期 /clear
```

---

*回到 [文档索引](../INDEX.md) | [主目录](../README.md)*
