# 自编译快速上手指南

本指南面向**没有 iOS 开发经验**的用户,帮助你从零开始在 iPhone/iPad 上安装 BassPractice。

---

## 📋 前置条件

### 你必须拥有:
- ✅ **一台 Mac 电脑**(MacBook/iMac/Mac mini,macOS 13.0+)
- ✅ **Apple ID**(免费注册,用于 Xcode 签名)
- ✅ **USB-C 或 Lightning 数据线**(用于连接 iPhone/iPad)
- ✅ **iPhone/iPad**(iOS 17.0+,用于安装测试)

### 可选但推荐:
- 稳定的网络连接(下载 Xcode 约 12GB)
- 2-3 小时空闲时间(首次设置)

---

## 🚀 Step-by-Step 教程

### Step 1: 安装 Xcode (约 30-60 分钟)

#### 方法 A: Mac App Store(推荐新手)

1. 打开 **App Store**
2. 搜索 "Xcode"
3. 点击 **"获取"** → 输入 Apple ID 密码
4. 等待下载完成(12GB,视网速而定)
5. 自动安装到 `/Applications/Xcode.app`

#### 方法 B: 开发者网站下载

如果 App Store 速度慢:

1. 访问 [developer.apple.com/download](https://developer.apple.com/download/)
2. 用 Apple ID 登录
3. 搜索 "Xcode 15"
4. 下载 `.xip` 文件
5. 双击解压,拖到 `Applications` 文件夹

**验证安装:**
```bash
xcodebuild -version
# 应该输出: Xcode 15.x.x ...
```

---

### Step 2: 安装命令行工具

打开 **终端**(Applications → Utilities → Terminal),输入:

```bash
xcode-select --install
```

点击弹窗中的 **"安装"**,等待完成(约 5 分钟)。

---

### Step 3: 克隆项目代码

#### 如果你会用 Git:

```bash
# 在桌面创建文件夹
cd ~/Desktop
git clone https://github.com/YOUR_USERNAME/BassPractice.git
cd BassPractice
```

#### 如果你不会用 Git:

1. 访问项目的 GitHub 页面
2. 点击绿色 **"Code"** 按钮
3. 选择 **"Download ZIP"**
4. 解压到桌面,重命名为 `BassPractice`

---

### Step 4: 安装 XcodeGen(一次性操作)

在终端中执行:

```bash
# 安装 Homebrew(如果还没安装)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 XcodeGen
brew install xcodegen
```

**验证:**
```bash
xcodegen --version
# 应该输出版本号,如: 2.42.0
```

---

### Step 5: 生成 Xcode 项目

在终端中进入项目目录:

```bash
cd ~/Desktop/BassPractice  # 根据你的实际路径调整
xcodegen generate
```

成功后会看到:
```
✨ Generated project at BassPractice.xcodeproj
```

---

### Step 6: 配置 Xcode

1. **打开项目**:
   ```bash
   open BassPractice.xcodeproj
   ```
   或双击 Finder 中的 `BassPractice.xcodeproj`

2. **首次启动 Xcode**:
   - 接受许可协议
   - 选择 "Skip for now"(跳过组件安装)

3. **添加 Apple ID**:
   - Xcode → Settings(或 Preferences)
   - 点击 **"Accounts"** 标签
   - 点击左下角 **"+"** → **"Add Apple ID..."**
   - 输入你的 Apple ID 和密码
   - 选择 **"Personal Team"**(免费)

4. **选择签名团队**:
   - 左侧项目导航器选中 **BassPractice**(蓝色图标)
   - 右侧选择 **"Signing & Capabilities"** 标签
   - Team 下拉框选择你的 **Personal Team**
   - Bundle Identifier 保持 `com.basspractice.app`

---

### Step 7: 模拟器测试(无需真机)

#### 在 Xcode 中运行:

1. 顶部工具栏选择设备:
   - 点击设备下拉框(显示 "BassPractice" 旁边)
   - 选择 **"iPhone 16 Pro"** 或其他模拟器

2. 点击左上角 **▶️ Run** 按钮(或按 `Cmd+R`)

3. 等待构建(首次约 2-5 分钟)

4. 模拟器自动启动并显示应用!

#### 或用命令行:

```bash
# 列出可用模拟器
xcrun simctl list devices available | grep iPhone

# 构建并运行
xcodebuild -project BassPractice.xcodeproj \
  -scheme BassPractice \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build run
```

---

### Step 8: 真机安装(推荐)

#### 准备工作:

1. **解锁 iPhone/iPad**
2. **用数据线连接 Mac**
3. **手机上弹出"信任此电脑?" → 点击"信任"**
4. **输入手机锁屏密码确认**

#### 在 Xcode 中:

1. 顶部设备下拉框选择你的 **真实设备**(显示为 "YourName's iPhone")

2. 点击 **▶️ Run**

3. 首次安装时:
   - 手机上可能弹出 **"未受信任的企业级开发者"**
   - 前往 **设置 → 通用 → VPN 与设备管理**
   - 找到你的 Apple ID → 点击 **"信任"**

4. 应用自动启动!

#### 常见问题:

**Q: 提示 "Failed to create provisioning profile"?**
```
解决: 
1. Xcode → Settings → Accounts
2. 选中你的 Apple ID
3. 点击底部 "Download Manual Profiles"
4. 重新 Run
```

**Q: 提示 "The identity used to sign the executable is no longer valid"?**
```
这是正常现象!免费账号签名的证书 7 天过期。
解决:
1. 删除手机上的旧 App
2. Xcode Product → Clean Build Folder (Cmd+Shift+K)
3. 重新 Run
```

**Q: 找不到我的设备?**
```
检查:
1. 数据线是否连接牢固
2. 手机是否已信任电脑
3. Xcode → Window → Devices and Simulators 
   查看设备是否列出
4. 重启 Xcode 和手机
```

---

### Step 9: 导出 IPA 分享给他人(可选)

如果你有付费开发者账号($99/年):

#### 方法 A: Xcode Organizer

1. Xcode → Product → Archive
2. 等待归档完成
3. 点击 **"Distribute App"**
4. 选择 **"Ad Hoc"**
5. 勾选要支持的设备 UDID
6. 点击 **"Export"** 保存 IPA 文件
7. 通过 AirDrop/网盘发送给学生

#### 方法 B: 命令行

```bash
# 1. Archive
xcodebuild -project BassPractice.xcodeproj \
  -scheme BassPractice \
  -configuration Release \
  -archivePath BassPractice.xcarchive \
  archive

# 2. 创建导出配置
cat > ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
EOF

# 3. 导出 IPA
xcodebuild -exportArchive \
  -archivePath BassPractice.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./ReleaseIPA

# 4. 生成的 BassPractice.ipa 在 ReleaseIPA 文件夹
```

学生收到 IPA 后:
1. 用 Safari 打开(不能直接点击)
2. 或安装 [Configurator 2](https://apps.apple.com/us/app/apple-configurator/id1037126344) 导入

---

## 🔧 故障排除

### 问题 1: 构建失败 "No such module 'SwiftData'"

**原因**: iOS 版本低于 17.0  
**解决**: 
- 模拟器: 选择 iOS 17+ 的模拟器
- 真机: 更新系统到 iOS 17+

---

### 问题 2: OSMD 五线谱不显示

**原因**: JS 资源文件缺失  
**检查**:
```bash
ls -la BassPractice/Resources/notation_template.html
ls -la BassPractice/Resources/osmd/opensheetmusicdisplay.min.js
```

如果文件不存在,从 GitHub 重新下载。

---

### 问题 3: 真机调试 7 天后过期

**原因**: 免费 Apple ID 限制  
**解决**:
1. 删除手机上的旧 App
2. Xcode → Product → Clean Build Folder
3. 重新 Run(每次重装有效期重置 7 天)

**永久方案**: 购买 Apple Developer Program ($99/年)

---

### 问题 4: MIDI 导入后无声音

**检查**:
1. 手机静音开关是否关闭
2. 音量是否调高
3. 耳机是否正常(如使用)
4. Xcode Console 是否有音频错误日志

---

### 问题 5: iPad 横屏布局错乱

**原因**: 可能是缓存问题  
**解决**:
1. 完全关闭 App(上滑退出)
2. 重新打开
3. 如仍异常,重启 iPad

---

## 📱 日常使用流程

### 每次开发的典型工作流:

```bash
# 1. 拉取最新代码(如果是团队协作)
git pull origin main

# 2. 清理构建(遇到奇怪问题时)
xcodebuild clean -project BassPractice.xcodeproj -scheme BassPractice

# 3. 构建到模拟器
xcodebuild -project BassPractice.xcodeproj \
  -scheme BassPractice \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build run

# 4. 或直接打开 Xcode 图形界面操作
open BassPractice.xcodeproj
```

---

## 💡 进阶技巧

### 加速构建

```bash
# 使用增量构建(不清理)
xcodebuild -project BassPractice.xcodeproj \
  -scheme BassPractice \
  build

# 并行构建(多核 CPU)
xcodebuild -parallelizeTargets \
  -project BassPractice.xcodeproj \
  -scheme BassPractice \
  build
```

### 查看实时日志

```bash
# 模拟器日志
xcrun simctl spawn booted log stream --predicate \
  'processImagePath contains "BassPractice"'

# 真机日志(需先知道设备 UDID)
idevicesyslog -u YOUR_UDID | grep BassPractice
```

### 性能分析

Xcode → Product → Profile (Cmd+I)  
使用 Instruments 工具检查:
- CPU 占用
- 内存泄漏
- 卡顿帧率

---

## 🎓 学习资源

### Swift/SwiftUI 入门
- [Swift 官方教程](https://docs.swift.org/swift-book/)
- [SwiftUI by Example](https://www.hackingwithswift.com/quick-start/swiftui)
- [Stanford CS193p iOS 开发课程](https://cs193p.sites.stanford.edu/)

### 音频/MIDI 编程
- [AVAudioEngine Programming Guide](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [Core MIDI Overview](https://developer.apple.com/documentation/coremidi)

### 音乐记谱
- [MusicXML 规范](https://www.w3.org/2021/06/musicxml40/)
- [OpenSheetMusicDisplay API](https://github.com/opensheetmusicdisplay/opensheetmusicdisplay/wiki)

---

## ❓ 常见问题 FAQ

**Q: 我没有 Mac,能用 Windows 编译吗?**  
A: 不能。iOS 应用必须用 Xcode(Mac 专属)编译。可考虑:
- 借用朋友的 Mac
- 购买 Mac mini(最便宜选项)
- 云 Mac 服务(如 MacinCloud,但不推荐用于开发)

**Q: 可以不用 XcodeGen 吗?**  
A: 可以,但需要手动在 Xcode 中创建项目并添加所有源文件。XcodeGen 自动化这个过程。

**Q: 为什么不用 CocoaPods/SwiftPM?**  
A: 本项目依赖极少(OSMD/VexFlow 是本地 JS 文件),无需包管理器。

**Q: 能在 Android 上运行吗?**  
A: 不能。这是纯 SwiftUI 应用,仅限 iOS。如需 Android 版本需完全重写。

**Q: 如何修改 App 图标?**  
A: 替换 `BassPractice/Resources/Assets.xcassets/AppIcon.appiconset/` 中的图片,然后在 Xcode 中重新生成 Assets Catalog。

**Q: 如何更改 Bundle ID?**  
A: 编辑 `project.yml`:
```yaml
targets:
  BassPractice:
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.yourname.basspractice
```
然后重新 `xcodegen generate`

---

## 🆘 获取帮助

遇到问题?

1. **查看控制台日志**: Xcode → View → Debug Area → Activate Console
2. **搜索 Issue**: [GitHub Issues](https://github.com/YOUR_USERNAME/BassPractice/issues)
3. **新建 Issue**: 提供详细错误信息和截图
4. **邮件联系**: your.email@example.com

---

**祝你编译顺利! 🎸**

如有任何疑问,不要犹豫,立即提问!
