#!/bin/bash

# 快速重新编译并运行到模拟器

set -e

echo "🔨 开始编译 BassPractice..."

# 进入项目目录
cd "/Users/coco_j/Documents/GameHacker/Bass Practice"

# 清理旧的构建(可选,如果遇到问题可以取消注释)
# rm -rf build/

# 编译项目
echo "📦 编译中..."
xcodebuild -project BassPractice.xcodeproj \
    -scheme BassPractice \
    -sdk iphonesimulator \
    build 2>&1 | grep -E "(BUILD|error:|warning:)" | tail -20

echo ""
echo "✅ 编译完成!"

# 查找构建产物
APP_PATH=$(find build -name "BassPractice.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ 未找到 .app 文件"
    echo "请检查编译输出"
    exit 1
fi

echo "📱 找到应用: $APP_PATH"

# 获取模拟器 UUID
echo "🔍 查找 iPhone 17 Pro 模拟器..."
SIMULATOR_UUID=$(xcrun simctl list devices available | grep "iPhone 17 Pro" | head -1 | grep -oE '\([A-F0-9-]+\)' | tr -d '()')

if [ -z "$SIMULATOR_UUID" ]; then
    echo "⚠️  未找到 iPhone 17 Pro,尝试使用第一个可用的 iPhone 模拟器"
    SIMULATOR_UUID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | grep -oE '\([A-F0-9-]+\)' | tr -d '()')
fi

if [ -z "$SIMULATOR_UUID" ]; then
    echo "❌ 未找到可用的 iOS 17+ 模拟器"
    echo "请在 Xcode 中安装: Xcode → Settings → Components"
    exit 1
fi

echo "✅ 使用模拟器: $SIMULATOR_UUID"

# 启动模拟器(如果还没启动)
echo "🚀 启动模拟器..."
xcrun simctl boot "$SIMULATOR_UUID" 2>/dev/null || true

# 等待模拟器就绪
sleep 2

# 安装应用
echo "📲 安装应用..."
xcrun simctl install "$SIMULATOR_UUID" "$APP_PATH"

# 启动应用
echo "▶️  启动应用..."
xcrun simctl launch "$SIMULATOR_UUID" com.basspractice.app

echo ""
echo "🎉 完成!应用已在模拟器中运行"
echo ""
echo "提示:"
echo "  - 查看日志: xcrun simctl spawn booted log stream --predicate 'processImagePath contains \"BassPractice\"'"
echo "  - 停止应用: xcrun simctl terminate $SIMULATOR_UUID com.basspractice.app"
echo "  - 卸载应用: xcrun simctl uninstall $SIMULATOR_UUID com.basspractice.app"
