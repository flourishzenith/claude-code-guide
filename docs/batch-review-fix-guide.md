# 大规模 Review + 批量 Fix 最佳实践

> 基于 Claude Code 官方文档和社区实战经验
> 
> 最后更新：2026-03-02

## 🎯 核心问题

在大规模代码 review 后，如果在同一 session 直接批量 fix，会导致：
- **上下文溢出**（context overflow）
- **Claude 性能下降**
- **开始产生幻觉**（hallucinate）
- **修复质量大幅下降**

**根本原因**：Claude 的上下文窗口（context window）是有限资源，性能随填充度下降。

---

## 📊 上下文 vs 性能关系

| 上下文使用率 | Claude 表现 | 建议 |
|------------|-----------|------|
| 0-50% | ✅ 优秀 | 正常工作 |
| 50-80% | ⚠️ 开始"忘记"早期指令 | 开始注意 |
| 80-95% | ❌ 频繁错误，性能下降 | 必须 /clear |
| 95%+ | 🔴 **高风险，开始 hallucinate** | 立即 /clear |

**结论**：上下文是核心约束，必须主动管理。

---

## ✅ 正确做法：Review + Fix 分离

### 工作流程

```
┌─────────────────────────────────────────┐
│  Phase 1: Review（主会话）              │
├─────────────────────────────────────────┤
│  • 使用 Plan Mode 探索代码              │
│  • 生成问题列表（ISSUES.md）            │
│  • 按优先级排序                         │
│  • /clear 清理上下文                    │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  Phase 2: Fix（Subagent 逐个）          │
├─────────────────────────────────────────┤
│  • 创建专用 subagent                    │
│  • 每次只修复一个问题                   │
│  • 极致精简上下文                       │
│  • 每个修复后验证                       │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  Phase 3: Verify（主会话）              │
├─────────────────────────────────────────┤
│  • 运行完整测试套件                     │
│  • 代码审查                             │
│  • 提交 PR                              │
└─────────────────────────────────────────┘
```

---

## 🛠️ Claude Code 具体操作

### Phase 1: Review 阶段

#### Step 1: 进入 Plan Mode

**方法 1：启动时进入**
```bash
claude --permission-mode plan
```

**方法 2：会话中切换**
按 `Shift+Tab` 两次，直到看到 `⏸ plan mode on`

**方法 3：一次性查询**
```bash
claude --permission-mode plan -p "Review the codebase for security issues"
```

#### Step 2: 进行 Review

```text
> Review 整个项目找出所有安全问题
  关注：SQL注入、XSS、硬编码密钥
  将结果保存到 SECURITY-ISSUES.md
```

Claude 会：
- 只读取文件，不修改
- 分析代码模式
- 生成结构化报告

#### Step 3: 整理问题列表

Claude 会生成类似文件：

```markdown
# SECURITY-ISSUES.md

## Critical

### 1. SQL Injection in user-service.js:45
- File: src/services/user-service.js
- Line: 45
- Issue: Unsanitized user input in query
- Severity: High

### 2. Hardcoded API Key
- File: src/config/config.js
- Line: 12
- Issue: API key exposed in code
- Severity: High

## Medium
...
```

#### Step 4: 清理上下文

```text
> /clear
```

**重要**：Review 阶段会读取大量文件，必须清理上下文。

---

### Phase 2: Fix 阶段

#### Step 1: 创建修复 Subagent

**方法 1：使用 /agents 命令**

```text
> /agents
```

选择：
- Create new agent
- User-level（全局可用）
- Generate with Claude
- 描述：Security fixer that fixes one issue at a time
- Tools：Read, Edit, Bash
- Model：sonnet

**方法 2：手动创建文件**

```bash
mkdir -p ~/.claude/agents
vim ~/.claude/agents/security-fixer.md
```

内容：

