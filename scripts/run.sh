#!/bin/bash

# BassPractice - 一键编译运行脚本
# 用法: ./scripts/run.sh [simulator|device|clean]

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 未安装"
        return 1
    fi
    return 0
}

# 显示帮助信息
show_help() {
    cat << EOF
🎸 BassPractice - 一键编译运行脚本

用法: $0 [选项]

选项:
  simulator     在模拟器上运行(默认)
  device        在真机上运行
  clean         清理构建缓存后运行
  help          显示此帮助信息

示例:
  $0                    # 在默认模拟器运行
  $0 simulator          # 在 iPhone 16 Pro 模拟器运行
  $0 device             # 在连接的 iPhone 运行
  $0 clean              # 清理后重新构建

EOF
}

# 检测可用的模拟器
detect_simulators() {
    print_info "检测可用的模拟器..."
    
    # 列出 iOS 17+ 的 iPhone 模拟器
    simulators=$(xcrun simctl list devices available | grep "iPhone" | grep -E "iOS 1[7-9]|iOS 2[0-9]" | head -5)
    
    if [ -z "$simulators" ]; then
        print_error "未找到可用的 iOS 17+ 模拟器"
        print_info "请在 Xcode 中安装 iOS 17+ 模拟器:"
        print_info "Xcode → Settings → Components → iOS 17.x Simulator"
        exit 1
    fi
    
    echo "$simulators"
}

# 选择或创建模拟器
select_simulator() {
    local preferred_name="iPhone 16 Pro"
    
    # 查找首选模拟器
    simulator=$(xcrun simctl list devices available | grep "$preferred_name" | grep -E "iOS 1[7-9]|iOS 2[0-9]" | head -1)
    
    if [ -z "$simulator" ]; then
        print_warning "未找到 $preferred_name,使用第一个可用的 iPhone 模拟器"
        simulator=$(detect_simulators | head -1)
    fi
    
    # 提取 UUID
    uuid=$(echo "$simulator" | grep -oE '\([A-F0-9-]+\)' | tr -d '()')
    name=$(echo "$simulator" | cut -d'(' -f1 | sed 's/ *$//')
    
    print_success "选择模拟器: $name (UUID: $uuid)"
    echo "$uuid"
}

# 检查 Xcode 是否安装
check_xcode() {
    print_info "检查 Xcode..."
    
    if ! check_command xcodebuild; then
        print_error "Xcode 未安装或未配置命令行工具"
        print_info "请执行以下命令安装:"
        echo "  xcode-select --install"
        exit 1
    fi
    
    xcode_version=$(xcodebuild -version | head -1)
    print_success "Xcode 已安装: $xcode_version"
}

# 检查 XcodeGen
check_xcodegen() {
    print_info "检查 XcodeGen..."
    
    if ! check_command xcodegen; then
        print_warning "XcodeGen 未安装,正在安装..."
        
        if ! check_command brew; then
            print_error "Homebrew 未安装"
            print_info "请访问 https://brew.sh 安装 Homebrew"
            exit 1
        fi
        
        brew install xcodegen
        print_success "XcodeGen 安装完成"
    else
        xcodegen_version=$(xcodegen --version)
        print_success "XcodeGen 已安装: v$xcodegen_version"
    fi
}

# 生成 Xcode 项目
generate_project() {
    print_info "生成 Xcode 项目..."
    
    if [ ! -f "project.yml" ]; then
        print_error "未找到 project.yml 文件"
        print_info "请确保在项目根目录运行此脚本"
        exit 1
    fi
    
    xcodegen generate
    
    if [ ! -d "BassPractice.xcodeproj" ]; then
        print_error "项目生成失败"
        exit 1
    fi
    
    print_success "Xcode 项目生成成功"
}

