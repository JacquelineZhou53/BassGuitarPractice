#!/bin/bash

# BassPractice - 从零开始的一键安装脚本
# 适合完全新手的用户,自动完成所有步骤

set -e

echo "=========================================="
echo "  🎸 BassPractice 一键安装向导"
echo "=========================================="
echo ""
echo "此脚本将:"
echo "  ✓ 检查并安装 Xcode Command Line Tools"
echo "  ✓ 安装 Homebrew(如果未安装)"
echo "  ✓ 安装 XcodeGen"
echo "  ✓ 生成 Xcode 项目"
echo "  ✓ 构建并启动应用"
echo ""
echo "预计耗时: 10-30 分钟(取决于网络和电脑性能)"
echo ""

# 询问用户是否继续
read -p "是否继续? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

echo ""
echo "Step 1/6: 检查 macOS 版本..."
macos_version=$(sw_vers -productVersion | cut -d. -f1)
if [ "$macos_version" -lt 13 ]; then
    echo "❌ 需要 macOS 13.0 或更高版本"
    echo "   当前版本: $(sw_vers -productVersion)"
    exit 1
fi
echo "✅ macOS $macos_version 符合要求"

echo ""
echo "Step 2/6: 检查 Xcode Command Line Tools..."
if xcode-select -p &> /dev/null; then
    echo "✅ Command Line Tools 已安装"
else
    echo "⚠️  正在安装 Command Line Tools...(需要几分钟)"
    xcode-select --install
    echo "✅ 安装完成"
fi

echo ""
echo "Step 3/6: 检查 Homebrew..."
if command -v brew &> /dev/null; then
    echo "✅ Homebrew 已安装"
else
    echo "⚠️  正在安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo "✅ Homebrew 安装完成"
fi

echo ""
echo "Step 4/6: 安装 XcodeGen..."
if command -v xcodegen &> /dev/null; then
    echo "✅ XcodeGen 已安装 (v$(xcodegen --version))"
else
    echo "⚠️  正在安装 XcodeGen..."
    brew install xcodegen
    echo "✅ XcodeGen 安装完成 (v$(xcodegen --version))"
fi

echo ""
echo "Step 5/6: 生成 Xcode 项目..."
if [ -d "BassPractice.xcodeproj" ]; then
    echo "✅ 项目已存在,跳过生成"
else
    xcodegen generate
    echo "✅ 项目生成成功"
fi

echo ""
echo "Step 6/6: 检测模拟器..."
simulator_uuid=$(xcrun simctl list devices available | grep "iPhone 16 Pro" | grep -E "iOS 1[7-9]" | head -1 | grep -oE '\([A-F0-9-]+\)' | tr -d '()')

if [ -z "$simulator_uuid" ]; then
    echo "⚠️  未找到 iPhone 16 Pro 模拟器"
    simulator_uuid=$(xcrun simctl list devices available | grep "iPhone" | grep -E "iOS 1[7-9]" | head -1 | grep -oE '\([A-F0-9-]+\)' | tr -d '()')
    
    if [ -z "$simulator_uuid" ]; then
        echo "❌ 未找到可用的 iOS 17+ 模拟器"
        echo ""
        echo "请手动安装:"
        echo "  1. 打开 Xcode"
        echo "  2. Xcode → Settings → Components"
        echo "  3. 下载 iOS 17.x Simulator"
        echo "  4. 重新运行此脚本"
        echo ""
        exit 1
    fi
fi

echo "✅ 找到模拟器"

echo ""
echo "=========================================="
echo "  环境准备完成!开始构建..."
echo "=========================================="
echo ""

# 构建
xcodebuild -project BassPractice.xcodeproj \
    -scheme BassPractice \
    -destination "platform=iOS Simulator,id=$simulator_uuid" \
    build

echo ""
echo "✅ 构建成功!"

# 启动
echo "🚀 启动应用..."
xcrun simctl boot "$simulator_uuid" 2>/dev/null || true
sleep 2

app_path=$(find build -name "BassPractice.app" -type d | head -1)
if [ -n "$app_path" ]; then
    xcrun simctl install "$simulator_uuid" "$app_path"
    xcrun simctl launch "$simulator_uuid" com.basspractice.app
    echo ""
    echo "=========================================="
    echo "  🎉 安装成功!"
    echo "=========================================="
    echo ""
    echo "应用已在模拟器中启动"
    echo ""
    echo "下次运行时,只需执行:"
    echo "  ./scripts/quickstart.sh"
    echo ""
else
    echo "⚠️  构建成功但未找到应用文件"
    echo "请在 Xcode 中手动运行: open BassPractice.xcodeproj"
fi