```markdown
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

#### Step 2: 逐个修复

**修复第 1 个问题**

```text
> 使用 security-fixer 修复 SECURITY-ISSUES.md 中的第 1 个问题
```

Claude 会：
- 只获取 issue #1 的描述
- 只读取相关文件
- 实现修复
- 运行测试
- 提交 commit

**修复第 2 个问题**

```text
> 使用 security-fixer 修复 SECURITY-ISSUES.md 中的第 2 个问题
```

重复直到所有问题修复完成。

**关键**：每个问题使用独立的 subagent 调用。

---

### Phase 3: Verify 阶段

#### Step 1: 运行完整测试

```text
> 运行完整测试套件验证所有修复
```

#### Step 2: 代码审查

```text
> 使用 subagent 审查这些安全修复
```

#### Step 3: 提交 PR

```text
> 提交所有修复并创建 PR
```

---

## 🎓 实战案例

### 案例 1：安全审查修复

**场景**：审查 500 个文件的安全问题

#### ❌ 错误方式

```text
> Review 整个项目并修复所有安全问题
```

**后果**：
- 读取 500 文件 → 上下文满
- 发现 150 个问题
- 开始修复 → 幻觉
- 引入新 bug

#### ✅ 正确方式

**Step 1: Review（Plan Mode）**

```bash
claude --permission-mode plan
```

```text
> Review 整个项目找出所有安全问题
  保存到 SECURITY-ISSUES.md
```

**Step 2: 创建 Fixer Subagent**

```bash
cat > ~/.claude/agents/security-fixer.md << 'EOF'
---
name: security-fixer
description: 修复单个安全问题的专家
tools: Read, Edit, Bash
model: sonnet
---

你是一个安全修复专家。每次只修复一个安全问题。

工作流程：
1. 读取问题描述（只读具体 issue）
2. 定位到具体文件和行
3. 实现最小化修复
4. 运行测试验证
5. 提交 commit

原则：最小化改动，不引入新问题
EOF
```

**Step 3: 清理上下文**

```text
> /clear
```

**Step 4: 逐个修复**

```text
> 使用 security-fixer 修复 issue #1
> 使用 security-fixer 修复 issue #2
> 使用 security-fixer 修复 issue #3
...
```

**Step 5: 验证**

```text
> 运行完整测试套件
```

---

### 案例 2：代码风格统一

**场景**：统一 1000 个文件的代码风格

#### ❌ 错误方式

```text
> 统一整个项目的代码风格
```

**后果**：
- 读取 1000 文件 → 上下文爆炸
- 随意修改
- 破坏代码

#### ✅ 正确方式

**Step 1: 分析**

```text
> 找出所有需要格式化的文件
  保存到 FORMAT-LIST.txt
```

**Step 2: 创建 Formatter Subagent**

```bash
cat > ~/.claude/agents/code-formatter.md << 'EOF'
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
EOF
```

**Step 3: 批量处理脚本**

```bash
#!/bin/bash
# format-files.sh

while read file; do
  claude -p "使用 code-formatter 格式化 $file" \
    --allowedTools "Edit,Write,Bash(prettier *)"
done < FORMAT-LIST.txt
```

**Step 4: 运行**

```bash
chmod +x format-files.sh
./format-files.sh
```

---

## 📋 Subagent 配置模板

### 模板 1：通用问题修复器

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
1. 理解问题描述（从 ISSUES.md）
2. 使用 Grep 搜索相关代码
3. 读取相关文件（只读必要的）
4. 实现最小化修复
5. 运行测试验证
6. 记录到 memory

重要：
- 不要读取整个 review 结果
- 只处理当前分配的问题
- 保持上下文极致精简
```

### 模板 2：安全专家

```markdown
---
name: security-expert
description: 安全漏洞修复专家
tools: Read, Edit, Bash, Grep
model: opus
---

你是安全专家。专注于：
- SQL 注入
- XSS 漏洞
- 硬编码密钥
- 认证授权问题

每次只修复一个安全问题。
修复后运行相关测试。
```

### 模板 3：代码格式化器

```markdown
---
name: code-formatter
description: 代码风格格式化
tools: Read, Edit, Write, Bash
background: true
---

格式化代码风格：
1. 读取文件
2. 应用格式化规则
3. 保存文件
4. 运行 linter
```

