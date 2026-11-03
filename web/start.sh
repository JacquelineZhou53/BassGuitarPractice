#!/bin/bash

# 贝斯/吉他练习网页应用 - 启动脚本

PORT=8081
WEB_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🎸 贝斯/吉他练习网页应用"
echo "========================"
echo ""
echo "启动本地服务器..."
echo "访问地址: http://localhost:$PORT"
echo ""
echo "按 Ctrl+C 停止服务器"
echo ""

# 检查端口是否被占用
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  端口 $PORT 已被占用，尝试使用端口 $((PORT+1))"
    PORT=$((PORT+1))
    echo "访问地址: http://localhost:$PORT"
    echo ""
fi

# 启动 HTTP 服务器
cd "$WEB_DIR"
python3 -m http.server $PORT
