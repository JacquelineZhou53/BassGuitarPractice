import SwiftUI

struct MetronomeView: View {
    @Bindable var metronome: MetronomeEngine
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("节拍器")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { metronome.isRunning },
                    set: { _ in toggleMetronome() }
                ))
                .labelsHidden()
            }

            HStack(spacing: 16) {
                beatIndicator

                VStack(alignment: .leading, spacing: 4) {
                    Text("♩ = \(metronome.tempo)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()

                    Slider(value: Binding(
                        get: { Double(metronome.tempo) },
                        set: { metronome.tempo = Int($0) }
                    ), in: 40...240, step: 1)

                    HStack {
                        Text("40")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("拍/分钟")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("240")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    metronome.tempo -= 5
                } label: {
                    Image(systemName: "minus.circle")
                }

                Button {
                    metronome.tempo += 5
                } label: {
                    Image(systemName: "plus.circle")
                }

                Spacer()

                Button {
                    metronome.soundEnabled.toggle()
                } label: {
                    Image(systemName: metronome.soundEnabled ? "speaker.wave.2" : "speaker.slash")
                }
            }
            .font(.title3)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var beatIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<metronome.beatsPerMeasure, id: \.self) { beat in
                Circle()
                    .fill(beat == metronome.currentBeatInMeasure && metronome.isRunning
                          ? (beat == 0 ? .red : .blue)
                          : Color.gray.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .scaleEffect(beat == metronome.currentBeatInMeasure && metronome.isRunning ? 1.2 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: metronome.currentBeatInMeasure)
            }
        }
    }

    private func toggleMetronome() {
        if metronome.isRunning {
            metronome.stop()
        } else {
            metronome.start()
        }
    }
}
