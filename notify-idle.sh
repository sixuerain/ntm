#!/bin/bash
# notify-idle.sh — 当目标 pane 的输出停止变化（agent 空闲）时通知用户
# 用法: notify-idle.sh [session:pane] [client_tty]
# 机制: 连续 3 次采样输出完全一致（约 60s）即判定完成，弹通知 + 响铃后退出。

TMUX=/usr/local/bin/tmux
TARGET="${1:-research:0}"
CLIENT="${2:-$($TMUX list-clients -F '#{client_name}' 2>/dev/null | head -1)}"
PREV=""
STABLE=0

echo "watching $TARGET (notify -> $CLIENT)"
while true; do
  CUR=$($TMUX capture-pane -p -t "$TARGET" 2>/dev/null | tail -8)
  if [ -z "$CUR" ]; then
    # pane 消失（session 被清）也算结束
    $TMUX display-message -c "$CLIENT" " flew away: $TARGET pane gone" 2>/dev/null
    exit 0
  fi
  if [ "$CUR" == "$PREV" ]; then
    STABLE=$((STABLE + 1))
  else
    STABLE=0
  fi
  PREV="$CUR"
  if [ $STABLE -ge 3 ]; then
    $TMUX display-message -c "$CLIENT" "✅ 后台任务完成: $TARGET (ncheck 查看)" 2>/dev/null
    printf '\a' > "$CLIENT" 2>/dev/null
    exit 0
  fi
  sleep 20
done
