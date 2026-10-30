# GitHub 上传检查清单

在将项目推送到 GitHub 之前,请按以下步骤检查:

---

## ✅ 文件准备检查

### 核心文件(必须存在)

- [x] `BassPractice/` - 源代码目录
  - [x] `App/` - App 入口
  - [x] `Core/` - 核心逻辑
  - [x] `Features/` - SwiftUI 视图
  - [x] `Models/` - 数据模型
  - [x] `Rendering/` - 导出器
  - [x] `Resources/` - OSMD JS 文件 + HTML 模板
  - [x] `Info.plist` - 应用配置

- [x] `BassPracticeTests/` - 单元测试(如有)

- [x] 配置文件
  - [x] `project.yml` - XcodeGen 配置
  - [x] `.gitignore` - Git 忽略规则
  - [x] `Package.swift` - Swift Package 描述(可选)

- [x] 文档
  - [x] `README.md` - 项目说明
  - [x] `LICENSE` - MIT 许可证
  - [x] `CONTRIBUTING.md` - 贡献指南
  - [x] `SETUP_GUIDE.md` - 编译教程

### 不应上传的文件(确认已忽略)

运行以下命令验证:

```bash
# 查看将被提交的文件
git status

# 确认以下文件/文件夹 NOT 出现在列表中:
# ❌ .build/
# ❌ build/
# ❌ *.xcodeproj
# ❌ xcuserdata/
# ❌ DerivedData/
# ❌ .DS_Store
# ❌ *.ipa
# ❌ *.dSYM*
# ❌ Pods/
```

如发现有不该上传的文件:

```bash
# 添加到 .gitignore
echo "filename" >> .gitignore

# 从 Git 缓存中移除(不删除本地文件)
git rm --cached filename
```

---

## 🔒 安全检查

### 敏感信息扫描

```bash
# 搜索可能的硬编码密钥
grep -r "API_KEY\|SECRET\|PASSWORD\|TOKEN" BassPractice/ --include="*.swift"

# 搜索 Apple ID 或邮箱
grep -r "@apple.com\|@gmail.com" BassPractice/ --include="*.swift"

# 搜索 Bundle ID(应该是变量而非常量)
grep -r "com\.basspractice" BassPractice/ --include="*.plist"
```

**预期结果**: 
- ✅ 无 API Key/Secret
- ✅ 无个人邮箱(除非是公开的联系方式)
- ✅ Bundle ID 使用 `$(PRODUCT_BUNDLE_IDENTIFIER)` 变量

### Info.plist 检查

打开 `BassPractice/Info.plist`,确认:

```xml
<!-- ✅ 正确: 使用变量 -->
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>

<!-- ❌ 错误: 硬编码 -->
<key>CFBundleIdentifier</key>
<string>com.basspractice.app</string>
```

### project.yml 检查

打开 `project.yml`,确认:

```yaml
# ✅ 正确: 使用变量
settings:
  DEVELOPMENT_TEAM: "$(DEVELOPMENT_TEAM)"
  PRODUCT_BUNDLE_IDENTIFIER: "com.basspractice.app"

# ❌ 错误: 硬编码团队 ID
settings:
  DEVELOPMENT_TEAM: "ABC123XYZ"  # 不要这样!
```

---

## 🧹 代码清理

### 移除调试代码

```bash
# 搜索 print 语句(可选,建议保留关键日志)
grep -r "print(" BassPractice/ --include="*.swift" | wc -l

# 搜索 TODO/FIXME(决定是否完成或移除)
grep -r "TODO\|FIXME\|HACK" BassPractice/ --include="*.swift"
```

### 格式化代码