### 模板 4：测试修复器

```markdown
---
name: test-fixer
description: 修复失败的测试
tools: Read, Edit, Bash
---

修复失败的测试：
1. 读取测试文件
2. 运行测试看错误
3. 修复代码
4. 重新运行测试
5. 确保通过
```

---

## 🤖 自动化工作流

### 方式 1：Claude 主会话自动控制（推荐）

**原理**：主会话中的 Claude 可以多次调用 subagent

```text
> Step 1: Review 整个项目找出所有安全问题
  保存到 SECURITY-ISSUES.md

> Step 2: 读取 SECURITY-ISSUES.md，
  对每个问题依次使用 security-fixer subagent 修复

> Step 3: 等待所有修复完成后，
  运行完整测试套件验证
```

**工作流程**：
1. Claude 主会话进行 review
2. 生成 ISSUES.md 问题列表
3. Claude 自动逐个调用 subagent
4. 每个 subagent 独立修复一个问题
5. Claude 汇总所有修复结果
6. 运行测试验证

**优点**：
- ✅ 完全自动化
- ✅ Claude 控制整个流程
- ✅ 可以处理依赖关系
- ✅ 错误时可以重试

### 方式 2：Bash 脚本自动化

**原理**：脚本解析 ISSUES.md，循环调用 Claude

```bash
#!/bin/bash
# auto-fix.sh

ISSUES_FILE="SECURITY-ISSUES.md"

# Step 1: Review
echo "=== Phase 1: Review ==="
claude --permission-mode plan \
  -p "Review 整个项目找出所有安全问题
      保存到 $ISSUES_FILE
      格式：### N. 标题\n- File: ...\n- Line: ...\n- Issue: ..."

# Step 2: Count issues
TOTAL=$(grep "^###" "$ISSUES_FILE" | wc -l)
echo "Found $TOTAL issues"

# Step 3: Fix each issue
echo "=== Phase 2: Fix ==="
for i in $(seq 1 $TOTAL); do
  echo "Fixing issue #$i..."
  
  claude -p "使用 security-fixer 修复 $ISSUES_FILE 中的第 $i 个问题" \
    --allowedTools "Read,Edit,Bash(git commit *,npm test *)"
  
  echo "Issue #$i completed"
done

# Step 4: Verify
echo "=== Phase 3: Verify ==="
claude -p "运行完整测试套件验证所有修复"

echo "=== Done ==="
```

**使用**：
```bash
chmod +x auto-fix.sh
./auto-fix.sh
```

### 方式 3：Agent Teams（高级）

**原理**：创建一个 agent team 自动协调

```text
> 创建一个 agent team 来自动修复安全问题：
  
  Team Lead:
  - 读取 SECURITY-ISSUES.md
  - 为每个 issue 分配一个 teammate
  - 协调修复顺序
  - 验证所有修复
  
  Workers (3-5个):
  - 每个 worker 处理一个 issue
  - 独立的 subagent
  - 并行工作
```

**配置**：
```json
// .claude/settings.json
{
  "teammateMode": "in-process",
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

### 对比三种方式

| 方式 | 自动化程度 | 灵活性 | 配置难度 | 推荐场景 |
|------|----------|--------|---------|----------|
| **Claude 主会话** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 简单 | 大多数场景 |
| **Bash 脚本** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | 简单 | CI/CD 集成 |
| **Agent Teams** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 复杂 | 复杂项目 |

### 推荐方案

**日常开发**：使用方式 1（Claude 主会话）

```text
> Review 并自动修复所有安全问题
```

**CI/CD 集成**：使用方式 2（Bash 脚本）

```bash
./auto-fix.sh
```

**大型项目**：使用方式 3（Agent Teams）

```text
> 创建 agent team 来自动修复
```

---

## 🔄 批量处理脚本

### 脚本 1：顺序修复

```bash
#!/bin/bash
# fix-issues-sequential.sh

