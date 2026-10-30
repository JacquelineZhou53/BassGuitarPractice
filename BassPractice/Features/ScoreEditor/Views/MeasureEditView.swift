import SwiftUI

struct MeasureListView: View {
    @Bindable var viewModel: ScoreEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("小节列表")
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.addMeasure()
                } label: {
                    Label("添加", systemImage: "plus.circle")
                }
                .font(.caption)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(viewModel.score.measures.enumerated()), id: \.element.id) { index, measure in
                        measureCell(index: index, measure: measure)
                    }
                }
            }
        }
    }

    private func measureCell(index: Int, measure: ScoreMeasure) -> some View {
        let isSelected = index == viewModel.selectedMeasureIndex
        let noteCount = measure.notes.count

        return Button {
            viewModel.selectMeasure(index)
        } label: {
            VStack(spacing: 4) {
                Text("第\(index + 1)小节")
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)

                Text("\(noteCount)个音符")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(spacing: 2) {
                    ForEach(measure.notes.prefix(8), id: \.id) { note in
                        Circle()
                            .fill(note.isRest ? Color.gray : Color.blue)
                            .frame(width: 6, height: 6)
                    }
                    if measure.notes.count > 8 {
                        Text("+\(measure.notes.count - 8)")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 80, height: 70)
            .background(isSelected ? Color.blue.opacity(0.15) : Color.gray.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if viewModel.score.measures.count > 1 {
                Button(role: .destructive) {
                    viewModel.deleteMeasure(at: index)
                } label: {
                    Label("删除小节", systemImage: "trash")
                }
            }
        }
    }
}

struct MeasureNoteListView: View {
    @Bindable var viewModel: ScoreEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("音符列表")
                    .font(.headline)
                Spacer()
                if let measure = viewModel.currentMeasure {
                    Text("共 \(measure.notes.count) 个音符")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let measure = viewModel.currentMeasure {
                if measure.notes.isEmpty {
                    emptyMeasureView
                } else {
                    noteList(measure: measure)
                }
            }
        }
    }

    private var emptyMeasureView: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.title)
                .foregroundColor(.secondary)
            Text("空小节")
                .font(.caption)
                .foregroundColor(.secondary)

            if viewModel.inputMode == .pitch {
                Text("在指板上点击添加音符")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else if viewModel.inputMode == .rest {
                Button("插入休止符") {
                    viewModel.addRest(at: viewModel.selectedMeasureIndex)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private func noteList(measure: ScoreMeasure) -> some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(Array(measure.notes.enumerated()), id: \.element.id) { index, note in
                    noteRow(index: index, note: note)
                }
            }
        }
        .frame(maxHeight: 200)
    }

    private func noteRow(index: Int, note: ScoreNote) -> some View {
        let isSelected = note.id == viewModel.selectedNoteId
        let pitch = Pitch.from(midi: note.midiPitch)

        return Button {
            viewModel.selectNote(note.id)
        } label: {
            HStack {
                Text("\(index + 1)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                if note.isRest {
                    Text("休止")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text(pitch.noteName.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(pitch.octave)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(durationLabel(note.duration))
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)

                if let annotation = viewModel.score.fretboardAnnotations.first(where: { $0.noteId == note.id }) {
                    Text("\(annotation.position.stringIndex + 1)弦\(annotation.position.fretNumber)品")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                viewModel.selectNote(note.id)
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            Button(role: .destructive) {
                viewModel.selectedNoteId = note.id
                viewModel.deleteSelectedNote()
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private func durationLabel(_ duration: NoteDuration) -> String {
        switch duration {
        case .whole: return "全"
        case .half: return "二分"
        case .quarter: return "四分"
        case .eighth: return "八分"
        case .sixteenth: return "十六分"
        case .thirtySecond: return "三十二分"
        case .dottedHalf, .dottedQuarter, .dottedEighth: return "附点"
        case .eighthTriplet, .sixteenthTriplet: return "连音"
        }
    }
}
