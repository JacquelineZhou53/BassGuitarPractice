# 贡献指南

感谢你考虑为 BassPractice 做出贡献!

## 🚀 快速开始

### 开发环境设置

1. **安装 Xcode 15+** (Mac App Store)
2. **安装 XcodeGen**: `brew install xcodegen`
3. **克隆仓库**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/BassPractice.git
   cd BassPractice
   ```
4. **生成项目**: `xcodegen generate`
5. **打开项目**: `open BassPractice.xcodeproj`

### 运行测试

```bash
# 模拟器
xcodebuild test -project BassPractice.xcodeproj -scheme BassPractice \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# 真机(需先信任电脑)
xcodebuild test -project BassPractice.xcodeproj -scheme BassPractice \
  -destination 'platform=iOS,id=YOUR_DEVICE_UDID'
```

## 📋 提交规范

### Commit Message 格式

遵循 [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Type 类型:**
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式(不影响功能)
- `refactor`: 重构(非功能性变更)
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建过程或辅助工具变更

**示例:**
```
feat(chord): 增加增七和弦移调支持

- 实现 Aug7 和弦的音程计算
- 添加 Caug7/Eaug7 预设指法
- 更新和弦分类枚举

Closes #42
```

### Pull Request 流程

1. **Fork 本仓库**
2. **从 `main` 创建分支**:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/your-feature-name
   ```
3. **开发并测试**
4. **提交更改**:
   ```bash
   git add .
   git commit -m "feat(scope): description"
   ```
5. **推送到你的 Fork**:
   ```bash
   git push origin feature/your-feature-name
   ```
6. **在 GitHub 开启 PR**

## 🎯 代码规范

### Swift 风格指南

- **缩进**: 2 空格(不使用 Tab)
- **行宽**: 最大 120 字符
- **命名**: 
  - 类型/协议: `UpperCamelCase`
  - 变量/函数: `lowerCamelCase`
  - 常量: `UPPER_SNAKE_CASE`(仅全局常量)
- **访问控制**: 默认 `private`,需要时再放宽
- **文档**: 公共 API 必须添加 `///` 文档注释

### 示例代码风格

```swift
/// 计算音符在指定弦上的品格位置
/// - Parameters:
///   - pitch: 目标音高
///   - stringIndex: 弦索引(0=最高音弦)
/// - Returns: 品格号,`nil` 表示该弦无法演奏此音高
func calculateFret(for pitch: Pitch, onString stringIndex: Int) -> Int? {
    guard stringIndex < config.strings.count else { return nil }
    
    let openStringMIDI = config.strings[stringIndex].midiNumber
    let fret = pitch.midiNumber - openStringMIDI
    
    return fret >= 0 && fret <= config.fretCount ? fret : nil
}
```

### 避免的模式

❌ **不要硬编码魔法数字:**
```swift
// Bad
if fret > 24 { return nil }

// Good
guard fret <= config.fretCount else { return nil }
```

❌ **不要在主线程执行耗时操作:**
```swift
// Bad
Button("Import MIDI") {
    let events = parseMIDI(fileURL)  // 阻塞 UI!
}

// Good
Button("Import MIDI") {
    Task.detached {
        let events = try await parseMIDIAsync(fileURL)
        await MainActor.run {
            viewModel.events = events
        }
    }
}
```

❌ **不要使用强制解包:**
```swift
// Bad
let name = optionalString!

// Good
guard let name = optionalString else { return }
```

## 🧪 测试要求

### 单元测试

新增核心逻辑应附单元测试:

```swift
final class FretboardTests: XCTestCase {
    func testCalculateFretOnDifferentStrings() {
        let config = FretboardConfig.bass5String
        let d2 = Pitch(midiNumber: 50)  // D2
        
        // D 弦(空弦 D2) → 0 品
        XCTAssertEqual(config.calculateFret(for: d2, onString: 2), 0)
        
        // G 弦(空弦 G2, MIDI 43) → 7 品
        XCTAssertEqual(config.calculateFret(for: d2, onString: 1), 7)
    }
}
```

### UI 测试关键路径

确保以下场景在真机上测试通过:
- [ ] 音阶库列表滚动流畅(60 FPS)
- [ ] 指板点击响应无延迟
- [ ] MIDI 导入大文件(>10MB)不崩溃
- [ ] 横竖屏切换布局正确
- [ ] iPad Split View 正常工作

## 🐛 报告 Bug

请在 [GitHub Issues](https://github.com/YOUR_USERNAME/BassPractice/issues) 创建 Issue,包含:

### Bug 报告模板

```markdown
**描述问题**
简明扼要地说明发生了什么错误。

**复现步骤**
1. 打开应用,进入"音阶库"
2. 选择"大调音阶" → C Major
3. 点击"指法对比"按钮
4. 观察到...

**预期行为**
应该显示...

**实际行为**
实际显示了...

**环境信息**
- 设备: iPhone 15 Pro / iPad Air 5
- iOS 版本: 17.4.1
- App 版本: 1.0.0 (Build 1)
- 是否越狱: 否

**截图/录屏**
[附加截图或屏幕录制]

**日志**
[如有 Crash Log 或 Console 输出,请附上]
```

## 💡 功能建议

欢迎提出新功能想法!请在 Issue 中标签 `[Enhancement]`,说明:
- 使用场景
- 解决的问题
- 可能的实现方案(可选)

## 📝 文档更新

如果 PR 改变了公共 API 或用户可见功能,请同步更新:
- `README.md` 相关章节
- 代码文档注释(`///`)
- 截图/演示 GIF(如 UI 变更)

## 🎨 资源文件处理

### 添加新音阶/和弦

编辑 `BassPractice/Features/ScaleLibrary/Data/ScaleDefinitions.swift`:

```swift
// 新增音阶示例
static let phrygianDominant = ScaleDefinition(
    id: "phrygian_dominant",
    name: "Phrygian Dominant",
    chineseName: "弗里几亚属音阶",
    intervals: [0, 1, 4, 5, 7, 8, 10],  // 半音偏移
    description: "和声小调第五模式,常见于弗拉门戈和中东音乐"
)
```

### 添加新 OSMD 功能

修改 `notation_template.html` 后,需在 README 中说明兼容性影响。

## 🔒 安全注意事项

- **绝不提交**: Apple ID、密码、Provisioning Profile、证书私钥
- **敏感信息**: 使用环境变量或 `.env`(已加入 .gitignore)
- **依赖审计**: 定期运行 `swift package audit` 检查第三方库漏洞

## 📊 Code Review 标准

PR 合并前需满足:
- [ ] 所有 CI 检查通过(构建 + 测试)
- [ ] 至少 1 个 Maintainer 批准
- [ ] 无未解决的评论
- [ ] 分支最新于 `main`
- [ ] Commit 历史整洁(必要时 Rebase)

## 🙏 致谢

感谢所有贡献者让这个项目变得更好!

---

**有问题?** 随时在 [Discussions](https://github.com/YOUR_USERNAME/BassPractice/discussions) 提问!
