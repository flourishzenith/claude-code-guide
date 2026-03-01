#!/bin/bash
# Claude Code Guide 自动更新脚本
# 监控文档变更并自动提交到 GitHub

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$SCRIPT_DIR/../logs/auto-update.log"
SOURCE_DIR="$HOME/.openclaw/workspace/projects/claude-code-guide"

# 创建日志目录
mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "🚀 开始检查更新..."

# 检查是否有变更
cd "$PROJECT_DIR"

# 检查 Git 状态
if git diff --quiet && git diff --cached --quiet; then
    log "✅ 没有变更，无需提交"
    exit 0
fi

# 显示变更
log "📝 检测到文件变更："
git status --short | tee -a "$LOG_FILE"

# 添加所有变更
git add . || {
    log "❌ Git add 失败"
    exit 1
}

# 提交变更
COMMIT_MSG="📚 自动更新文档 $(date '+%Y-%m-%d %H:%M:%S')

- 更新 Claude Code 功能文档
- 同步最新社区案例
- 更新监控脚本"

git commit -m "$COMMIT_MSG" || {
    log "❌ Git commit 失败"
    exit 1
}

log "✅ 变更已提交"

# 推送到 GitHub
git push origin main || {
    log "❌ Git push 失败"
    exit 1
}

log "🎉 已推送到 GitHub"
log "✅ 更新完成"
