# Scripts - 自动化脚本工具

本目录包含用于简化编译和运行的自动化脚本。

---

## 📜 可用脚本

### 1. `install.sh` - 从零开始的一键安装(🌟 强烈推荐新手)

**功能:**
- ✅ 自动检查并安装所有依赖(Xcode CLI, Homebrew, XcodeGen)
- ✅ 交互式向导,每步都有清晰提示
- ✅ 预计耗时显示,让用户心里有数
- ✅ 适合完全没接触过 iOS 开发的用户

**用法:**

```bash
# 克隆仓库后,直接运行
git clone https://github.com/JacquelineZhou53/BassGuitarPractice.git
cd BassGuitarPractice
chmod +x scripts/install.sh
./scripts/install.sh
```

**执行流程:**
```
Step 1/6: 检查 macOS 版本
Step 2/6: 检查 Xcode Command Line Tools → 未安装则自动安装
Step 3/6: 检查 Homebrew → 未安装则自动安装
Step 4/6: 安装 XcodeGen → 未安装则自动安装
Step 5/6: 生成 Xcode 项目
Step 6/6: 检测模拟器并构建启动
```

**适用人群:** 第一次接触此项目的新手用户

---

### 2. `run.sh` - 完整的一键编译运行脚本

**功能:**
- ✅ 自动检查 Xcode 和 XcodeGen 是否安装
- ✅ 自动生成 Xcode 项目
- ✅ 智能选择模拟器或真机
- ✅ 构建并启动应用
- ✅ 彩色输出,友好的错误提示

**用法:**

```bash
# 赋予执行权限(仅需一次)
chmod +x scripts/run.sh

# 在模拟器上运行(默认)
./scripts/run.sh

# 或指定模式
./scripts/run.sh simulator    # 在模拟器运行
./scripts/run.sh device       # 在真机运行
./scripts/run.sh clean        # 清理构建缓存
./scripts/run.sh help         # 显示帮助
```

**适用人群:** 所有用户,特别是命令行新手

---

### 3. `quickstart.sh` - 超快速启动脚本

**功能:**
- ⚡ 跳过检查,直接构建运行
- ⚡ 适合已经配置好环境的用户
- ⚡ 更少的输出,更快的速度

**用法:**

```bash
chmod +x scripts/quickstart.sh
./scripts/quickstart.sh
```

**适用人群:** 有经验的开发者,日常快速启动

---

## 🚀 使用示例

### 场景 1: 首次克隆项目

```bash
# 1. 克隆仓库
git clone https://github.com/JacquelineZhou53/BassGuitarPractice.git
cd BassGuitarPractice

# 2. 运行一键脚本
./scripts/run.sh

# 脚本会自动:
# - 检查 Xcode 是否安装
# - 安装 XcodeGen(如果需要)
# - 生成 Xcode 项目
# - 选择模拟器
# - 构建并启动应用
```

### 场景 2: 日常开发

```bash
# 修改代码后,快速重新构建
./scripts/quickstart.sh

# 或清理后重新构建
./scripts/run.sh clean
./scripts/run.sh
```

### 场景 3: 在真机上测试

```bash
# 连接 iPhone/iPad 后
./scripts/run.sh device
```

---

## 🔧 故障排除

### 问题 1: "Permission denied"

**解决:**
```bash
chmod +x scripts/run.sh
chmod +x scripts/quickstart.sh
```

### 问题 2: "xcodegen: command not found"

**解决:**
```bash
# run.sh 会自动安装,或手动安装:
brew install xcodegen
```

### 问题 3: "No iOS 17+ simulator found"

**解决:**
1. 打开 Xcode
2. Xcode → Settings → Components
3. 下载 iOS 17.x Simulator
4. 重新运行脚本

### 问题 4: 构建失败

**解决:**
```bash
# 清理后重试
./scripts/run.sh clean
./scripts/run.sh

# 或手动清理
rm -rf build/ .build/
xcodebuild clean -project BassGuitarPractice.xcodeproj -scheme BassGuitarPractice
```

---

## 💡 高级用法

### 自定义模拟器

编辑 `run.sh`,修改这一行:

```bash
local preferred_name="iPhone 16 Pro"  # 改为你喜欢的设备
```

可选值:
- `iPhone 16 Pro`
- `iPhone 15 Pro`
- `iPhone SE (3rd generation)`
- `iPad Air (5th generation)`

### 查看详细日志

```bash
# 显示 xcodebuild 详细输出
./scripts/run.sh 2>&1 | tee build.log
```

### 仅构建不运行

```bash
# 修改 run.sh,注释掉 launch_simulator 调用
# 或直接运行:
xcodebuild -project BassGuitarPractice.xcodeproj \
    -scheme BassGuitarPractice \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    build
```

---

## 📝 脚本说明

### run.sh 工作流程

```
1. 解析命令行参数
2. 检查 Xcode 是否安装 → 未安装则报错
3. 检查 XcodeGen 是否安装 → 未安装则自动安装
4. 生成 Xcode 项目 (xcodegen generate)
5. 检测可用的模拟器
6. 选择首选模拟器(iPhone 16 Pro)
7. 构建应用 (xcodebuild)
8. 启动模拟器
9. 安装并启动应用
```

### quickstart.sh 工作流程

```
1. 检查 project.yml 是否存在
2. 生成项目(如果不存在)
3. 查找模拟器 UUID
4. 构建应用
5. 启动应用
```

---

## 🆘 获取帮助

如果脚本运行失败:

1. **查看详细错误信息:**
   ```bash
   ./scripts/run.sh 2>&1 | tail -50
   ```

2. **手动执行每一步:**
   ```bash
   # Step 1: 生成项目
   xcodegen generate
   
   # Step 2: 列出模拟器
   xcrun simctl list devices available
   
   # Step 3: 手动构建
   xcodebuild -project BassGuitarPractice.xcodeproj \
     -scheme BassGuitarPractice \
     -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
     build
   ```

3. **查看系统日志:**
   ```bash
   log show --predicate 'process == "xcodebuild"' --last 5m
   ```

4. **提交 Issue:**
   - 附上完整的错误输出
   - 说明 macOS 和 Xcode 版本
   - 说明是模拟器还是真机

---

## 🎯 最佳实践

### 推荐的工作流

```bash
# 早晨开始工作时
./scripts/run.sh clean    # 清理缓存

# 每次修改代码后
./scripts/quickstart.sh   # 快速重新构建

# 测试前
./scripts/run.sh          # 完整流程

# 遇到问题时
./scripts/run.sh clean && ./scripts/run.sh  # 核弹级清理
```

### 配合 Xcode 使用

```bash
# 用脚本快速验证构建
./scripts/quickstart.sh

# 然后在 Xcode 中调试
open BassGuitarPractice.xcodeproj
```

---

**祝编码愉快! 🎸**
