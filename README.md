# Bass Practice - 五弦贝斯 & 吉他练习助手

[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

一款功能强大的 **iOS 音乐练习工具**,专为 **五弦贝斯** 和 **吉他** 手设计。支持音阶/琶音学习、交互式指板、MIDI/PDF 导入、曲谱编辑、节拍器回放等完整工作流。

> 🎸 **核心特色**: 双乐器支持 · 实时五线谱渲染 · MIDI 导入自动生成 Tab 谱 · 吉他和弦移调练习 · 纯 Swift 实现无后端依赖

---

## 📱 功能概览

### 🎵 音阶与琶音库
- **16 种音阶**: 大调、自然小调、和声/旋律小调、Dorian、Phrygian、Lydian、Mixolydian、Locrian、五声音阶、布鲁斯等
- **16 种琶音**: 大三和弦、小三和弦、属七、大七、小七、减七、增七等
- **双乐器切换**: 贝斯(B-E-A-D-G) / 吉他(E-A-D-G-B-E),自动适配指板配置
- **多指法对比**: 同一音阶生成多种把位指法,支持并排对比
- **中文说明**: 每个音阶提供音程结构、全半音模式、中文描述

### 🎸 吉他和弦练习
- **83+ 预设和弦**: 涵盖大三、小三、属七、大七、小七、减、增、sus4、sus2、六和弦、九和弦等 12 类
- **智能移调**: 
  - **指型移动模式**: 保持指型,整体平移把位(适合练习不同调)
  - **变调夹模式**: 固定把位,模拟 Capo 效果
- **和弦构成详解**: 
  - 显示根音、音程结构(如 1-3-5-b7)
  - 每根弦标注实际音高 + 音程角色(根音/三音/五音等)
  - 移调后自动更新所有说明
- **可视化指板图**: 清晰展示按弦位置,支持空弦/闷音标记

### 🎼 五线谱与 Tab 谱
- **专业渲染**: 基于 OpenSheetMusicDisplay (OSMD) + VexFlow,出版级五线谱质量
- **双视图布局**: iPad 横屏并排显示五线谱 + 指板,iPhone 自适应上下排列
- **Tab 谱自动生成**: 
  - MIDI 导入时自动检测最佳指法位置
  - MusicXML 导出时输出双谱表(五线谱 + Tab 谱)
  - 贝斯 5 线 / 吉他 6 线,符合标准记谱规范
- **实时预览**: 编辑器中输入音符即刻渲染五线谱

### 📥 文件导入与导出
- **MIDI 导入**: 解析 .mid/.midi 文件,自动转换为 Score 模型 + Tab 谱标注
- **PDF 查看**: 内置 PDFKit 阅读器,支持导入外部曲谱
- **MuseScore 支持**: 直接打开 .mscz/.mscx 文件(需系统安装 MuseScore)
- **MusicXML 导出**: 标准 Partwise 格式,兼容 Sibelius/Finale/MuseScore
- **MIDI 导出**: 将编辑的曲谱导出为标准 SMF 文件

### ✏️ 曲谱编辑器
- **交互式输入**: 点击指板输入音符,自动计算最优弦品位置
- **时值选择**: 全音符、二分、四分、八分、十六分音符及对应休止符
- **小节管理**: 添加/删除小节,设置拍号(4/4、3/4、6/8 等)、调号、速度
- **撤销/重做**: 基于命令模式的无限撤销历史
- **SwiftData 持久化**: 自动保存,重启不丢失

### 🎧 练习模式
- **MIDI 回放引擎**: AVAudioEngine + AVAudioUnitSampler,精确到毫秒级的时序调度
- **变速不变调**: 25%-100% 速度调节,保持原始音高(适合慢练)
- **循环播放**: 自定义起止小节,自动循环计数
- **节拍器**: 
  - 40-240 BPM 可调
  - 视觉节拍指示 + 音频提示音
  - 独立使用或配合曲谱
- **实时追踪**: 练习时长统计、当前小节/音符高亮、进度条显示

---

## 🏗️ 技术架构

### 核心技术栈
- **UI 框架**: SwiftUI + Combine + @Observable
- **最低系统**: iOS 17.0 (利用 SwiftData、新 SwiftUI 特性)
- **设备支持**: iPhone + iPad (自适应 NavigationSplitView)
- **五线谱引擎**: OpenSheetMusicDisplay 0.9.5 + VexFlow 3.0.9 (WKWebView 桥接)
- **音频引擎**: AVAudioEngine + AVAudioUnitSampler + AVAudioPlayerNode
- **数据持久化**: SwiftData (iOS 17 原生 ORM)
- **文件解析**: 纯 Swift 实现的 SMF Parser、MusicXML Generator

### 项目结构
```
BassGuitarPractice/
├── App/                          # App 入口与导航
│   ├── BassGuitarPracticeApp.swift     # @main 入口
│   └── RootView.swift            # 主导航(TabView)
├── Core/                         # 核心业务逻辑(无 UI 依赖)
│   ├── MusicTheory/              # 音乐理论模型
│   │   ├── Pitch.swift           # 音高(MIDI 号 ↔ 音名+八度)
│   │   ├── Interval.swift        # 音程计算
│   │   ├── Scale.swift           # 16 种音阶定义
│   │   ├── Arpeggio.swift        # 16 种琶音定义
│   │   └── GuitarChord.swift     # 吉他和弦数据结构 + 移调算法
│   ├── Fretboard/                # 指板引擎
│   │   ├── FretboardConfig.swift # 贝斯/吉他配置(弦数、品格数、定弦)
│   │   ├── FretboardPosition.swift # 弦+品位置抽象
│   │   ├── FretboardMap.swift    # 指板音符映射表
│   │   ├── StringFretSolver.swift # 音高→弦品转换算法
│   │   └── FingeringGenerator.swift # 多指法回溯搜索 + 剪枝
│   ├── MIDI/                     # MIDI 处理
│   │   ├── MIDIEvent.swift       # NoteOn/Off/Tempo 事件
│   │   ├── MIDIParser.swift      # SMF 二进制解析(Type 0/1)
│   │   └── MIDIToScoreConverter.swift # MIDI→Score 量化转换
│   └── Audio/                    # 音频引擎
│       ├── MIDIPlaybackEngine.swift # 回放调度( lookahead 机制)
│       └── MetronomeEngine.swift    # 节拍器音频合成
├── Features/                     # SwiftUI 功能模块
│   ├── Fretboard/                # 交互式指板视图
│   │   ├── Views/FretboardView.swift
│   │   └── ViewModels/FretboardViewModel.swift
│   ├── ScaleLibrary/             # 音阶/和弦库
│   │   ├── Views/
│   │   │   ├── ScaleLibraryView.swift      # 懒加载列表
│   │   │   ├── ScaleDetailView.swift       # 音阶详情
│   │   │   ├── ChordDiagramView.swift      # 和弦指板图
│   │   │   └── FingeringComparisonView.swift
│   │   ├── ViewModels/ScaleLibraryViewModel.swift
│   │   └── Data/ScaleDefinitions.swift     # 音阶/和弦静态数据
│   ├── Notation/                 # 五线谱渲染
│   │   ├── Views/NotationWebView.swift     # WKWebView 桥接 OSMD
│   │   └── Resources/
│   │       ├── notation_template.html      # HTML 模板
│   │       └── osmd/                       # OSMD + VexFlow JS
│   ├── Import/                   # 文件导入
│   │   └── Views/
│   │       ├── MIDIImportView.swift        # MIDI 导入向导
│   │       └── PDFViewer.swift             # PDFKit 包装
│   ├── ScoreEditor/              # 曲谱编辑器
│   │   ├── Views/
│   │   │   ├── ScoreEditorView.swift
│   │   │   ├── NoteInputBar.swift          # 音符时值选择栏
│   │   │   ├── MeasureEditView.swift       # 小节编辑
│   │   │   └── ScoreExportView.swift       # 导出面板
│   │   ├── ViewModels/ScoreEditorViewModel.swift
│   │   └── Commands/EditorCommands.swift   # Undo/Redo 命令
│   └── Practice/                 # 练习模式
│       ├── Views/
│       │   ├── PracticeSessionView.swift
│       │   └── MetronomeView.swift
│       └── ViewModels/PracticeSessionViewModel.swift
├── Models/                       # 数据模型
│   ├── Score.swift               # Score 内存模型(音符/小节/元数据)
│   └── StoredScore.swift         # SwiftData 持久化模型
├── Rendering/                    # 导出渲染
│   ├── MusicXMLExporter.swift    # Score→MusicXML(支持 Tab 谱)
│   └── MIDIExporter.swift        # Score→SMF
└── Resources/                    # 资源文件
    └── Assets.xcassets/          # App Icon(需自行添加)
```

### 关键算法

#### 1. 弦品自动计算
当用户将音符拖动到不同弦上时,实时计算目标品格:
```swift
fret = targetPitch.midiNumber - stringOpenString.midiNumber
// 例: D2(MIDI 50) 在 G 弦(空弦 MIDI 43) → 第 7 品
```

#### 2. 多指法生成(回溯搜索 + 剪枝)
```swift
1. 为每个音高找出所有可能的 (弦, 品) 组合
2. 回溯搜索有效的手指分配方案
3. 剪枝条件:
   - 相邻音符跨弦 > 2 根 → 剔除
   - 单指同时按多弦 → 剔除
   - 把位跨度 > 5 品 → 低优先级
4. 按"低把位优先、手型紧凑"排序返回前 N 种
```

#### 3. MIDI 量化对齐
```swift
1. 解析 NoteOn/NoteOff 事件对,计算精确时值(微秒)
2. 根据 tempo 和 time signature 确定网格单位(默认十六分音符)
3. 将音符起始时间量化到最近网格点
4. 合并重叠音符,拆分跨小节音符
```

#### 4. 吉他和弦移调
```swift
// 指型移动模式: 所有 fret += semitones, 开放弦变为按弦(finger=nil)
transposedChord = originalChord.fingering.map { 
    Fingering(fret: $0.fret == nil ? nil : $0.fret! + offset, finger: $0.finger)
}

// 变调夹模式: fret 不变,重新计算 chord name (C → C#)
capoChord = originalChord.withName(transposeName(originalChord.name, semitones))
```

---

## 🚀 快速开始

### 系统要求
- **macOS**: 13.0+ (Xcode 15+)
- **iOS**: 17.0+ (iPhone/iPad)
- **Swift**: 5.9+

### ⚡ 方式一:一键脚本(推荐新手)

最简单的方式,自动完成所有步骤:

```bash
# 1. 克隆仓库
git clone https://github.com/JacquelineZhou53/BassGuitarPractice.git
cd BassGuitarPractice

# 2. 运行一键启动脚本
chmod +x scripts/run.sh
./scripts/run.sh
```

脚本会自动:
- ✅ 检查 Xcode 和 XcodeGen 是否安装
- ✅ 自动生成 Xcode 项目
- ✅ 智能选择模拟器(iPhone 16 Pro 优先)
- ✅ 构建并启动应用
- ✅ 彩色输出,友好的错误提示

**其他脚本选项:**
```bash
./scripts/run.sh device    # 在真机上运行
./scripts/run.sh clean     # 清理构建缓存
./scripts/quickstart.sh    # 超快速启动(跳过检查)
```

详细说明请查看 [scripts/README.md](scripts/README.md)

---

### 方式二:XcodeGen(手动)

如果你想了解每一步在做什么:

```bash
# 1. 安装 XcodeGen
brew install xcodegen

# 2. 克隆仓库
git clone https://github.com/JacquelineZhou53/BassGuitarPractice.git
cd BassGuitarPractice

# 3. 生成 Xcode 项目
xcodegen generate

# 4. 打开项目
open BassGuitarPractice.xcodeproj
```

### 方式二:手动创建项目

1. Xcode → File → New → Project → iOS → App
2. Product Name: `BassGuitarPractice`, Interface: `SwiftUI`, Language: `Swift`
3. 删除自动生成的 `ContentView.swift`
4. 将整个 `BassGuitarPractice/` 文件夹拖入 Xcode 项目根目录
5. 确保勾选 "Copy items if needed" 和 Target Membership
6. 选择模拟器或真机,Cmd+R 运行

### 方式三:命令行构建(仅模拟器)

```bash
# 清理构建
xcodebuild clean -project BassGuitarPractice.xcodeproj -scheme BassGuitarPractice

# 构建到模拟器
xcodebuild -project BassGuitarPractice.xcodeproj \
  -scheme BassGuitarPractice \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' \
  build

# 启动模拟器并安装
xcrun simctl boot "iPhone 16 Pro"
xcrun simctl install booted build/Debug-iphonesimulator/BassGuitarPractice.app
xcrun simctl launch booted com.basspractice.app
```

---

## 🛠️ 自编译指南

### 前置准备

1. **安装 Xcode**
   - Mac App Store 下载 Xcode 15+
   - 首次启动接受许可协议

2. **安装 Xcode Command Line Tools**
   ```bash
   xcode-select --install
   ```

3. **注册 Apple ID**(免费)
   - Xcode → Preferences → Accounts → + → Add Apple ID
   - 无需付费开发者账号即可真机调试(7 天有效期)

### 编译步骤

#### A. 模拟器测试(最简单)
```bash
# 1. 列出可用模拟器
xcrun simctl list devices available

# 2. 构建并运行
xcodebuild -project BassGuitarPractice.xcodeproj \
  -scheme BassGuitarPractice \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build run
```

#### B. 真机调试(免费账号)
```bash
# 1. USB 连接 iPhone/iPad
# 2. 信任电脑(手机上点击"信任此电脑")
# 3. Xcode 中选择你的设备(Device 而非 Simulator)
# 4. Cmd+R 运行(Xcode 自动签名)

# 或使用命令行:
DEVICE_UDID=$(idevice_id -l)  # 获取 UDID
xcodebuild -project BassGuitarPractice.xcodeproj \
  -scheme BassGuitarPractice \
  -destination "platform=iOS,id=$DEVICE_UDID" \
  build run
```

**注意**: 免费账号签名的 App **7 天过期**,过期后需删除重装。

#### C. 导出 IPA(Ad Hoc 分发)
需要付费开发者账号($99/年):

```bash
# 1. Archive
xcodebuild -project BassGuitarPractice.xcodeproj \
  -scheme BassGuitarPractice \
  -configuration Release \
  -archivePath BassGuitarPractice.xcarchive \
  archive

# 2. 创建 ExportOptions.plist
cat > ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
EOF

# 3. 导出 IPA
xcodebuild -exportArchive \
  -archivePath BassGuitarPractice.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./ReleaseIPA
```

将生成的 `BassGuitarPractice.ipa` 通过 AirDrop/网盘分享给学生,他们用 Safari 打开安装。

---

## 📦 上传到 GitHub 清单

### ✅ 应该上传的文件

```
BassGuitarPractice/                  # 源代码根目录
├── BassGuitarPractice/              # Swift 源码和资源
│   ├── App/                   # App 入口
│   ├── Core/                  # 核心逻辑
│   ├── Features/              # SwiftUI 视图
│   ├── Models/                # 数据模型
│   ├── Rendering/             # 导出器
│   ├── Resources/             # OSMD JS 文件 + HTML 模板
│   ├── Info.plist             # 应用配置
│   └── BassGuitarPracticeApp.swift  # @main
├── BassGuitarPracticeTests/         # 单元测试(如有)
├── Package.swift              # Swift Package 描述(可选)
├── project.yml                # XcodeGen 配置
├── .gitignore                 # Git 忽略规则
├── LICENSE                    # MIT 许可证
├── README.md                  # 本文档
└── CONTRIBUTING.md            # 贡献指南(可选)
```

### ❌ 不应上传的文件(已在 .gitignore)

```
.build/                        # Swift 构建产物
build/                         # Xcode 构建产物
*.xcodeproj                    # Xcode 项目文件(用 XcodeGen 生成)
*.xcworkspace
xcuserdata/                    # 用户特定配置
DerivedData/
.DS_Store                      # macOS 隐藏文件
*.ipa                          # 安装包
*.dSYM*                        # 调试符号
Pods/                          # CocoaPods 依赖
.idea/ .vscode/                # IDE 配置
*.env *.secret                 # 敏感信息(本项目无)
```

### 🔒 安全检查清单

上传前确认**没有硬编码**:
- [x] API Key / Secret Token
- [x] 个人 Apple ID / 密码
- [x] Provisioning Profile UUID(使用变量 `$PRODUCT_BUNDLE_IDENTIFIER`)
- [x] 团队 ID(使用 `$DEVELOPMENT_TEAM`)
- [x] 私有证书 / Keystore

**本项目已验证**: 纯本地应用,无网络请求,无硬编码密钥,✅ 安全开源。

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request!

### 如何贡献代码

1. **Fork 本仓库**
2. **创建特性分支**: `git checkout -b feature/amazing-feature`
3. **提交更改**: `git commit -m 'Add amazing feature'`
4. **推送分支**: `git push origin feature/amazing-feature`
5. **开启 Pull Request**

### 代码规范
- 遵循 [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- 使用 2 空格缩进
- 公共 API 添加文档注释(`///`)
- 新增功能尽量附单元测试

### 报告 Bug
请在 Issue 中提供:
- iOS 版本和设备型号
- 复现步骤
- 预期行为 vs 实际行为
- 截图或录屏(如适用)

---

## 📄 许可证

本项目采用 **MIT License** - 详见 [LICENSE](LICENSE) 文件

```
Copyright (c) 2024 BassGuitarPractice Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

### 第三方组件致谢
- **OpenSheetMusicDisplay** (Apache 2.0) - 五线谱渲染引擎
- **VexFlow** (MIT) - 音乐记谱排版引擎
- **Apple AVFoundation** - MIDI 回放音频合成

---

## 📬 联系方式

- **GitHub Issues**: [Issues · BassGuitarPractice](https://github.com/JacquelineZhou53/BassGuitarPractice/issues)

---

## 🌟 Star History

如果这个项目对你有帮助,请给个 ⭐️ Star 支持一下!

[![Star History Chart](https://api.star-history.com/svg?repos=JacquelineZhou53/BassGuitarPractice&type=Date)](https://star-history.com)

---

## 📚 相关资源

- [SwiftUI 官方教程](https://developer.apple.com/tutorials/swiftui)
- [OpenSheetMusicDisplay 文档](https://github.com/opensheetmusicdisplay/opensheetmusicdisplay)
- [MusicXML 规范](https://www.w3.org/2021/06/musicxml40/)
- [AVAudioEngine 编程指南](https://developer.apple.com/documentation/avfaudio/avaudioengine)

---

**Happy Practicing! 🎸🎵**
