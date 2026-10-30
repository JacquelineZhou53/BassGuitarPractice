import SwiftUI

/// 音阶练习设置页面 - 配置乐器、指法、速度等参数
struct ScalePracticeSetupView: View {
    @State private var viewModel: ScalePracticeSetupViewModel
    @Environment(\.dismiss) private var dismiss
    
    let scale: Scale
    let root: Pitch
    let fingerings: [FingeringPattern]
    let initialInstrumentType: InstrumentType
    
    init(
        scale: Scale,
        root: Pitch,
        fingerings: [FingeringPattern],
        instrumentType: InstrumentType
    ) {
        self.scale = scale
        self.root = root
        self.fingerings = fingerings
        self.initialInstrumentType = instrumentType
        _viewModel = State(initialValue: ScalePracticeSetupViewModel(
            scale: scale,
            root: root,
            fingerings: fingerings,
            instrumentType: instrumentType
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 音阶信息卡片
                    scaleInfoCard
                    
                    // 乐器选择
                    instrumentSelector
                    
                    // 指法选择
                    fingeringSelector
                    
                    // 速度设置
                    tempoControl
                    
                    // 显示模式
                    displayModeSelector
                    
                    // 开始练习按钮
                    startButton
                }
                .padding()
            }
            .navigationTitle("音阶练习设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - 音阶信息卡片
    
    private var scaleInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(root.noteName.displayName) \(scale.name)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(scale.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "music.note.list")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("音程结构")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(scale.intervals.map { $0.name }.joined(separator: " - "))
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("可用指法")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text("\(fingerings.count) 种")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - 乐器选择
    
    private var instrumentSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("乐器")
                .font(.headline)
            
            Picker("乐器", selection: $viewModel.instrumentType) {
                ForEach(InstrumentType.allCases, id: \.self) { instrument in
                    Text(instrument.displayName).tag(instrument)
                }
            }
            .pickerStyle(.segmented)
            
            Text(viewModel.instrumentType == .bass 
                 ? "五弦贝斯 (B-E-A-D-G)" 
                 : "六弦吉他 (E-A-D-G-B-E)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - 指法选择
    
    private var fingeringSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择指法")
                .font(.headline)
            
            FingeringMultiSelectView(
                fingerings: fingerings,
                config: viewModel.instrumentType.defaultFretboardConfig,
                selectedIndices: $viewModel.selectedFingeringIndices
            )
            
            if viewModel.selectedFingeringIndices.isEmpty {
                Text("请至少选择一种指法")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - 速度设置
    
    private var tempoControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("练习速度")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.tempo) BPM")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            HStack(spacing: 16) {
                Button {
                    viewModel.tempo = max(40, viewModel.tempo - 5)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                
                Slider(
                    value: Binding(
                        get: { Double(viewModel.tempo) },
                        set: { viewModel.tempo = Int($0) }
                    ),
                    in: 40...200,
                    step: 1
                )
                
                Button {
                    viewModel.tempo = min(200, viewModel.tempo + 5)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            
            Text("建议: 慢速开始,逐步提高")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - 显示模式
    
    private var displayModeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("显示模式")
                .font(.headline)
            
            Picker("显示模式", selection: $viewModel.displayMode) {
                Text("仅显示选中指法").tag(ScalePracticeDisplayMode.selectedOnly)
                Text("显示所有指法").tag(ScalePracticeDisplayMode.allFingerings)
            }
            .pickerStyle(.segmented)
            
            Text(viewModel.displayMode == .selectedOnly
                 ? "只显示你选择的指法"
                 : "显示所有可用指法,方便对比练习")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - 开始按钮
    
    private var startButton: some View {
        NavigationLink {
            ScalePracticeSessionView(viewModel: buildSessionViewModel())
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("开始练习")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                viewModel.selectedFingeringIndices.isEmpty 
                    ? Color.gray 
                    : Color.blue
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.selectedFingeringIndices.isEmpty)
    }
    
    // MARK: - 构建练习会话 ViewModel
    
    private func buildSessionViewModel() -> ScalePracticeSessionViewModel {
        // 根据显示模式确定要使用的指法
        let practiceFingerings: [FingeringPattern]
        if viewModel.displayMode == .selectedOnly {
            practiceFingerings = viewModel.selectedFingeringIndices
                .sorted()
                .map { fingerings[$0] }
        } else {
            practiceFingerings = fingerings
        }
        
        // 构建 Score
        let builder = ScaleScoreBuilder(
            scale: scale,
            root: root,
            fingerings: practiceFingerings,
            instrumentType: viewModel.instrumentType,
            tempo: viewModel.tempo
        )
        
        let score = builder.buildScore()
        
        // 创建练习会话 ViewModel
        return ScalePracticeSessionViewModel(
            score: score,
            fingerings: practiceFingerings,
            scale: scale,
            root: root
        )
    }
}

// MARK: - Preview

#Preview("音阶练习设置") {
    struct PreviewWrapper: View {
        @State private var showSetup = true
        
        var body: some View {
            Button("打开设置") {
                showSetup = true
            }
            .sheet(isPresented: $showSetup) {
                NavigationStack {
                    let scale = Scale.major
                    let root = Pitch(noteName: .C, octave: 2)
                    let config = FretboardConfig.standard5StringBass
                    let pitches = scale.pitches(root: root)
                    let fingerings = FingeringGenerator(config: config).generate(pitches: pitches)
                    
                    ScalePracticeSetupView(
                        scale: scale,
                        root: root,
                        fingerings: fingerings,
                        instrumentType: .bass
                    )
                }
            }
        }
    }
    
    return PreviewWrapper()
}
