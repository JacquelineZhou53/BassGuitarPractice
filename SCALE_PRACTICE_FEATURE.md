# 音阶/琶音练习功能 - 实现总结

## 🎯 功能概述

新增了完整的音阶和琶音练习功能,用户可以:
1. 选择贝斯或吉他乐器
2. 从音阶库中选择任意音阶或琶音
3. 选择根音
4. 多选指法(支持全选/清空)
5. 设置练习速度
6. 选择显示模式(仅选中指法/所有指法)
7. 生成多行五线谱 + Tab 谱
8. 使用完整的练习功能(播放、循环、变速、节拍器)
9. 在不同指法间快速切换

## 📁 新增文件

### Core 层
- `BassPractice/Core/ScoreGeneration/ScaleScoreBuilder.swift`
  - 将 FingeringPattern 转换为 Score 的核心工具
  - 支持多个指法生成多行乐谱
  - 自动计算调号、拍号、速度
  - 提供指法到小节的映射功能

### Features 层

#### ScalePractice/ViewModels/
- `ScalePracticeSetupViewModel.swift`
  - 练习设置页面的状态管理
  - 管理乐器选择、指法选择、速度、显示模式
  
- `ScalePracticeSessionViewModel.swift`
  - 练习会话的状态管理
  - 包装 PracticeSessionViewModel
  - 提供指法切换功能
  - 计算指法对应的小节位置

#### ScalePractice/Views/
- `FingeringMultiSelectView.swift`
  - 指法多选组件
  - 显示指法缩略图网格
  - 支持全选/清空操作
  - 包含简化的指板预览视图
  
- `ScalePracticeSetupView.swift`
  - 练习设置页面
  - 显示音阶信息卡片
  - 乐器选择器
  - 指法多选器
  - 速度控制
  - 显示模式切换
  - 开始练习按钮
  
- `ScalePracticeSessionView.swift`
  - 练习会话页面
  - 指法导航栏(横向滚动标签)
  - 前后指法切换按钮
  - 嵌入现有的 PracticeSessionView

### Models 层
- 修改 `Score.swift`
  - 添加 `ScoreSource.scalePractice` 枚举值

## 🔧 修改的文件

### ScaleDetailView.swift
- 添加 `practiceButton` 视图
- 使用 NavigationLink 导航到 ScalePracticeSetupView
- 在指法选择器下方显示"开始音阶练习"按钮

## 🎨 UI 设计

### 练习设置页面
```
┌─────────────────────────────────┐
│  C 大调音阶          🎵         │
│  大调音阶                       │
│                                 │
│  音程结构: R - M2 - M3 - ...   │
│  可用指法: 6 种                 │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  乐器                           │
│  [贝斯] [吉他]                  │
│  五弦贝斯 (B-E-A-D-G)           │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  选择指法 (3/6)  [全选] [清空]  │
│                                 │
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  │ ✓ 1  │ │ ✓ 2  │ │   3  │   │
│  │ [指板]│ │ [指板]│ │ [指板]│   │
│  └──────┘ └──────┘ └──────┘   │
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  │ ✓ 4  │ │   5  │ │   6  │   │
│  │ [指板]│ │ [指板]│ │ [指板]│   │
│  └──────┘ └──────┘ └──────┘   │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  练习速度          80 BPM       │
│  [-] ━━━━━━●━━━━━━━ [+]        │
│  建议: 慢速开始,逐步提高        │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  显示模式                       │
│  [仅选中指法] [所有指法]        │
│  只显示你选择的指法             │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│        ▶️ 开始练习               │
└─────────────────────────────────┘
```

### 练习会话页面
```
┌─────────────────────────────────┐
│ [指法1] [指法2] [指法3] [指法4] │ ← 横向滚动
│         ← 上一个  下一个 →      │
├─────────────────────────────────┤
│  [停止] [▶️播放]  0:23  ═══ 第3小节 │
├─────────────────────────────────┤
│                                 │
│  五线谱 + Tab 谱                │
│  (多行显示所有选中的指法)       │
│                                 │
├─────────────────────────────────┤
│                                 │
│  指板图                         │
│  (实时同步当前播放位置)         │
│                                 │
├─────────────────────────────────┤
│  速度控制 | 循环控制 | 节拍器   │
└─────────────────────────────────┘
```

## 🔄 数据流

