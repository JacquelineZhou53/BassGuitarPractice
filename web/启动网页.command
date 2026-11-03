#!/bin/bash

# 贝斯/吉他练习网页应用 - macOS 双击启动脚本

PORT=8081
WEB_DIR="$(cd "$(dirname "$0")" && pwd)"

# 检查端口是否被占用
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    PORT=$((PORT+1))
fi

# 在浏览器中打开
open "http://localhost:$PORT"

# 启动 HTTP 服务器
cd "$WEB_DIR"
python3 -m http.server $PORT
