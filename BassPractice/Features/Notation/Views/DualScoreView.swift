import SwiftUI

struct DualScoreView: View {
    @State private var workingScore: Score
    @State private var selectedNoteID: UUID?
    @State private var fretboardNotes: [FretboardNote] = []
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var config: FretboardConfig { workingScore.instrumentType.defaultFretboardConfig }
    private let onScoreChanged: ((Score) -> Void)?

    init(score: Score, onScoreChanged: ((Score) -> Void)? = nil) {
        _workingScore = State(initialValue: score)
        self.onScoreChanged = onScoreChanged
    }

    var body: some View {
        if sizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            notationSection
                .frame(minWidth: 400)

            fretboardSection
                .frame(minWidth: 300)
        }
    }

    private var iPhoneLayout: some View {
        ScrollView {
            VStack(spacing: 16) {
                notationSection
                    .frame(height: 250)

                fretboardSection
                    .frame(height: 200)
            }
            .padding()
        }
    }

    private var notationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("五线谱")
                .font(.headline)

            NotationContainerView(score: workingScore)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }

    private var fretboardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("指板图")
                    .font(.headline)
                Spacer()
                Button("自动标注") {
                    autoAnnotateFretboard()
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }

            let binding = Binding(
                get: { fretboardNotes },
                set: { fretboardNotes = $0 }
            )
            let selectedBinding = Binding(
                get: { selectedNoteID },
                set: { selectedNoteID = $0 }
            )

            FretboardView(
                config: config,
                notes: binding,
                selectedNoteID: selectedBinding,
                showFingerNumbers: true,
                noteColor: .blue,
                isEditable: true,
                onNoteMoved: { note in
                    if let sourceNoteID = note.sourceNoteID {
                        setFretboardPosition(for: sourceNoteID, position: note.position)
                    }
                }
            )
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)

            if let noteID = selectedNoteID,
               let note = fretboardNotes.first(where: { $0.id == noteID }) {
                noteInfoView(note: note)
            }
        }
        .padding(.vertical, 8)
    }

    private func noteInfoView(note: FretboardNote) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("选中: \(note.pitch.displayName)")
                .font(.caption)
                .fontWeight(.medium)
            Text("\(note.position.stringIndex + 1)弦 \(note.position.fretNumber)品")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }

    private func autoAnnotateFretboard() {
        let solver = StringFretSolver(config: config)
        var notes: [FretboardNote] = []
        var annotations: [FretboardAnnotation] = []
        var prevPosition: FretboardPosition? = nil

        for measure in workingScore.measures {
            for scoreNote in measure.notes where !scoreNote.isRest {
                let pitch = Pitch.from(midi: scoreNote.midiPitch)
                if let position = solver.bestPositionForPitch(pitch, near: prevPosition) {
                    notes.append(FretboardNote(
                        position: position,
                        pitch: pitch,
                        sourceNoteID: scoreNote.id
                    ))
                    annotations.append(FretboardAnnotation(
                        noteId: scoreNote.id,
                        position: position
                    ))
                    prevPosition = position
                }
            }
        }

        workingScore.fretboardAnnotations = annotations
        fretboardNotes = notes
        onScoreChanged?(workingScore)
    }

    private func setFretboardPosition(for sourceNoteID: UUID, position: FretboardPosition) {
        if let index = workingScore.fretboardAnnotations.firstIndex(where: { $0.noteId == sourceNoteID }) {
            workingScore.fretboardAnnotations[index].position = position
        } else {
            workingScore.fretboardAnnotations.append(
                FretboardAnnotation(noteId: sourceNoteID, position: position)
            )
        }

        if let index = fretboardNotes.firstIndex(where: { $0.sourceNoteID == sourceNoteID }) {
            fretboardNotes[index].position = position
        }

        workingScore.modifyTime = Date()
        onScoreChanged?(workingScore)
    }
}

struct ScaleNotationView: View {
    let scale: Scale
    let root: Pitch
    let fingering: FingeringPattern
    let instrumentType: InstrumentType
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var config: FretboardConfig { instrumentType.defaultFretboardConfig }
    private var exporter: MusicXMLExporter { MusicXMLExporter(config: config) }