```
用户选择音阶/根音
        ↓
ScaleLibraryViewModel
        ↓
点击"开始音阶练习"
        ↓
ScalePracticeSetupView
  ├─ 选择乐器 (bass/guitar)
  ├─ 多选指法 (Set<Int>)
  ├─ 设置速度 (40-200 BPM)
  └─ 选择显示模式 (selectedOnly/allFingerings)
        ↓
点击"开始练习"
        ↓
ScaleScoreBuilder.buildScore()
  ├─ 为每个指法生成音符
  ├─ 添加高八度音符
  ├─ 分组到小节 (4/4 拍)
  └─ 设置调号、速度
        ↓
生成 Score 对象
        ↓
ScalePracticeSessionViewModel
  ├─ 包装 PracticeSessionViewModel
  ├─ 保存指法列表
  └─ 提供指法切换方法
        ↓
ScalePracticeSessionView
  ├─ 显示指法导航栏
  └─ 嵌入 PracticeSessionView
        ↓
用户练习
  ├─ 播放/暂停
  ├─ 变速
  ├─ 循环
  ├─ 切换指法
  └─ 指板同步显示
```

## 🎵 核心算法

### ScaleScoreBuilder

1. **生成单个指法的音符**
   ```swift
   let baseNotes = fingering.positions.map { pos -> ScoreNote in
       let pitch = pos.pitch(on: config)
       return ScoreNote(midiPitch: pitch.midiNumber, ...)
   }
   ```

2. **生成高八度音符**
   ```swift
   let highOctavePitches = scale.pitches(root: root).map { 
       Pitch.from(midi: $0.midiNumber + 12) 
   }
   let highOctaveFingerings = FingeringGenerator(config: config)
       .generate(pitches: highOctavePitches)
   ```

3. **分组到小节**
   ```swift
   for chunkStart in stride(from: 0, to: notes.count, by: notesPerMeasure) {
       let chunk = Array(notes[chunkStart..<chunkEnd])
       // 填充休止符
       measures.append(ScoreMeasure(...))
   }
   ```

4. **计算指法对应的小节索引**
   ```swift
   func measureIndexForFingering(fingeringIndex: Int) -> Int {
       var measureOffset = 0
       for i in 0..<fingeringIndex {
           let noteCount = fingerings[i].positions.count + highOctaveNoteCount
           measureOffset += (noteCount + notesPerMeasure - 1) / notesPerMeasure
       }
       return measureOffset
   }
   ```

## ✅ 测试要点

### 功能测试
- [ ] 从音阶库导航到练习设置
- [ ] 切换乐器(贝斯/吉他)
- [ ] 多选指法
- [ ] 调整速度
- [ ] 切换显示模式
- [ ] 生成多行乐谱
- [ ] 播放练习
- [ ] 切换指法
- [ ] 循环播放
- [ ] 变速播放
- [ ] 指板同步

### UI 测试
- [ ] iPhone 竖屏布局
- [ ] iPad 横屏布局
- [ ] 指法缩略图显示
- [ ] 指法导航栏滚动
- [ ] 按钮状态(禁用/启用)

### 边界情况
- [ ] 只有 1 个指法
- [ ] 选择所有指法
- [ ] 不选择任何指法(按钮禁用)
- [ ] 极快速度(200 BPM)
- [ ] 极慢速度(40 BPM)

## 🚀 使用方法

1. 打开应用,进入"音阶库"
2. 选择任意音阶或琶音
3. 选择根音(如 C)
4. 点击"开始音阶练习"按钮
5. 在设置页面:
   - 选择乐器(贝斯/吉他)
   - 选择要练习的指法(可多选)
   - 设置练习速度
   - 选择显示模式
6. 点击"开始练习"
7. 使用播放控制进行练习
8. 点击指法标签切换不同指法

## 📊 性能优化

1. **懒加载指法缩略图**: 使用 LazyVGrid
2. **缓存高八度指法**: 避免重复计算
3. **异步生成 Score**: 防止 UI 卡顿(未来优化)
4. **复用 PracticeSessionView**: 减少代码重复

## 🎓 技术亮点

1. **模块化设计**: ScaleScoreBuilder 独立于 UI
2. **状态管理**: 使用 @Observable 宏
3. **组合模式**: ScalePracticeSessionView 包装 PracticeSessionView
4. **类型安全**: 使用枚举管理显示模式
5. **可复用组件**: FingeringMultiSelectView 可独立使用

## 🔮 未来扩展

1. **琶音练习**: 已支持,无需额外工作
2. **自定义节奏型**: 可添加八分音符、十六分音符等
3. **指法难度分级**: 标记简单/中等/困难指法
4. **练习统计**: 记录每个指法的练习时长
5. **导出练习**: 将生成的 Score 导出为 MIDI/PDF
6. **和弦练习**: 复用相同架构

## 📝 总结

本次实现完整添加了音阶/琶音练习功能,包括:
- ✅ 核心算法(ScaleScoreBuilder)
- ✅ UI 组件(3 个新视图)
- ✅ 状态管理(2 个新 ViewModel)
- ✅ 导航集成(修改 ScaleDetailView)
- ✅ 数据模型扩展(ScoreSource)

所有代码已编译通过,无错误。下一步可以进行实际设备测试。
