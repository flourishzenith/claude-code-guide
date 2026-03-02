# Claude Code 高级特性指南

> 深入了解 MCP、Skills、Hooks 等高级功能
>
> 最后更新：2026-03-02

---

## 📚 目录

- [MCP (Model Context Protocol)](#mcp-model-context-protocol)
- [Skills (自定义技能)](#skills-自定义技能)
- [Hooks (钩子系统)](#hooks-钩子系统)
- [高级配置](#高级配置)
- [性能优化](#性能优化)
- [故障排查](#故障排查)

---

## MCP (Model Context Protocol)

### 🎯 什么是 MCP？

**MCP (Model Context Protocol)** 是 Claude Code 的扩展协议，允许你连接外部工具和数据源，大幅扩展 Claude 的能力。

### 核心概念

1. **MCP Server**
   - 提供工具和资源的独立进程
   - 可以是本地或远程服务
   - 通过 stdio 或 HTTP 通信

2. **MCP Client**
   - Claude Code 内置的 MCP 客户端
   - 管理服务器连接
   - 调用工具和获取资源

3. **Tools (工具)**
   - MCP Server 提供的可执行函数
   - Claude 可以调用这些工具
   - 例如：数据库查询、API 请求

4. **Resources (资源)**
   - MCP Server 提供的数据
   - Claude 可以读取这些资源
   - 例如：文件、数据库记录、API 响应

### 配置 MCP Servers

### 方法 1：项目级配置

创建 `.claude/config.json`：

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/path/to/allowed/directory"
      ]
    },
    "database": {
      "command": "python",
      "args": [
        "/path/to/mcp-server-db.py"
      ],
      "env": {
        "DATABASE_URL": "postgresql://localhost/mydb"
      }
    }
  }
}
```

### 方法 2：用户级配置

编辑 `~/.claude/config.json`：

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your_token_here"
      }
    },
    "postgres": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://localhost/mydb"
      ]
    }
  }
}
```

### 常用 MCP Servers

#### 1. Filesystem Server

```bash
npx -y @modelcontextprotocol/server-filesystem /path/to/directory
```

**功能**：
- 读取文件
- 列出目录
- 搜索文件
- 写入文件（需要权限）

**使用场景**：
- 访问项目文档
- 读取配置文件
- 搜索代码示例

#### 2. GitHub Server

```bash
npx -y @modelcontextprotocol/server-github
```

**功能**：
- 查看仓库
- 读取 Issues
- 查看 PR
- 获取文件内容

**配置**：
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxx"
      }
    }
  }
}
```

**使用示例**：
```
查看 anthropics/claude-code 仓库的最近 5 个 issues
```

#### 3. PostgreSQL Server

```bash
npx -y @modelcontextprotocol/server-postgres "postgresql://localhost/mydb"
```

**功能**：
- 执行 SQL 查询
- 获取表结构
- 查看数据库统计

**使用示例**：
```
查询 users 表中最近注册的 10 个用户
```

#### 4. Brave Search Server

```bash
npx -y @modelcontextprotocol/server-brave-search
```

**功能**：
- 网络搜索
- 获取搜索结果
- 摘要网页内容

**配置**：
```json
{
  "mcpServers": {
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "your_api_key"
      }
    }
  }
}
```

### 创建自定义 MCP Server

### Python 示例

```python
#!/usr/bin/env python3
import json
import sys
from mcp.server import Server
from mcp.types import Tool, Resource

app = Server("my-mcp-server")

@app.tool("calculate")
async def calculate(expression: str) -> str:
    """计算数学表达式"""
    try:
        result = eval(expression)
        return f"结果: {result}"
    except Exception as e:
        return f"错误: {str(e)}"

@app.resource("data://stats")
async def get_stats() -> str:
    """获取统计数据"""
    return json.dumps({
        "requests": 1000,
        "errors": 5,
        "uptime": "99.9%"
    })

async def main():
    async with app.run() as server:
        await server.run()

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
```

### Node.js 示例

```javascript
#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';