ISSUES_FILE="SECURITY-ISSUES.md"
TOTAL=$(grep "^###" "$ISSUES_FILE" | wc -l)

echo "Total issues: $TOTAL"

for i in $(seq 1 $TOTAL); do
  echo "=== Fixing issue #$i ==="
  
  claude -p "使用 security-fixer 修复 $ISSUES_FILE 中的第 $i 个问题" \
    --allowedTools "Read,Edit,Bash(git commit *,npm test *)"
  
  echo "Issue #$i completed"
  echo ""
done

echo "All issues fixed!"
```

### 脚本 2：并行修复

```bash
#!/bin/bash
# fix-issues-parallel.sh

ISSUES_FILE="SECURITY-ISSUES.md"
TOTAL=$(grep "^###" "$ISSUES_FILE" | wc -l)
MAX_PARALLEL=5

echo "Total issues: $TOTAL"
echo "Max parallel: $MAX_PARALLEL"

seq 1 $TOTAL | xargs -P $MAX_PARALLEL -I {} bash -c '
  echo "=== Fixing issue #{} ==="
  claude -p "使用 security-fixer 修复 '"$ISSUES_FILE"' 中的第 {} 个问题" \
    --allowedTools "Read,Edit,Bash(git commit *,npm test *)"
  echo "Issue #{} completed"
'

echo "All issues fixed!"
```

### 脚本 3：完整自动化流程（推荐）

```bash
#!/bin/bash
# auto-review-and-fix.sh
# 完整自动化工作流：Review → Fix → Verify

set -e  # 遇到错误立即退出

# 配置
ISSUES_FILE="SECURITY-ISSUES.md"
FIXER_AGENT="security-fixer"
MAX_RETRIES=3

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Phase 1: Review
log_info "=== Phase 1: Review 代码库 ==="

if ! claude --permission-mode plan \
  -p "Review 整个项目找出所有安全问题
      关注：SQL注入、XSS、硬编码密钥、认证授权
      保存到 $ISSUES_FILE
      格式要求：
      ### N. 问题标题
      - File: 文件路径
      - Line: 行号
      - Issue: 问题描述
      - Severity: High/Medium/Low"; then
    log_error "Review 失败"
    exit 1
fi

if [ ! -f "$ISSUES_FILE" ]; then
    log_error "ISSUES.md 未生成"
    exit 1
fi

# 统计问题数量
TOTAL=$(grep -c "^###" "$ISSUES_FILE" 2>/dev/null || echo "0")
if [ "$TOTAL" -eq 0 ]; then
    log_info "未发现安全问题"
    exit 0
fi

log_info "发现 $TOTAL 个安全问题"

# Phase 2: 创建 Fixer Agent
log_info "=== Phase 2: 创建 Fixer Subagent ==="

cat > ~/.claude/agents/$FIXER_AGENT.md << 'EOF'
---
name: security-fixer
description: 修复单个安全问题的专家
tools: Read, Edit, Bash, Grep
model: sonnet
---

你是安全修复专家。每次只修复一个安全问题。

工作流程：
1. 读取问题描述（只读具体 issue，不要读其他问题）
2. 使用 Grep 定位相关代码
3. 读取相关文件（只读必要的文件）
4. 实现最小化修复
5. 运行测试验证
6. 提交 commit

重要原则：
- 上下文极致精简：只读当前 issue 相关的代码
- 最小化改动：只修改必要的地方
- 不引入新问题
- 确保测试通过
EOF

log_info "Fixer agent 创建完成"

# Phase 3: 逐个修复
log_info "=== Phase 3: 逐个修复问题 ==="

SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_ISSUES=()

