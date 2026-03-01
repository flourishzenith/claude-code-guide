#!/bin/bash
# Claude Code Guide 同步脚本
# 监控源文档变更并同步到 GitHub 仓库

set -e

SOURCE_DIR="$HOME/.openclaw/workspace/projects/claude-code-guide"
TARGET_DIR="$HOME/.openclaw/workspace/projects/claude-code-guide.github"
LOG_FILE="$TARGET_DIR/logs/sync.log"

# 创建日志目录
mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "🔄 开始同步文档..."

# 检查源目录
if [ ! -d "$SOURCE_DIR" ]; then
    log "❌ 源目录不存在: $SOURCE_DIR"
    exit 1
fi

# 进入目标目录
cd "$TARGET_DIR" || exit 1

# 复制文档文件
log "📄 复制文档..."

# 复制主文档（如果源文件更新）
if [ "$SOURCE_DIR/README.md" -nt "$TARGET_DIR/docs/source-readme.md" ]; then
    cp "$SOURCE_DIR/README.md" "$TARGET_DIR/docs/source-readme.md"
    log "✅ 更新 source-readme.md"
fi

# 检查是否有文件变更
if git diff --quiet && git diff --cached --quiet; then
    log "✅ 没有变更，无需提交"
    exit 0
fi

# 显示变更
log "📝 检测到变更："
git status --short | tee -a "$LOG_FILE"

# 添加变更
git add . || {
    log "❌ Git add 失败"
    exit 1
}

# 提交变更
COMMIT_MSG="📚 自动同步文档 $(date '+%Y-%m-%d %H:%M:%S')

- 同步源文档变更
- 更新项目内容"

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
log "✅ 同步完成"