    private var score: Score {
        let baseNotes = fingering.positions.map { pos -> ScoreNote in
            let pitch = pos.pitch(on: config)
            return ScoreNote(midiPitch: pitch.midiNumber, duration: .quarter, fretboardPosition: pos)
        }

        let highOctavePitches = scale.pitches(root: root).map { pitch in Pitch.from(midi: pitch.midiNumber + 12) }
        let highOctaveFingerings = FingeringGenerator(config: config).generate(pitches: highOctavePitches)
        let highPositions = highOctaveFingerings.first?.positions ?? []
        let highNotes = highPositions.map { pos -> ScoreNote in
            let pitch = pos.pitch(on: config)
            return ScoreNote(midiPitch: pitch.midiNumber, duration: .quarter, fretboardPosition: pos)
        }

        let allNotes = baseNotes + highNotes

        let measure = ScoreMeasure(
            measureNumber: 1,
            notes: allNotes
        )

        return Score(
            title: "\(root.noteName.displayName) \(scale.name)",
            timeSignature: TimeSignatureData(numerator: 4, denominator: 4),
            keySignature: keySignatureForRoot(root, scale: scale),
            measures: [measure]
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("\(root.noteName.displayName) \(scale.name)")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text(fingering.positionName)
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            if sizeClass == .regular {
                HStack(alignment: .top, spacing: 16) {
                    notationView
                        .frame(maxWidth: .infinity)
                    fretboardView
                        .frame(width: 350, height: 200)
                }
            } else {
                VStack(spacing: 16) {
                    notationView
                    fretboardView
                        .frame(height: 180)
                }
            }
        }
        .padding()
    }

    private var notationView: some View {
        NotationPreviewView(musicXML: exporter.export(score: score))
    }

    private var fretboardView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("指板图")
                .font(.caption)
                .foregroundColor(.secondary)

            // 原音高音符（使用传入的fingering）
            let baseNotes = fingering.positions.map { pos in
                FretboardNote(position: pos, config: config)
            }

            // 高八度音符（重新生成最优指法）
            let highOctavePitches = scale.pitches(root: root).map { pitch in
                Pitch.from(midi: pitch.midiNumber + 12)
            }
            let highOctaveFingerings = generateFingerings(for: highOctavePitches)
            let highOctaveNotes = highOctaveFingerings.first?.positions.map { pos in
                FretboardNote(position: pos, config: config)
            } ?? []

            let allNotes = baseNotes + highOctaveNotes
            let binding = Binding(get: { allNotes }, set: { _ in })
            let selectedBinding = Binding<UUID?>(get: { nil }, set: { _ in })

            FretboardView(
                config: config,
                notes: binding,
                selectedNoteID: selectedBinding,
                showFingerNumbers: true,
                noteColor: .blue,
                visibleFretRange: fullVisibleRange
            )
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
    }

    private func generateFingerings(for pitches: [Pitch]) -> [FingeringPattern] {
        let generator = FingeringGenerator(config: config)
        return generator.generate(pitches: pitches)
    }

    private func findPositionForPitch(_ pitch: Pitch) -> FretboardPosition? {
        for stringIdx in 0..<config.stringCount {
            let openPitch = config.tuning[stringIdx]
            let fretNumber = pitch.midiNumber - openPitch.midiNumber
            if fretNumber >= 0 && fretNumber <= config.fretCount {
                return FretboardPosition(stringIndex: stringIdx, fretNumber: fretNumber)
            }
        }
        return nil
    }

    private var fullVisibleRange: ClosedRange<Int> {
        // 基于原音阶和高八度音符的实际把位计算可见范围
        let baseFrets = fingering.positions.map(\.fretNumber)
        
        let highOctavePitches = scale.pitches(root: root).map { pitch in
            Pitch.from(midi: pitch.midiNumber + 12)
        }
        let highOctaveFingerings = generateFingerings(for: highOctavePitches)
        let highFrets = highOctaveFingerings.first?.positions.map(\.fretNumber) ?? []
        
        let allFrets = baseFrets + highFrets
        let minFret = allFrets.min() ?? 0
        let maxFret = allFrets.max() ?? 12
        let start = max(0, minFret - 1)
        let end = min(config.fretCount, maxFret + 2)
        return start...end
    }

    private func keySignatureForRoot(_ root: Pitch, scale: Scale) -> KeySignatureData {
        let rootFifths: [NoteName: Int] = [
            .C: 0, .G: 1, .D: 2, .A: 3, .E: 4, .B: 5,
            .Fs: 6, .Cs: 7, .F: -1, .As: -2, .Ds: -3, .Gs: -4
        ]
        let fifths = rootFifths[root.noteName] ?? 0
        let mode = scale.category == .minor ? "minor" : "major"
        return KeySignatureData(fifths: fifths, mode: mode)
    }
}
