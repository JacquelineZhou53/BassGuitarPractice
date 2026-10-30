import SwiftUI

/// 指法多选组件 - 显示多个指法缩略图,支持多选
struct FingeringMultiSelectView: View {
    let fingerings: [FingeringPattern]
    let config: FretboardConfig
    @Binding var selectedIndices: Set<Int>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和操作按钮
            HStack {
                Text("选择指法 (\(selectedIndices.count)/\(fingerings.count))")
                    .font(.headline)
                
                Spacer()
                
                Button("全选") {
                    selectedIndices = Set(0..<fingerings.count)
                }
                .font(.caption)
                .buttonStyle(.bordered)
                
                Button("清空") {
                    selectedIndices.removeAll()
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .disabled(selectedIndices.isEmpty)
            }
            
            // 指法网格
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(Array(fingerings.enumerated()), id: \.offset) { index, fingering in
                    FingeringThumbnailCard(
                        fingering: fingering,
                        index: index,
                        isSelected: selectedIndices.contains(index),
                        config: config
                    ) {
                        toggleFingering(index)
                    }
                }
            }
        }
    }
    
    private func toggleFingering(_ index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }
}

/// 单个指法缩略图卡片
struct FingeringThumbnailCard: View {
    let fingering: FingeringPattern
    let index: Int
    let isSelected: Bool
    let config: FretboardConfig
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // 选择指示器
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
                
                Text("指法 \(index + 1)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            // 指板缩略图
            FingeringThumbnailPreview(
                fingering: fingering,
                config: config
            )
            .frame(height: 80)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(6)
            
            // 位置名称
            Text(fingering.positionName)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
        .onTapGesture(perform: onTap)
    }
}

/// 指板缩略图视图 - 简化的指板显示
struct FingeringThumbnailPreview: View {
    let fingering: FingeringPattern
    let config: FretboardConfig
    
    var body: some View {
        GeometryReader { geometry in
            let stringSpacing = geometry.size.height / CGFloat(config.stringCount - 1)
            let fretSpacing = geometry.size.width / CGFloat(maxVisibleFrets + 1)
            
            ZStack {
                // 绘制弦
                ForEach(0..<config.stringCount, id: \.self) { stringIdx in
                    let y = CGFloat(stringIdx) * stringSpacing
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                }
                
                // 绘制品丝
                ForEach(0...maxVisibleFrets, id: \.self) { fret in
                    let x = CGFloat(fret + 1) * fretSpacing
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                }
                
                // 绘制音符位置
                ForEach(Array(fingering.positions.enumerated()), id: \.offset) { _, position in
                    if position.fretNumber >= minVisibleFret && position.fretNumber <= maxVisibleFrets {
                        let x = CGFloat(position.fretNumber - minVisibleFret + 1) * fretSpacing - fretSpacing / 2
                        let y = CGFloat(position.stringIndex) * stringSpacing
                        
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                        
                        if let finger = position.finger {
                            Text("\(finger)")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(.white)
                                .position(x: x, y: y)
                        }
                    }
                }
            }
        }
    }
    
    private var minVisibleFret: Int {
        let frets = fingering.positions.map(\.fretNumber)
        return max(0, (frets.min() ?? 0) - 1)
    }
    
    private var maxVisibleFrets: Int {
        let frets = fingering.positions.map(\.fretNumber)
        return min(config.fretCount, (frets.max() ?? 12) + 2)
    }
}

// MARK: - Preview

#Preview("指法多选") {
    struct PreviewWrapper: View {
        @State private var selectedIndices: Set<Int> = [0, 2]
        
        var body: some View {
            FingeringMultiSelectView(
                fingerings: SampleData.fingerings,
                config: .standard5StringBass,
                selectedIndices: $selectedIndices
            )
            .padding()
        }
    }
    
    return PreviewWrapper()
}

// MARK: - Sample Data for Preview

struct SampleData {
    static let fingerings: [FingeringPattern] = {
        let config = FretboardConfig.standard5StringBass
        let cMajor = Scale.major
        let root = Pitch(noteName: .C, octave: 2)
        let pitches = cMajor.pitches(root: root)
        let generator = FingeringGenerator(config: config)
        return generator.generate(pitches: pitches)
    }()
}
