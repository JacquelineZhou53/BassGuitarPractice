#!/bin/bash

# BassPractice - 超快速启动脚本
# 适合已经安装好 Xcode 和 XcodeGen 的用户

set -e

echo "🎸 快速启动 BassPractice..."

# 检查是否在正确的目录
if [ ! -f "project.yml" ]; then
    echo "❌ 错误: 未找到 project.yml,请在项目根目录运行此脚本"
    exit 1
fi

# 生成项目(如果不存在)
if [ ! -d "BassPractice.xcodeproj" ]; then
    echo "📦 生成 Xcode 项目..."
    xcodegen generate
fi

# 选择模拟器
echo "🔍 查找 iPhone 16 Pro 模拟器..."
SIMULATOR_UUID=$(xcrun simctl list devices available | grep "iPhone 16 Pro" | grep -E "iOS 1[7-9]" | head -1 | grep -oE '\([A-F0-9-]+\)' | tr -d '()')

if [ -z "$SIMULATOR_UUID" ]; then
    echo "⚠️  未找到 iPhone 16 Pro,使用第一个可用的 iPhone 模拟器"
    SIMULATOR_UUID=$(xcrun simctl list devices available | grep "iPhone" | grep -E "iOS 1[7-9]" | head -1 | grep -oE '\([A-F0-9-]+\)' | tr -d '()')
fi

if [ -z "$SIMULATOR_UUID" ]; then
    echo "❌ 未找到可用的 iOS 17+ 模拟器"
    echo "请在 Xcode 中安装: Xcode → Settings → Components"
    exit 1
fi

echo "✅ 使用模拟器 UUID: $SIMULATOR_UUID"

# 构建
echo "🔨 开始构建...(首次构建可能需要几分钟)"
xcodebuild -project BassPractice.xcodeproj \
    -scheme BassPractice \
    -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
    build

# 启动
echo "🚀 启动模拟器并安装应用..."
xcrun simctl boot "$SIMULATOR_UUID" 2>/dev/null || true
sleep 2

APP_PATH=$(find build -name "BassPractice.app" -type d | head -1)
if [ -n "$APP_PATH" ]; then
    xcrun simctl install "$SIMULATOR_UUID" "$APP_PATH"
    xcrun simctl launch "$SIMULATOR_UUID" com.basspractice.app
    echo "🎉 完成!应用已启动"
else
    echo "⚠️  构建成功但未找到 .app 文件"
    echo "请手动在 Xcode 中运行,或检查 build 目录"
fi