const server = new Server({
  name: 'my-mcp-server',
  version: '1.0.0'
});

// 注册工具
server.setRequestHandler('tools/list', async () => ({
  tools: [
    {
      name: 'calculate',
      description: '计算数学表达式',
      inputSchema: {
        type: 'object',
        properties: {
          expression: {
            type: 'string',
            description: '要计算的表达式'
          }
        },
        required: ['expression']
      }
    }
  ]
}));

server.setRequestHandler('tools/call', async (request) => {
  if (request.params.name === 'calculate') {
    const expr = request.params.arguments.expression;
    try {
      const result = eval(expr);
      return {
        content: [{
          type: 'text',
          text: `结果: ${result}`
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `错误: ${error.message}`
        }]
      };
    }
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(console.error);
```

### MCP 最佳实践

1. **安全性**
   - 不要暴露敏感数据
   - 使用环境变量存储密钥
   - 限制访问路径

2. **性能**
   - 缓存频繁查询的资源
   - 使用异步操作
   - 限制返回数据量

3. **错误处理**
   - 提供清晰的错误消息
   - 优雅降级
   - 记录错误日志

4. **文档**
   - 清晰的工具描述
   - 完整的参数说明
   - 提供使用示例

---

## Skills (自定义技能)

### 🎯 什么是 Skills？

**Skills** 是可重用的提示词模板和配置，让 Claude Code 学会特定的工作方式。

### Skill 文件结构

Skill 文件是 Markdown 文件，包含以下部分：

```markdown
---
name: my-skill
description: 技能描述
model: sonnet
tools: Read, Write, Edit, Bash
memory: user
---

# 技能标题

技能的详细说明...
```

### 创建 Skill

### 步骤 1：创建 Skill 文件

```bash
mkdir -p ~/.claude/skills
vim ~/.claude/skills/my-skill.md
```

### 步骤 2：编写 Skill 内容

```markdown
---
name: code-reviewer
description: 专业的代码审查专家
model: sonnet
tools: Read, Edit, Bash, Grep
---

# 代码审查专家

你是一个经验丰富的代码审查专家。

## 审查重点

1. **安全性**
   - SQL 注入
   - XSS 漏洞
   - 认证问题

2. **性能**
   - 算法复杂度
   - 内存使用
   - 数据库查询

3. **可维护性**
   - 代码结构
   - 命名规范
   - 注释质量

## 审查流程

1. 读取代码文件
2. 分析潜在问题
3. 提供改进建议
4. 生成审查报告

## 输出格式

```markdown
## 代码审查报告

### 发现的问题
1. [严重] 问题描述
   - 位置：文件:行号
   - 建议：修复方案

### 改进建议
1. 性能优化
2. 代码质量
```
```

### 步骤 3：使用 Skill

```
使用 code-reviewer 审查 src/auth.py 文件
```

### Skill 配置选项

### 基础配置

```yaml
---
name: skill-name
description: 技能描述
model: sonnet          # 使用的模型
tools: Read, Write     # 允许的工具
memory: user           # 记忆级别: none/user/session
---
```

### 高级配置

```yaml
---
name: advanced-skill
description: 高级技能示例
model: opus
tools: Read, Write, Edit, Bash, Grep, Web
memory: session
temperature: 0.7      # 创造性程度
maxTokens: 4000       # 最大 token 数
---

# 技能内容
```

### 内置变量

Claude Code 在 Skill 中提供以下变量：

```markdown
## 可用变量

- `{{cwd}}` - 当前工作目录
- `{{filename}}` - 当前文件名
- `{{selection}}` - 选中的文本
- `{{clipboard}}` - 剪贴板内容
- `{{date}}` - 当前日期
- `{{time}}` - 当前时间
```

### 示例 Skills

#### 1. 文档生成器

```markdown
---
name: doc-generator
description: 自动生成代码文档
tools: Read, Write
model: sonnet
---

# 文档生成器

为代码文件生成 JSDoc/Docstring 文档。

## 规则

1. 分析函数签名
2. 理解函数功能
3. 生成标准文档格式
4. 添加使用示例

## 输出格式

```javascript
/**
 * 函数简短描述
 *
 * @param {type} param - 参数描述
 * @returns {type} 返回值描述
 * @example
 * functionName(args);
 */
```

使用方式：
```
使用 doc-generator 为当前文件生成文档
```

#### 2. 测试生成器

```markdown
---
name: test-generator
description: 为代码生成单元测试
tools: Read, Write, Bash
model: sonnet
---

# 测试生成器

为代码生成完整的单元测试。

## 测试框架

根据项目自动检测：
- Jest (JavaScript)
- Pytest (Python)
- JUnit (Java)

## 覆盖场景

1. 正常情况
2. 边界条件
3. 错误处理
4. 边界值

## 输出格式

```javascript
describe('FunctionName', () => {
  it('should do something', () => {
    // 测试代码
  });
});
```
```

#### 3. 重构助手

```markdown
---
name: refactor-helper
description: 代码重构建议和执行
tools: Read, Write, Edit, Bash
model: opus
---

# 重构助手

帮助重构代码，提高质量。

## 重构原则

1. DRY (Don't Repeat Yourself)
2. SOLID 原则
3. 清晰的命名
4. 适当的抽象

## 工作流程

1. 分析代码结构
2. 识别问题
3. 提供重构方案
4. 执行重构
5. 运行测试验证
```

### Skill 最佳实践

1. **清晰的目的**
   - 单一职责
   - 明确的使用场景
   - 具体的输出格式

2. **详细的说明**
   - 工作流程
   - 规则和约束
   - 示例和模板

3. **合适的工具**
   - 只声明需要的工具
   - 避免过度权限

4. **适当的模型**
   - 简单任务用 sonnet
   - 复杂任务用 opus
   - 考虑成本和速度

### 管理 Skills

### 列出所有 Skills

```
/agents
```

### 查看 Skill 详情

```
使用 skill-name 并显示其配置
```

### 删除 Skill

```bash
rm ~/.claude/skills/skill-name.md
```

### 更新 Skill

```bash
vim ~/.claude/skills/skill-name.md
```

---

## Hooks (钩子系统)

### 🎯 什么是 Hooks？

**Hooks** 是在特定事件发生时自动执行的脚本，让你自定义 Claude Code 的行为。

### Hook 类型

### 1. Before Edit Hook

**触发时机**：在编辑文件之前

**用途**：
- 备份文件
- 检查文件状态
- 验证编辑权限

**配置**：

```json
{
  "hooks": {
    "beforeEdit": {
      "command": "cp",
      "args": ["{{filepath}}", "{{filepath}}.bak"]
    }
  }
}
```

### 2. After Edit Hook

**触发时机**：在编辑文件之后

**用途**：
- 运行 linter
- 执行格式化
- 触发测试

**配置**：

```json
{
  "hooks": {
    "afterEdit": {
      "command": "npm",
      "args": ["run", "lint"]
    }
  }
}
```

### 3. Before Command Hook

**触发时机**：在执行命令之前

**用途**：
- 检查环境
- 加载配置
- 准备依赖

**配置**：

```json
{
  "hooks": {
    "beforeCommand": {
      "command": "source",
      "args": ["setup.sh"]
    }
  }
}
```

### 4. After Command Hook

**触发时机**：在执行命令之后

**用途**：
- 清理临时文件
- 收集统计信息
- 发送通知

**配置**：

```json
{
  "hooks": {
    "afterCommand": {
      "command": "rm",
      "args": ["-rf", "/tmp/claude-temp/*"]
    }
  }
}
```

### Hook 配置位置

### 项目级 Hooks

创建 `.claude/hooks.json`：

```json
{
  "hooks": {
    "beforeEdit": {
      "command": "cp",
      "args": ["{{filepath}}", "{{filepath}}.bak"],
      "runInBackground": false
    },
    "afterEdit": {
      "command": "npx",
      "args": ["prettier", "--write", "{{filepath}}"],
      "runInBackground": true
    }
  }
}
```

### 用户级 Hooks

编辑 `~/.claude/hooks.json`：

```json
{
  "hooks": {
    "beforeCommand": {
      "command": "echo",
      "args": ["Starting command..."]
    },
    "afterCommand": {
      "command": "notify-send",
      "args": ["Claude Code", "Command completed"],
      "runInBackground": true
    }
  }
}
```

### Hook 变量

在 Hook 命令中可以使用以下变量：

| 变量 | 描述 | 示例 |
|------|------|------|
| `{{filepath}}` | 文件路径 | `/home/user/project/src/index.js` |
| `{{filename}}` | 文件名 | `index.js` |
| `{{cwd}}` | 当前目录 | `/home/user/project` |
| `{{git_root}}` | Git 根目录 | `/home/user/project` |
| `{{timestamp}}` | 时间戳 | `1677639600` |
| `{{uuid}}` | 唯一 ID | `550e8400-e29b-41d4-a716-446655440000` |

### Hook 实战示例

#### 1. 自动备份

```json
{
  "hooks": {
    "beforeEdit": {
      "command": "cp",
      "args": ["{{filepath}}", "{{filepath}}.bak.{{timestamp}}"]
    }
  }
}
```

#### 2. 自动格式化

```json
{
  "hooks": {
    "afterEdit": {
      "command": "npx",
      "args": ["prettier", "--write", "{{filepath}}"],
      "runInBackground": true
    }
  }
}
```

#### 3. 运行测试

```json
{
  "hooks": {
    "afterEdit": {
      "command": "npm",
      "args": ["test", "--", "--related", "{{filepath}}"],
      "runInBackground": true
    }
  }
}
```

#### 4. Git Commit

```json
{
  "hooks": {
    "afterEdit": {
      "command": "git",
      "args": ["add", "{{filepath}}"],
      "runInBackground": false
    }
  }
}
```

#### 5. 发送通知

```json
{
  "hooks": {
    "afterCommand": {
      "command": "notify-send",
      "args": ["Claude Code", "Command completed"],
      "runInBackground": true
    }
  }
}
```

### 高级 Hooks

### 条件 Hooks

只在特定条件下执行：

```json
{
  "hooks": {
    "beforeEdit": {
      "command": "check-and-backup.sh",
      "args": ["{{filepath}}"],
      "condition": {
        "fileExtension": ["js", "ts", "jsx", "tsx"]
      }
    }
  }
}
```

### 链式 Hooks

一个 Hook 触发另一个：

```bash
#!/bin/bash
# chain-hook.sh

# 第一个 Hook
cp "$1" "$1.bak"

# 触发下一个 Hook
npx prettier --write "$1"
```

```json
{
  "hooks": {
    "afterEdit": {
      "command": "./chain-hook.sh",
      "args": ["{{filepath}}"]
    }
  }
}
```

### 异步 Hooks

后台运行的 Hook：

```json
{
  "hooks": {
    "afterEdit": {
      "command": "long-running-task.sh",
      "args": ["{{filepath}}"],
      "runInBackground": true,
      "timeout": 300000
    }
  }
}
```

### Hook 最佳实践

1. **快速执行**
   - Hook 应该快速完成
   - 长时间任务在后台运行
   - 设置合理的超时

2. **错误处理**
   - Hook 失败不应阻止主操作
   - 记录错误日志
   - 提供重试机制

3. **性能考虑**
   - 避免重复操作
   - 使用缓存
   - 批量处理

4. **调试**
   - 添加日志输出
   - 测试 Hook 脚本
   - 检查执行结果

---

## 高级配置

### 环境变量

在 `.claude/config.json` 中设置环境变量：

```json
{
  "env": {
    "MY_API_KEY": "your_key_here",
    "DATABASE_URL": "postgresql://localhost/mydb",
    "NODE_ENV": "development"
  }
}
```

### 模型选择

为不同任务选择合适的模型：

```json
{
  "models": {
    "default": "sonnet",
    "code": "opus",
    "chat": "haiku",
    "review": "sonnet"
  }
}
```

### 工具权限

精确控制可用工具：

```json
{
  "allowedTools": {
    "Read": true,
    "Write": true,
    "Edit": true,
    "Bash": {
      "enabled": true,
      "allowedCommands": ["git", "npm", "ls", "cat"]
    }
  }
}
```

### 内存管理

配置会话记忆：

```json
{
  "memory": {
    "enabled": true,
    "maxSize": "1MB",
    "retentionDays": 30
  }
}
```

---

## 性能优化

### 1. 减少 Token 使用

**策略**：
- 使用 Plan Mode 进行只读操作
- 定期 `/clear` 清理上下文
- 使用精确的文件路径
- 避免读取整个目录

**示例**：
```
❌ 读取整个项目
✅ 只读取需要的文件
```

### 2. 优化 MCP Servers

**策略**：
- 缓存频繁查询的资源
- 使用增量更新
- 限制返回数据量
- 选择合适的通信方式

**示例**：
```python
# ❌ 每次都查询所有数据
@app.resource("data://all")
async def get_all_data():
    return json.dumps(db.query("SELECT * FROM huge_table"))

# ✅ 只返回需要的数据
@app.resource("data://recent")
async def get_recent_data():
    return json.dumps(db.query("SELECT * FROM table LIMIT 10"))
```

### 3. 优化 Hooks

**策略**：
- 后台运行长时间任务
- 避免阻塞主流程
- 批量处理操作

**示例**：
```json
{
  "hooks": {
    "afterEdit": {
      "command": "format-and-test.sh",
      "runInBackground": true
    }
  }
}
```

---

## 故障排查

### MCP 连接问题

**问题**：MCP Server 无法连接

**解决**：
```bash
# 1. 检查配置
cat .claude/config.json

# 2. 测试 MCP Server
npx -y @modelcontextprotocol/server-filesystem /tmp

# 3. 查看日志
tail -f ~/.claude/logs/mcp.log

# 4. 重启 Claude Code
```

### Skill 不生效

**问题**：Skill 没有被加载

**解决**：
```bash
# 1. 检查 Skill 语法
cat ~/.claude/skills/my-skill.md

# 2. 列出所有 Skills
/agents

# 3. 重新加载 Skill
# 退出并重新启动 Claude Code
```

### Hook 失败

**问题**：Hook 执行失败

**解决**：
```bash
# 1. 测试 Hook 脚本
bash -x hook-script.sh

# 2. 检查权限
ls -la .claude/hooks.json

# 3. 查看错误日志
cat ~/.claude/logs/hooks.log

# 4. 手动执行
cp test.txt test.txt.bak
```

### 性能问题

**问题**：Claude Code 运行缓慢

**解决**：
```
1. /clear 清理上下文
2. 关闭不需要的 MCP Servers
3. 使用更快的模型（sonnet vs opus）
4. 优化 Hook 配置
5. 检查网络连接
```

---

## 总结

### MCP
- ✅ 连接外部工具和数据源
- ✅ 扩展 Claude 的能力
- ✅ 支持自定义服务器

### Skills
- ✅ 可重用的提示词模板
- ✅ 专业化的工作流程
- ✅ 提高工作效率

### Hooks
- ✅ 自动化工作流程
- ✅ 自定义行为
- ✅ 集成现有工具

---

## 相关资源

### 官方文档
- [MCP 规范](https://modelcontextprotocol.io)
- [Claude Code 文档](https://code.claude.com/docs/en/overview)

### 社区
- [MCP Servers 仓库](https://github.com/modelcontextprotocol)
- [Claude Code Discord](https://discord.gg/clawd)

### 示例
- [MCP Server 示例](https://github.com/modelcontextprotocol/servers)
- [Skills 示例](https://github.com/anthropics/claude-code/tree/main/skills)

---

*基于 Claude Code v2.1.63 和官方文档整理*