推荐使用 [SwiftFormat](https://github.com/nicklockwood/SwiftFormat):

```bash
# 安装
brew install swiftformat

# 格式化所有 Swift 文件
swiftformat BassPractice/ --indent 2 --maxwidth 120
```

### 清理构建产物

```bash
# 清理 Xcode 构建
xcodebuild clean -project BassPractice.xcodeproj -scheme BassPractice

# 删除构建文件夹
rm -rf build/

# 删除 Swift 包缓存
rm -rf .build/

# 清理 macOS 隐藏文件
find . -name ".DS_Store" -delete
```

---

## 📝 文档完善

### README.md 最终检查

确认包含:

- [x] 项目名称和简介
- [x] 功能特性列表
- [x] 技术栈说明
- [x] 快速开始指南
- [x] 自编译步骤
- [x] 截图/演示 GIF(建议添加)
- [x] 许可证信息
- [x] 贡献方式
- [x] 联系方式

**替换占位符:**
```bash
# 搜索并替换以下内容:
YOUR_USERNAME        → 你的 GitHub 用户名
your.email@example.com → 你的公开邮箱
YOUR_TEAM_ID         → 你的开发者团队 ID(如有)
```

### 添加截图(强烈推荐)

准备 3-5 张应用截图:

1. **音阶库页面** - 展示列表和乐器切换
2. **吉他和弦练习** - 展示移调控制和指板图
3. **五线谱 + Tab 谱** - 展示双视图渲染
4. **曲谱编辑器** - 展示音符输入界面
5. **练习模式** - 展示节拍器和回放控制

**处理方式:**
```bash
# 创建 screenshots 文件夹
mkdir screenshots

# 调整尺寸为 GitHub 友好大小(宽度 800px)
# 使用 sips(macOS 内置):
sips -Z 800 screenshot1.png -o screenshots/scale-library.png
sips -Z 800 screenshot2.png -o screenshots/chord-practice.png

# 或在 iPhone 模拟器中:
# File → Save Screen Shot (Cmd+S)
```

**在 README 中引用:**
```markdown
![音阶库](screenshots/scale-library.png)
![和弦练习](screenshots/chord-practice.png)
```

### 添加演示 GIF(可选但加分)

录制操作演示:

```bash
# macOS 内置录屏:
# Cmd+Shift+5 → 录制屏幕区域 → 转换为 GIF

# 或使用 Kap(开源录屏工具):
brew install kap

# 优化 GIF 大小
brew install gifsicle
gifsicle -O2 -o optimized.gif original.gif
```

---

## 🏷️ 版本标签

### 创建第一个 Release

```bash
# 确保所有更改已提交
git add .
git commit -m "Initial release: BassPractice v1.0.0"

# 打标签
git tag -a v1.0.0 -m "First public release"

# 推送标签
git push origin v1.0.0
```

### GitHub Release 页面

访问 `https://github.com/YOUR_USERNAME/BassPractice/releases/new`:

- **Tag version**: v1.0.0
- **Release title**: BassPractice v1.0.0
- **Description**: 
  ```
  ## 首次发布
  
  ### 核心功能
  - ✅ 音阶/琶音库(16种音阶 + 16种琶音)
  - ✅ 吉他和弦练习(83+ 和弦,支持移调)
  - ✅ 五线谱 + Tab 谱双视图
  - ✅ MIDI/PDF 导入
  - ✅ 曲谱编辑器
  - ✅ 节拍器 + 回放引擎
  
  ### 技术亮点
  - 纯 Swift 实现,无后端依赖
  - SwiftUI + SwiftData 现代架构
  - 支持 iPhone + iPad 自适应布局
  ```
- **Assets**: 上传 IPA 文件(可选)

点击 **"Publish release"**

---

## 🚀 推送到 GitHub

### 创建仓库

1. 访问 [github.com/new](https://github.com/new)
2. **Repository name**: `BassPractice`
3. **Description**: "五弦贝斯 & 吉他练习助手 - iOS 应用"
4. **Visibility**: Public(公开)
5. **Initialize with**: ⚠️ **不要勾选任何选项**(我们已有代码)
6. 点击 **"Create repository"**

### 推送代码

```bash
# 进入项目目录
cd "/Users/coco_j/Documents/GameHacker/Bass Practice"

# 初始化 Git(如果还没初始化)
git init

# 添加远程仓库
git remote add origin https://github.com/YOUR_USERNAME/BassPractice.git

# 切换到 main 分支
git checkout -b main

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit: BassPractice v1.0.0"

# 推送
git push -u origin main
```

### 验证上传

访问 `https://github.com/YOUR_USERNAME/BassPractice`:

- [ ] 所有文件可见
- [ ] README.md 正确渲染
- [ ] 文件大小合理(整个仓库 < 100MB)
- [ ] 无敏感信息泄露

---

## 📊 仓库设置优化

### 启用 GitHub Pages(可选)

如果要托管在线文档:

1. Settings → Pages
2. Source: Deploy from a branch
3. Branch: main / root
4. Save

访问 `https://YOUR_USERNAME.github.io/BassPractice/`

### 添加 Topics(标签)

仓库首页 → About → Edit:

**Topics**:
```
ios swift swiftui music midi bass guitar fretboard 
music-theory sheet-music tabulature ios17
```

### 设置 Issue Templates

创建 `.github/ISSUE_TEMPLATE/bug_report.md`:

```markdown
---
name: Bug Report
about: 报告一个问题
title: '[BUG] '
labels: bug
---

**描述问题**
...

**复现步骤**
1. ...
2. ...

**预期行为**
...

**实际行为**
...

**环境**
- 设备: [e.g. iPhone 15 Pro]
- iOS: [e.g. 17.4.1]
- App 版本: [e.g. 1.0.0]
```

创建 `.github/ISSUE_TEMPLATE/feature_request.md`:

```markdown
---
name: Feature Request
about: 提议新功能
title: '[FEATURE] '
labels: enhancement
---

**功能描述**
...

**使用场景**
...

**实现建议**(可选)
...
```

### 添加 CI/CD(可选)

创建 `.github/workflows/build.yml`:

```yaml
name: Build and Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Install XcodeGen
      run: brew install xcodegen
    
    - name: Generate Project
      run: xcodegen generate
    
    - name: Build
      run: |
        xcodebuild -project BassPractice.xcodeproj \
          -scheme BassPractice \
          -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' \
          build
```

---

## 🎯 最终验证清单

### 仓库健康度检查

- [x] README.md 完整且无 broken links
- [x] LICENSE 文件存在
- [x] .gitignore 正确配置
- [x] 无大文件(单个文件 > 50MB)
- [x] 无敏感信息(API Key/密码/证书)
- [x] 代码可以干净克隆并编译

### 克隆测试

```bash
# 在另一个目录测试
cd /tmp
git clone https://github.com/YOUR_USERNAME/BassPractice.git
cd BassPractice

# 验证可以生成项目
xcodegen generate

# 验证可以构建
xcodebuild -project BassPractice.xcodeproj \
  -scheme BassPractice \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build
```

### 文档可读性测试

找一个**没有 iOS 开发经验**的朋友:

1. 让他/她阅读 `SETUP_GUIDE.md`
2. 尝试按照步骤编译
3. 记录卡住的地方
4. 根据反馈改进文档

---

## 📢 发布后推广

### 分享到社区

- [Reddit r/iOSProgramming](https://www.reddit.com/r/iOSProgramming/)
- [Hacker News](https://news.ycombinator.com/)
- [Swift 论坛](https://forums.swift.org/)
- [V2EX](https://www.v2ex.com/)
- 微博/知乎/小红书(中文用户)

### 准备分享内容

**标题示例:**
```
🎸 我开源了一个贝斯/吉他练习 iOS App (SwiftUI + SwiftData)

- 支持音阶/琶音学习、MIDI 导入、Tab 谱自动生成
- 吉他和弦移调练习,带详细构成说明
- 纯 Swift 实现,无后端依赖
- 欢迎 Star 和 PR!

GitHub: https://github.com/YOUR_USERNAME/BassPractice
```

**配图:**
- 应用截图 3-5 张
- 或 30 秒演示视频

---

## 🔄 后续维护

### 定期任务

**每周:**
- 检查 Issues,回复用户问题
- Review Pull Requests

**每月:**
- 更新依赖(OSMD/VexFlow 新版本)
- 检查 Xcode 兼容性(新 Beta 版)
- 统计 Star/下载数据

**每季度:**
- 发布新版本(修复 Bug + 新功能)
- 更新 README 截图(如有 UI 变更)
- 清理过期 Issues

### 版本管理

遵循 [Semantic Versioning](https://semver.org/):

- **MAJOR.MINOR.PATCH**
- v1.0.0 → v1.1.0 (新增功能)
- v1.1.0 → v1.1.1 (Bug 修复)
- v1.1.1 → v2.0.0 (重大变更,不兼容)

---

**检查完毕?现在可以放心推送了! 🚀**

```bash
git push origin main
```