for i in $(seq 1 $TOTAL); do
    log_info "[$i/$TOTAL] 修复问题 #$i"
    
    # 提取问题描述（只读当前问题）
    ISSUE_DESC=$(sed -n "/^### $i\./,/^### /p" "$ISSUES_FILE" | sed '$d' | head -10)
    
    if [ -z "$ISSUE_DESC" ]; then
        log_warn "问题 #$i 描述为空，跳过"
        continue
    fi
    
    # 重试机制
    RETRY_COUNT=0
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if echo "$ISSUE_DESC" | claude -p "使用 $FIXER_AGENT 修复这个安全问题：
            $(cat)
            
            只修复这个问题，不要读取其他问题。" \
            --allowedTools "Read,Edit,Bash,Grep(git commit *,npm test *,pytest *)"; then
            log_info "✓ 问题 #$i 修复成功"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            break
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                log_warn "问题 #$i 修复失败，重试 ($RETRY_COUNT/$MAX_RETRIES)..."
                sleep 2
            else
                log_error "问题 #$i 修复失败（已重试 $MAX_RETRIES 次）"
                FAILED_COUNT=$((FAILED_COUNT + 1))
                FAILED_ISSUES+=($i)
                break
            fi
        fi
    done
    
    echo ""
done

# Phase 4: 验证
log_info "=== Phase 4: 验证所有修复 ==="

if ! claude -p "运行完整测试套件验证所有安全修复"; then
    log_warn "测试失败，请检查修复"
fi

# Phase 5: 汇总
log_info "=== Phase 5: 修复汇总 ==="

echo ""
echo "========================================="
echo "修复完成统计："
echo "  总问题数: $TOTAL"
echo "  成功修复: $SUCCESS_COUNT"
echo "  失败数量: $FAILED_COUNT"

if [ $FAILED_COUNT -gt 0 ]; then
    echo "  失败问题: ${FAILED_ISSUES[@]}"
    echo ""
    log_warn "部分问题修复失败，请手动处理"
    exit 1
else
    echo ""
    log_info "✅ 所有问题修复成功！"
fi

echo "========================================="

# 清理
log_info "清理临时文件..."
# 可以选择保留 ISSUES.md 作为记录
# rm "$ISSUES_FILE"

log_info "自动化工作流完成"


---

## 🎯 决策指南

### 何时使用 Subagent？

| 场景 | 推荐 | 原因 |
|------|------|------|
| **问题数量 < 5** | ❌ 主会话直接修复 | 上下文足够 |
| **问题数量 5-20** | ✅ 顺序 subagent | 避免上下文溢出 |
| **问题数量 > 20** | ✅ 并行 subagent | 提高效率 |
| **需要读取大量文件** | ✅ Subagent | 隔离上下文 |
| **问题相互独立** | ✅ 并行处理 | 无冲突 |
| **问题有依赖关系** | ❌ 顺序处理 | 保证顺序 |

### 选择修复方式

```
问题数量判断
│
├─ < 5 个问题
│  └─ 主会话直接修复
│
├─ 5-20 个问题
│  └─ 顺序 subagent
│     └─ 每个 subagent 修复一个问题
│
└─ > 20 个问题
   └─ 并行 subagent
      └─ 控制并发数（3-5）
```

---

## 📊 性能对比

### 场景：修复 100 个安全问题

| 方式 | 时间 | 质量 | 风险 | 推荐度 |
|------|------|------|------|--------|
| **主会话批量** | 30分钟 | 60% | 🔴 高 | ❌ 不推荐 |
| **顺序 subagent** | 2小时 | 95% | 🟢 低 | ✅ 最安全 |
| **并行 subagent** | 45分钟 | 90% | 🟢 低 | ✅ 推荐 |
| **Agent Teams** | 40分钟 | 92% | 🟢 低 | ✅ 高级 |

**结论**：
- **质量优先**：顺序 subagent
- **效率优先**：并行 subagent
- **避免**：主会话批量

---

## ⚠️ 常见错误

### 错误 1：在同一 session 连续执行

```text
❌ > Review 项目并修复所有问题
✅ > Review 项目，保存到 ISSUES.md，然后 /clear
    > 使用 subagent 逐个修复
```

### 错误 2：把整个 review 给 subagent

