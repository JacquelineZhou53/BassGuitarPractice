import SwiftUI

struct ScoreEditorView: View {
    @State var viewModel: ScoreEditorViewModel
    @State private var showSettings = false
    @State private var showExport = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    init(score: Score? = nil) {
        _viewModel = State(initialValue: ScoreEditorViewModel(score: score))
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            if sizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .navigationTitle(viewModel.score.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    viewModel.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!viewModel.canUndo)

                Button {
                    viewModel.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(!viewModel.canRedo)

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }

                Button {
                    showExport = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            ScoreSettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showExport) {
            ScoreExportView(score: viewModel.score)
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.undo()
            } label: {
                Label("撤销", systemImage: "arrow.uturn.backward")
            }
            .disabled(!viewModel.canUndo)

            Button {
                viewModel.redo()
            } label: {
                Label("重做", systemImage: "arrow.uturn.forward")
            }
            .disabled(!viewModel.canRedo)

            Divider()
                .frame(height: 20)

            Button {
                viewModel.autoAnnotateFretboard()
            } label: {
                Label("自动标注", systemImage: "wand.and.stars")
            }

            Spacer()

            if let note = viewModel.selectedNote {
                Button(role: .destructive) {
                    viewModel.deleteSelectedNote()
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
        .font(.caption)
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
    }

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            leftPanel
                .frame(minWidth: 280, maxWidth: 360)

            centerPanel

            if viewModel.showFretboard {
                rightPanel
                    .frame(minWidth: 300, maxWidth: 400)
            }
        }
    }

    private var iPhoneLayout: some View {
        ScrollView {
            VStack(spacing: 12) {
                centerPanel
                    .frame(height: 200)

                if viewModel.showFretboard {
                    fretboardSection
                        .frame(height: 180)
                }

                NoteInputBar(viewModel: viewModel)
                MeasureListView(viewModel: viewModel)
                MeasureNoteListView(viewModel: viewModel)
            }
            .padding()
        }
    }

    private var leftPanel: some View {
        VStack(spacing: 12) {
            NoteInputBar(viewModel: viewModel)
            MeasureListView(viewModel: viewModel)
            MeasureNoteListView(viewModel: viewModel)
            Spacer()
        }
        .padding(8)
    }

    private var centerPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("五线谱预览")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)

            NotationContainerView(score: viewModel.score)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(8)
    }

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("指板")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    viewModel.showFretboard.toggle()
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)

            fretboardContent
        }
        .padding(8)
    }

    private var fretboardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("指板")
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.showFretboard = false
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                }
            }

            fretboardContent
        }
    }

    private var fretboardContent: some View {
        VStack(spacing: 8) {
            let binding = Binding(
                get: { viewModel.fretboardNotes },
                set: { viewModel.fretboardNotes = $0 }
            )
            let selectedBinding = Binding<UUID?>(
                get: { viewModel.selectedNoteId },
                set: { viewModel.selectNote($0) }
            )

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
            .frame(height: 160)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            .onTapGesture { location in
                handleFretboardTap(at: location)
            }

            if let note = viewModel.selectedNote, !note.isRest {
                selectedNoteInfo(note)
            }
        }
    }

    private func selectedNoteInfo(_ note: ScoreNote) -> some View {
        let pitch = Pitch.from(midi: note.midiPitch)
        return VStack(alignment: .leading, spacing: 4) {
            Text("选中: \(pitch.displayName)")
                .font(.caption)
                .fontWeight(.medium)

            Text("可演奏位置:")
                .font(.caption2)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(viewModel.solver.allPositionsForPitch(pitch), id: \.self) { pos in
                        Button {
                            viewModel.setFretboardPosition(for: note.id, position: pos)
                        } label: {
                            Text("\(pos.stringIndex + 1)弦\(pos.fretNumber)品")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private func handleFretboardTap(at location: CGPoint) {
        guard viewModel.inputMode == .pitch else { return }
        guard let measureIndex = viewModel.selectedMeasureIndex as Int? else { return }

        let layout = FretboardLayout(
            config: viewModel.config,
            size: CGSize(width: 350, height: 160),
            visibleFretRange: nil
        )

        let stringIndex = layout.nearestString(to: location.y)
        let fretNumber = layout.nearestFret(to: location.x)

        guard let pitch = viewModel.config.tuning[stringIndex].transposed(by: fretNumber) as Pitch? else { return }

        let actualPitch = Pitch.from(midi: viewModel.config.tuning[stringIndex].midiNumber + fretNumber)
        viewModel.addNote(at: measureIndex, pitch: actualPitch)
    }
}

struct ScoreSettingsView: View {
    @Bindable var viewModel: ScoreEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("曲谱信息") {
                    TextField("标题", text: $viewModel.score.title)
                    TextField("作曲者", text: $viewModel.score.composer)
                }

                Section("拍号") {
                    HStack {
                        Text("分子")
                        Stepper(value: $viewModel.score.timeSignature.numerator, in: 1...12) {
                            Text("\(viewModel.score.timeSignature.numerator)")
                        }
                    }
                    HStack {
                        Text("分母")
                        Picker("", selection: $viewModel.score.timeSignature.denominator) {
                            Text("2").tag(2)
                            Text("4").tag(4)
                            Text("8").tag(8)
                            Text("16").tag(16)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("速度") {
                    HStack {
                        Text("BPM")
                        Stepper(value: $viewModel.score.tempo, in: 40...240) {
                            Text("\(viewModel.score.tempo)")
                        }
                    }
                }

                Section("调号") {
                    Picker("调", selection: Binding(
                        get: { viewModel.score.keySignature.fifths },
                        set: { viewModel.score.keySignature.fifths = $0 }
                    )) {
                        Text("Cb (♭7)").tag(-7)
                        Text("Gb (♭6)").tag(-6)
                        Text("Db (♭5)").tag(-5)
                        Text("Ab (♭4)").tag(-4)
                        Text("Eb (♭3)").tag(-3)
                        Text("Bb (♭2)").tag(-2)
                        Text("F (♭1)").tag(-1)
                        Text("C").tag(0)
                        Text("G (♯1)").tag(1)
                        Text("D (♯2)").tag(2)
                        Text("A (♯3)").tag(3)
                        Text("E (♯4)").tag(4)
                        Text("B (♯5)").tag(5)
                        Text("F# (♯6)").tag(6)
                        Text("C# (♯7)").tag(7)
                    }
                }
            }
            .navigationTitle("曲谱设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
