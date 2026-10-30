import SwiftUI

struct ScaleDetailView: View {
    @Bindable var viewModel: ScaleLibraryViewModel
    var initialScale: Scale?
    @State private var showFingeringComparison = false
    @State private var showScalePractice = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                if viewModel.selectedScale != nil {
                    scaleInfoSection
                    rootNoteSelector
                }
                if viewModel.isSelectedComplete {
                    ScaleNotationView(
                        scale: viewModel.selectedScale!,
                        root: viewModel.selectedRoot!,
                        fingering: viewModel.currentFingering!,
                        instrumentType: viewModel.instrumentType
                    )
                    fingeringSelectorSection
                    practiceButton
                    noteInfoSection
                } else if viewModel.selectedScale != nil {
                    selectRootPrompt
                }
            }
            .padding()
        }
        .navigationTitle(displayTitle)
        .onAppear {
            if let scale = initialScale, viewModel.selectedScale?.id != scale.id {
                viewModel.selectScale(scale)
            }
        }
        .sheet(isPresented: $showFingeringComparison) {
            FingeringComparisonView(viewModel: viewModel)
        }
    }

    private var displayTitle: String {
        guard let scale = viewModel.selectedScale else { return "详情" }
        if let root = viewModel.selectedRoot {
            return "\(root.noteName.displayName) \(scale.name)"
        }
        return scale.name
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let scale = viewModel.selectedScale {
                Text(scale.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(scale.category.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var scaleInfoSection: some View {
        Group {
            if let scale = viewModel.selectedScale {
                VStack(alignment: .leading, spacing: 12) {
                    // 音程结构
                    VStack(alignment: .leading, spacing: 6) {
                        Text("音程结构")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 4) {
                            ForEach(Array(scale.intervals.enumerated()), id: \.offset) { index, interval in
                                IntervalChip(interval: interval, isLast: index == scale.intervals.count - 1)
                            }
                        }
                    }
                    
                    // 全半音关系
                    VStack(alignment: .leading, spacing: 6) {
                        Text("全音/半音关系")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(wholeHalfPattern(for: scale))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    // 音阶描述
                    if let description = scaleDescription(for: scale) {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }

    private func wholeHalfPattern(for scale: Scale) -> String {
        var pattern = ""
        for i in 0..<(scale.intervals.count - 1) {
            let semitones = scale.intervals[i + 1].semitones - scale.intervals[i].semitones
            if semitones == 2 {
                pattern += "全"
            } else if semitones == 1 {
                pattern += "半"
            } else {
                pattern += "\(semitones)"
            }
            if i < scale.intervals.count - 2 {
                pattern += " - "
            }
        }
        return pattern
    }

    private func scaleDescription(for scale: Scale) -> String? {
        switch scale.id {
        case "major":
            return "大调音阶是最常用的音阶之一，具有明亮、欢快的色彩。由7个音符组成，加上八度共8个音符。"
        case "natural_minor":
            return "自然小调音阶具有柔和、忧郁的色彩。是大调音阶的关系小调，使用相同的调号。"
        case "harmonic_minor":
            return "和声小调在自然小调的基础上升高了第七级音，创造出独特的东方色彩。常用于古典音乐和爵士乐。"
        case "melodic_minor":
            return "旋律小调在上行时升高第六级和第七级音，下行时恢复自然小调。结合了和声小调和自然小调的特点。"
        case "dorian":
            return "Dorian调式是小调调式的一种，与自然小调相比升高了第六级音。常用于爵士乐和摇滚乐。"
        case "phrygian":
            return "Phrygian调式具有西班牙/弗拉门戈风格，第二级音降低，创造独特的异域色彩。"
        case "lydian":
            return "Lydian调式是大调调式的一种，第四级音升高（增四度）。具有梦幻、空灵的感觉。"
        case "mixolydian":
            return "Mixolydian调式是属七和弦对应的调式，第七级音降低。广泛用于布鲁斯、摇滚和流行音乐。"
        case "locrian":
            return "Locrian调式是最不稳定的调式，第五级音降低（减五度）。很少在实际音乐中使用。"
        case "major_pentatonic":
            return "大调五声音阶去掉了大调中的第四级和第七级音（半音关系的音），使音阶更加和谐。广泛用于流行、民谣和摇滚。"
        case "minor_pentatonic":
            return "小调五声音阶是布鲁斯和摇滚乐中最常用的音阶。由五个音符组成，易于演奏且听起来很酷。"
        case "blues":
            return "布鲁斯音阶在小调五声的基础上增加了降五度音（蓝调音），创造出经典的布鲁斯色彩。"
        case "major_blues":
            return "大调布鲁斯音阶在大调五声的基础上增加了降三级音，具有明亮但略带忧郁的色彩。"
        case "whole_tone":
            return "全音阶由六个全音组成，没有半音关系。德彪西等印象派作曲家常用，具有模糊、梦幻的效果。"
        case "diminished":
            return "减音阶交替使用全音和半音，对称性强。常用于爵士乐和现代古典音乐中制造紧张感。"
        case "chromatic":
            return "半音阶包含所有十二个半音，是最完整的音阶形式。主要用于练习和理论分析。"
        default:
            return nil
        }
    }

    private var selectRootPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap")
                .font(.title)
                .foregroundColor(.secondary)
            Text("请选择根音")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var rootNoteSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("根音")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(viewModel.rootNotes, id: \.self) { root in
                    Button {
                        viewModel.selectRoot(root)
                    } label: {
                        Text(root.noteName.displayName)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.selectedRoot == root
                                    ? Color.blue
                                    : Color.gray.opacity(0.1)
                            )
                            .foregroundColor(
                                viewModel.selectedRoot == root ? .white : .primary
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var fingeringSelectorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("指法选择 (\(viewModel.fingerings.count) 种)")
                    .font(.headline)
                Spacer()
                if viewModel.fingerings.count > 1 {
                    Button("对比视图") {
                        showFingeringComparison = true
                    }
                    .font(.subheadline)
                }
            }

            if viewModel.fingerings.isEmpty {
                Text("正在生成指法...")
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 6) {
                        ForEach(Array(viewModel.fingerings.enumerated()), id: \.offset) { index, fingering in
                            FingeringBadgeView(
                                pattern: fingering,
                                isSelected: index == viewModel.selectedFingeringIndex,
                                onTap: {
                                    viewModel.selectFingering(at: index)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 50)
            }
        }
    }
    
    private var practiceButton: some View {
        Button {
            showScalePractice = true
        } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                Text("开始音阶练习")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isSelectedComplete)
        .sheet(isPresented: $showScalePractice) {
            if let scale = viewModel.selectedScale,
               let root = viewModel.selectedRoot {
                NavigationStack {
                    ScalePracticeSetupView(
                        scale: scale,
                        root: root,
                        fingerings: viewModel.fingerings,
                        instrumentType: viewModel.instrumentType
                    )
                }
            }
        }
    }

    private var noteInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("音阶音符")
                .font(.headline)

            if let scale = viewModel.selectedScale, let root = viewModel.selectedRoot {
                let pitches = scale.pitches(root: root)
                FlowLayout(spacing: 8) {
                    ForEach(Array(pitches.enumerated()), id: \.offset) { index, pitch in
                        Text(pitch.noteName.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }
                }
            }
        }
    }
}

struct FingeringFretboardView: View {
    let config: FretboardConfig
    let pattern: FingeringPattern
    var showFingerNumbers: Bool = true

    var body: some View {
        let notes = pattern.positions.map { pos in
            FretboardNote(position: pos, config: config)
        }
        let binding = Binding(
            get: { notes },
            set: { _ in }
        )
        let selectedBinding = Binding<UUID?>(
            get: { nil },
            set: { _ in }
        )

        FretboardView(
            config: config,
            notes: binding,
            selectedNoteID: selectedBinding,
            showFingerNumbers: showFingerNumbers,
            noteColor: .blue
        )
    }
}

struct FingeringThumbnailView: View {
    let config: FretboardConfig
    let pattern: FingeringPattern
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(pattern.positionName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .secondary)

                let notes = pattern.positions.map { pos in
                    FretboardNote(position: pos, config: config)
                }
                let binding = Binding(
                    get: { notes },
                    set: { _ in }
                )
                let selectedBinding = Binding<UUID?>(
                    get: { nil },
                    set: { _ in }
                )

                FretboardView(
                    config: config,
                    notes: binding,
                    selectedNoteID: selectedBinding,
                    showFingerNumbers: false,
                    noteColor: isSelected ? .white : .blue,
                    visibleFretRange: visibleRange
                )
                .frame(height: 60)
            }
            .padding(8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(8)
            .frame(width: 200)
        }
        .buttonStyle(.plain)
    }

    private var visibleRange: ClosedRange<Int> {
        let minFret = pattern.positions.map(\.fretNumber).min() ?? 0
        let maxFret = pattern.positions.map(\.fretNumber).max() ?? 12
        let start = max(0, minFret - 1)
        let end = min(config.fretCount, maxFret + 2)
        return start...end
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

struct IntervalChip: View {
    let interval: Interval
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Text(interval.name)
                .font(.caption2)
                .fontWeight(.medium)
            if !isLast {
                Text(semitoneText)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(4)
    }
    
    private var semitoneText: String {
        let semitones = interval.semitones
        if semitones == 0 { return "根音" }
        if semitones == 1 { return "半音" }
        if semitones == 2 { return "全音" }
        return "\(semitones)半音"
    }
}

struct FingeringBadgeView: View {
    let pattern: FingeringPattern
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "hand.tap.fill" : "hand.tap")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(pattern.positionName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
