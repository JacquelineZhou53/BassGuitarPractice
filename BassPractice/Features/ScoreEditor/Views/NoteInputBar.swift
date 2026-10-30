import SwiftUI

struct NoteInputBar: View {
    @Bindable var viewModel: ScoreEditorViewModel

    var body: some View {
        VStack(spacing: 8) {
            modeSelector
            durationSelector
            velocitySlider
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var modeSelector: some View {
        Picker("输入模式", selection: $viewModel.inputMode) {
            Text("音符").tag(InputMode.pitch)
            Text("休止").tag(InputMode.rest)
            Text("选择").tag(InputMode.select)
        }
        .pickerStyle(.segmented)
    }

    private var durationSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                durationButton(.whole, label: "全", icon: "𝅝")
                durationButton(.half, label: "二分", icon: "𝅗𝅥")
                durationButton(.quarter, label: "四分", icon: "♩")
                durationButton(.eighth, label: "八分", icon: "♪")
                durationButton(.sixteenth, label: "十六分", icon: "𝅘𝅥𝅯")
            }
        }
    }

    private func durationButton(_ duration: NoteDuration, label: String, icon: String) -> some View {
        let isSelected = viewModel.selectedDuration == duration
        return Button {
            viewModel.selectedDuration = duration
        } label: {
            VStack(spacing: 2) {
                Text(icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
            .frame(width: 52, height: 52)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var velocitySlider: some View {
        HStack {
            Text("力度")
                .font(.caption)
                .foregroundColor(.secondary)
            Slider(value: Binding(
                get: { Double(viewModel.selectedVelocity) },
                set: { viewModel.selectedVelocity = Int($0) }
            ), in: 20...127, step: 1)
            Text("\(viewModel.selectedVelocity)")
                .font(.caption)
                .frame(width: 30)
        }
    }
}
