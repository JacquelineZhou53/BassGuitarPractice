import SwiftUI

struct FingeringComparisonView: View {
    @Bindable var viewModel: ScaleLibraryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("共 \(viewModel.fingerings.count) 种指法")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(Array(viewModel.fingerings.enumerated()), id: \.offset) { index, fingering in
                        fingeringCard(index: index, pattern: fingering)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("指法对比")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func fingeringCard(index: Int, pattern: FingeringPattern) -> some View {
        let isSelected = index == viewModel.selectedFingeringIndex
        let notes = pattern.positions.map { pos in
            FretboardNote(position: pos, config: viewModel.config)
        }
        let binding = Binding(
            get: { notes },
            set: { _ in }
        )
        let selectedBinding = Binding<UUID?>(
            get: { nil },
            set: { _ in }
        )
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .secondary)
                    Text("指法 \(index + 1)")
                        .font(.headline)
                }
                Spacer()
                Text(pattern.positionName)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                if !isSelected {
                    Button("选择") {
                        viewModel.selectFingering(at: index)
                        dismiss()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }

            FretboardView(
                config: viewModel.config,
                notes: binding,
                selectedNoteID: selectedBinding,
                showFingerNumbers: true,
                noteColor: isSelected ? .blue : .gray,
                visibleFretRange: visibleRange(for: pattern)
            )
            .frame(height: 140)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )

            HStack(spacing: 4) {
                ForEach(Array(pattern.positions.enumerated()), id: \.offset) { _, pos in
                    let pitch = pos.pitch(on: viewModel.config)
                    VStack(spacing: 2) {
                        Text(pitch.noteName.displayName)
                            .font(.system(size: 10, weight: .medium))
                        Text("\(pos.stringIndex + 1)弦\(pos.fretNumber)品")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.05) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.1), radius: isSelected ? 6 : 4, x: 0, y: isSelected ? 3 : 2)
        .padding(.horizontal)
        .onTapGesture {
            viewModel.selectFingering(at: index)
            dismiss()
        }
    }

    private func visibleRange(for pattern: FingeringPattern) -> ClosedRange<Int> {
        let minFret = pattern.positions.map(\.fretNumber).min() ?? 0
        let maxFret = pattern.positions.map(\.fretNumber).max() ?? 12
        let start = max(0, minFret - 1)
        let end = min(viewModel.config.fretCount, maxFret + 2)
        return start...end
    }
}