# 清理构建
clean_build() {
    print_info "清理构建缓存..."
    
    # 清理 Xcode 构建
    if [ -d "BassPractice.xcodeproj" ]; then
        xcodebuild clean -project BassPractice.xcodeproj -scheme BassPractice > /dev/null 2>&1 || true
    fi
    
    # 删除构建文件夹
    rm -rf build/
    
    # 清理 Swift 包缓存
    rm -rf .build/
    
    # 清理 macOS 隐藏文件
    find . -name ".DS_Store" -delete 2>/dev/null || true
    
    print_success "清理完成"
}

# 构建到模拟器
build_for_simulator() {
    local simulator_uuid=$1
    
    print_info "开始构建到模拟器..."
    print_info "这可能需要几分钟时间(首次构建较慢)..."
    
    xcodebuild -project BassPractice.xcodeproj \
        -scheme BassPractice \
        -destination "platform=iOS Simulator,id=$simulator_uuid" \
        build
    
    print_success "构建成功!"
}

# 构建到真机
build_for_device() {
    print_info "检测连接的设备..."
    
    # 获取连接的第一个设备 UDID
    device_udid=$(idevice_id -l 2>/dev/null | head -1)
    
    if [ -z "$device_udid" ]; then
        # 尝试通过 xcrun 检测
        device_udid=$(xcrun simctl list devices connected | grep -oE '\([A-F0-9-]+\)' | tr -d '()' | head -1)
    fi
    
    if [ -z "$device_udid" ]; USB-C ; then
        print_error "未检测到连接的设备"
        print_info "请:"
        print_info "1. 用数据线连接 iPhone/iPad"
        print_info "2. 解锁设备并点击'信任此电脑'"
        print_info "3. 在 Xcode 中验证设备可见: Window → Devices and Simulators"
        exit 1
    fi
    
    print_success "检测到设备 (UDID: $device_udid)"
    
    print_info "开始构建到真机..."
    
    xcodebuild -project BassPractice.xcodeproj \
        -scheme BassPractice \
        -destination "platform=iOS,id=$device_udid" \
        build
    
    print_success "构建成功!"
}

# 启动模拟器
launch_simulator() {
    local simulator_uuid=$1
    
    print_info "启动模拟器..."
    
    # 确保模拟器已启动
    xcrun simctl boot "$simulator_uuid" 2>/dev/null || true
    
    # 等待模拟器就绪
    sleep 3
    
    # 安装应用
    app_path=$(find build -name "BassPractice.app" -type d | head -1)
    
    if [ -z "$app_path" ]; then
        print_error "未找到构建的应用"
        exit 1
    fi
    
    xcrun simctl install "$simulator_uuid" "$app_path"
    
    # 启动应用
    xcrun simctl launch "$simulator_uuid" com.basspractice.app
    
    print_success "应用已启动!"
    print_info "如需查看日志,运行:"
    echo "  xcrun simctl spawn booted log stream --predicate 'processImagePath contains \"BassPractice\"'"
}

# 主函数
main() {
    local mode=${1:-simulator}
    
    echo ""
    echo "=========================================="
    echo "  🎸 BassPractice 一键编译运行"
    echo "=========================================="
    echo ""
    
    case "$mode" in
        help|-h|--help)
            show_help
            exit 0
            ;;
        clean)
            check_xcode
            check_xcodegen
            clean_build
            generate_project
            print_success "清理完成!现在可以重新运行: $0"
            exit 0
            ;;
        simulator)
            check_xcode
            check_xcodegen
            generate_project
            
            simulator_uuid=$(select_simulator)
            build_for_simulator "$simulator_uuid"
            launch_simulator "$simulator_uuid"
            
            print_success "🎉 完成!应用已在模拟器中运行"
            ;;
        device)
            check_xcode
            check_xcodegen
            generate_project
            
            build_for_device
            print_success "🎉 构建完成!请在设备上查看应用"
            print_warning "注意: 免费账号签名的应用 7 天后过期"
            ;;
        *)
            print_error "未知选项: $mode"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
