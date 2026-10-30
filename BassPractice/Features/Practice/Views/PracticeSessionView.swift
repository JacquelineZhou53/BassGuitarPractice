import SwiftUI

struct PracticeSessionView: View {
    @State var viewModel: PracticeSessionViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        VStack(spacing: 0) {
            playbackControlBar
            Divider()

            if sizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .navigationTitle("练习: \(viewModel.score.title)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var playbackControlBar: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.stop()
            } label: {
                Image(systemName: "stop.fill")
            }

            Button {
                viewModel.togglePlayPause()
            } label: {
                Image(systemName: viewModel.playbackEngine.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
            }

            Text(viewModel.formattedPracticeTime)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(.secondary)

            Spacer()

            if viewModel.playbackEngine.isPlaying {
                ProgressView(value: viewModel.playbackEngine.playbackProgress)
                    .frame(width: 100)
            }

            Text("第\(viewModel.playbackEngine.currentMeasureIndex + 1)小节")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            leftControlPanel
                .frame(minWidth: 300, maxWidth: 380)

            centerView

            rightFretboardPanel
                .frame(minWidth: 300, maxWidth: 400)
        }
    }

    private var iPhoneLayout: some View {
        ScrollView {
            VStack(spacing: 12) {
                centerView
                    .frame(height: 200)

                fretboardSection
                    .frame(height: 160)

                tempoControlSection
                loopControlSection
                MetronomeView(metronome: viewModel.metronome)
            }
            .padding()
        }
    }

    private var leftControlPanel: some View {
        ScrollView {
            VStack(spacing: 16) {
                tempoControlSection
                loopControlSection
                MetronomeView(metronome: viewModel.metronome)
            }
            .padding(8)
        }
    }

    private var centerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("五线谱")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)

            NotationContainerView(score: viewModel.score)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(8)
    }

    private var rightFretboardPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("指板")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)

            fretboardContent
        }
        .padding(8)
    }

    private var fretboardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("指板")
                .font(.headline)
            fretboardContent
        }
    }

    private var fretboardContent: some View {
        let binding = Binding(
            get: { viewModel.currentFretboardNotes },
            set: { viewModel.updateFretboardNotes($0) }
        )
        let selectedBinding = Binding<UUID?>(
            get: { viewModel.selectedFretboardNoteID },
            set: { viewModel.selectedFretboardNoteID = $0 }
        )

        return VStack(alignment: .leading, spacing: 4) {
            FretboardView(
                config: viewModel.config,
                notes: binding,
                selectedNoteID: selectedBinding,
                showFingerNumbers: true,
                noteColor: .blue,
                isEditable: true,
                onNoteMoved: { note in
                    if let sourceNoteID = note.sourceNoteID {
                        viewModel.setFretboardPosition(for: sourceNoteID, position: note.position)
                    }
                }
            )
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)

            Text("点击音符后，上下拖动到其他弦可自动换把；红色叉号表示该弦没有对应品位")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var tempoControlSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("速度控制")
                    .font(.headline)
                Spacer()
                Button("重置") {
                    viewModel.resetToOriginalTempo()
                }
                .font(.caption)
            }

            HStack {
                Text("♩ = \(viewModel.practiceTempo)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .monospacedDigit()
                Spacer()
                Text("\(viewModel.tempoPercentage)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Slider(value: Binding(
                get: { Double(viewModel.practiceTempo) },
                set: { viewModel.setPracticeTempo(Int($0)) }
            ), in: 30...Double(viewModel.originalTempo * 2), step: 1)

            HStack(spacing: 8) {
                speedPresetButton(label: "50%", rate: 0.5)
                speedPresetButton(label: "75%", rate: 0.75)
                speedPresetButton(label: "100%", rate: 1.0)
                speedPresetButton(label: "125%", rate: 1.25)
            }

            Toggle("慢速模式", isOn: Binding(
                get: { viewModel.isSlowMode },
                set: { viewModel.setSlowMode(enabled: $0) }
            ))

            if viewModel.isSlowMode {
                HStack {
                    Text("速度")
                        .font(.caption)
                    Slider(value: Binding(
                        get: { viewModel.slowModeRate },
                        set: { viewModel.setSlowModeRate($0) }
                    ), in: 0.25...1.0, step: 0.05)
                    Text("\(Int(viewModel.slowModeRate * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func speedPresetButton(label: String, rate: Double) -> some View {
        let isSelected = abs(viewModel.slowModeRate - rate) < 0.01
        return Button {
            viewModel.setSlowModeRate(rate)
            if rate < 1.0 {
                viewModel.setSlowMode(enabled: true)
            }
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private var loopControlSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("循环设置")
                    .font(.headline)
                Spacer()
                if viewModel.loopEnabled {
                    Button("清除") {
                        viewModel.clearLoop()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }

            Toggle("启用循环", isOn: Binding(
                get: { viewModel.loopEnabled },
                set: { enabled in
                    if enabled {
                        let start = max(0, viewModel.playbackEngine.currentMeasureIndex)
                        let end = min(viewModel.score.measures.count - 1, start + 3)
                        viewModel.setLoop(start: start, end: end)
                    } else {
                        viewModel.clearLoop()
                    }
                }
            ))

            if viewModel.loopEnabled, let range = viewModel.loopRange {
                HStack {
                    Text("范围:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Stepper("起: 第\(range.startMeasure + 1)小节",
                            value: Binding(
                                get: { range.startMeasure },
                                set: { viewModel.setLoop(start: $0, end: range.endMeasure) }
                            ),
                            in: 0...range.endMeasure)
                    .font(.caption)
                }

                HStack {
                    Text("     ")
                        .font(.caption)

                    Stepper("止: 第\(range.endMeasure + 1)小节",
                            value: Binding(
                                get: { range.endMeasure },
                                set: { viewModel.setLoop(start: range.startMeasure, end: $0) }
                            ),
                            in: range.startMeasure...(viewModel.score.measures.count - 1))
                    .font(.caption)
                }

                HStack {
                    Text("循环次数: \(viewModel.repeatCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("共 \(range.measureCount) 小节")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
