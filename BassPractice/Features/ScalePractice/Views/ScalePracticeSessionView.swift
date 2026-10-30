import SwiftUI

/// 音阶练习会话视图 - 包装 PracticeSessionView 并添加指法导航
struct ScalePracticeSessionView: View {
    @State var viewModel: ScalePracticeSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    var body: some View {
        VStack(spacing: 0) {
            // 指法导航栏
            if viewModel.showFingeringNavigation && viewModel.fingerings.count > 1 {
                fingeringNavigationBar
                Divider()
            }
            
            // 嵌入现有的 PracticeSessionView
            PracticeSessionView(viewModel: viewModel.practiceViewModel)
        }
        .navigationTitle("音阶练习: \(viewModel.scale.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("返回") {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - 指法导航栏
    
    private var fingeringNavigationBar: some View {
        VStack(spacing: 8) {
            // 指法标签横向滚动
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(viewModel.fingerings.enumerated()), id: \.offset) { index, fingering in
                        fingeringBadge(
                            index: index,
                            fingering: fingering,
                            isCurrent: index == viewModel.currentFingeringIndex
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // 前后指法切换按钮
            HStack(spacing: 16) {
                Button {
                    viewModel.previousFingering()
                } label: {
                    Label("上一个", systemImage: "chevron.left")
                        .font(.caption)
                }
                .disabled(viewModel.fingerings.count <= 1)
                
                Spacer()
                
                Text(viewModel.currentFingeringName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Button {
                    viewModel.nextFingering()
                } label: {
                    Label("下一个", systemImage: "chevron.right")
                        .font(.caption)
                }
                .disabled(viewModel.fingerings.count <= 1)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - 指法标签
    
    private func fingeringBadge(index: Int, fingering: FingeringPattern, isCurrent: Bool) -> some View {
        Button {
            viewModel.switchToFingering(at: index)
        } label: {
            VStack(spacing: 4) {
                Text("指法 \(index + 1)")
                    .font(.caption2)
                    .fontWeight(.medium)
                
                Text(fingering.positionName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCurrent ? Color.blue : Color.gray.opacity(0.2))
            )
            .foregroundColor(isCurrent ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("音阶练习会话") {
    let scale = Scale.major
    let root = Pitch(noteName: .C, octave: 2)
    let config = FretboardConfig.standard5StringBass
    let pitches = scale.pitches(root: root)
    let fingerings = FingeringGenerator(config: config).generate(pitches: pitches)
    
    let builder = ScaleScoreBuilder(
        scale: scale,
        root: root,
        fingerings: Array(fingerings.prefix(3)),
        instrumentType: .bass,
        tempo: 80
    )
    
    let score = builder.buildScore()
    
    let viewModel = ScalePracticeSessionViewModel(
        score: score,
        fingerings: Array(fingerings.prefix(3)),
        scale: scale,
        root: root
    )
    
    NavigationStack {
        ScalePracticeSessionView(viewModel: viewModel)
    }
}