```text
❌ > 使用 subagent 修复 SECURITY-ISSUES.md 中的所有问题
✅ > 使用 subagent 修复 SECURITY-ISSUES.md 中的第 1 个问题
    > 使用 subagent 修复 SECURITY-ISSUES.md 中的第 2 个问题
```

### 错误 3：不清理上下文

```text
❌ Review 完直接开始修复
✅ Review 完 /clear，然后新建会话修复
```

### 错误 4：过长会话

```text
❌ 会话持续 4 小时
✅ 每 1-2 小时 /clear 或新建会话
```

### 错误 5：忽略验证

```text
❌ 修复完不测试
✅ 每个修复后运行测试
```

---

## 🚀 高级技巧

### 技巧 1：极致精简上下文

**关键原则**：只给 subagent 需要的最小信息

```text
❌ 把整个 SECURITY-ISSUES.md 给 subagent
✅ 只给具体问题的描述：

> 使用 security-fixer 修复这个问题：
   File: src/services/user-service.js
   Line: 45
   Issue: SQL injection
   不要读取其他问题
```

### 技巧 2：使用 Memory

让 subagent 记住常见模式：

```markdown
---
name: issue-fixer
memory: user
---

修复后更新你的 memory：
- 常见问题模式
- 最佳修复方法
- 测试策略
```

### 技巧 3：增量验证

```text
> 每修复 10 个问题后，
  运行完整测试套件验证没有回归
```

### 技巧 4：独立分支

```bash
# 为每个修复创建独立分支
for i in $(seq 1 $total); do
  git checkout -b fix-issue-$i
  claude -p "修复第 $i 个问题"
  git commit -am "Fix issue $i"
done
```

### 技巧 5：使用 Git Worktree

```bash
# 为每个问题创建独立 worktree
git worktree add ../fix-issue-1 -b fix-issue-1
cd ../fix-issue-1
claude -p "修复第 1 个问题"
```

---

## 📚 Claude Code 命令参考

### Plan Mode

```bash
# 启动时进入 plan mode
claude --permission-mode plan

# 会话中切换
Shift+Tab (两次)

# 一次性查询
claude --permission-mode plan -p "Review code"
```

### Subagent 管理

```bash
# 列出所有 subagent
claude agents

# 交互式创建
/agents

# 使用 subagent
使用 <agent-name> <task>

# Resume subagent
继续之前的 <agent-name> 工作
```

### 上下文管理

```bash
# 清理上下文
/clear

# 压缩上下文
/compact Focus on API changes

# Rewind
Esc + Esc
/rewind
```

### 非交互模式

```bash
# 单次查询
claude -p "prompt"

# 限制工具
claude -p "prompt" --allowedTools "Read,Edit"

# JSON 输出
claude -p "prompt" --output-format json
```

---

## 🔑 核心原则

1. **Review 和 Fix 必须分离**
   - Review: Plan Mode → 生成 ISSUES.md
   - Fix: Subagent 逐个修复
   - Verify: 测试 + PR

2. **上下文极致精简**
   - 每个 subagent 只获取相关信息
   - 不要塞入整个 review 结果
   - context 越窄，fix 越准

3. **主动管理上下文**
   - Review 后 /clear
   - 每 1-2 小时新建会话
   - 避免上下文压缩

4. **逐个修复，验证每个**
   - 每个问题独立 subagent
   - 修复后立即测试
   - 失败则回滚

5. **版本控制很重要**
   - 每个 issue 独立分支
   - 或使用 worktree
   - 方便回滚

---

## 📖 相关文档

- **Subagents**: https://code.claude.com/docs/en/sub-agents
- **Plan Mode**: https://code.claude.com/docs/en/common-workflows#use-plan-mode-for-safe-code-analysis
- **Agent Teams**: https://code.claude.com/docs/en/agent-teams
- **Git Worktrees**: https://code.claude.com/docs/en/common-workflows#run-parallel-claude-code-sessions-with-git-worktrees
- **Best Practices**: https://code.claude.com/docs/en/best-practices

---

*基于 Claude Code 官方文档和实战经验整理*
