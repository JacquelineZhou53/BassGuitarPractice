import SwiftUI
import Observation

enum InputMode {
    case pitch
    case rest
    case select
}

@Observable
class ScoreEditorViewModel {
    var score: Score
    var selectedMeasureIndex: Int = 0
    var selectedNoteId: UUID?
    var inputMode: InputMode = .pitch
    var selectedDuration: NoteDuration = .quarter
    var selectedVelocity: Int = 80
    var showFretboard: Bool = true
    var fretboardNotes: [FretboardNote] = []

    private var undoStack: [EditorCommand] = []
    private var redoStack: [EditorCommand] = []

    let config: FretboardConfig
    let solver: StringFretSolver

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    var currentMeasure: ScoreMeasure? {
        guard selectedMeasureIndex < score.measures.count else { return nil }
        return score.measures[selectedMeasureIndex]
    }

    var selectedNote: ScoreNote? {
        guard let noteId = selectedNoteId else { return nil }
        for measure in score.measures {
            if let note = measure.notes.first(where: { $0.id == noteId }) {
                return note
            }
        }
        return nil
    }

    var selectedNoteMeasureIndex: Int? {
        guard let noteId = selectedNoteId else { return nil }
        for (idx, measure) in score.measures.enumerated() {
            if measure.notes.contains(where: { $0.id == noteId }) {
                return idx
            }
        }
        return nil
    }

    init(score: Score? = nil, config: FretboardConfig = .standard5StringBass) {
        if let score = score {
            self.score = score
        } else {
            self.score = Score(
                title: "新曲谱",
                measures: [ScoreMeasure(measureNumber: 1, notes: [])]
            )
        }
        self.config = config
        self.solver = StringFretSolver(config: config)
        regenerateFretboardNotes()
    }

    func execute(_ command: EditorCommand) {
        command.execute(on: &score)
        undoStack.append(command)
        redoStack.removeAll()
        score.modifyTime = Date()
        regenerateFretboardNotes()
    }

    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo(on: &score)
        redoStack.append(command)
        score.modifyTime = Date()
        regenerateFretboardNotes()
    }

    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.execute(on: &score)
        undoStack.append(command)
        score.modifyTime = Date()
        regenerateFretboardNotes()
    }

    func addNote(at measureIndex: Int, pitch: Pitch) {
        let note = ScoreNote(
            midiPitch: pitch.midiNumber,
            duration: selectedDuration,
            velocity: selectedVelocity
        )

        let noteIndex: Int
        if let current = currentMeasure {
            noteIndex = current.notes.count
        } else {
            noteIndex = 0
        }

        let command = AddNoteCommand(
            measureIndex: measureIndex,
            noteIndex: noteIndex,
            note: note
        )
        execute(command)
        selectedNoteId = note.id
    }

    func addRest(at measureIndex: Int) {
        let note = ScoreNote.rest(duration: selectedDuration)
        let noteIndex = currentMeasure?.notes.count ?? 0

        let command = AddNoteCommand(
            measureIndex: measureIndex,
            noteIndex: noteIndex,
            note: note
        )
        execute(command)
    }

    func deleteSelectedNote() {
        guard let noteId = selectedNoteId,
              let measureIndex = selectedNoteMeasureIndex,
              let note = selectedNote,
              let noteIndex = score.measures[measureIndex].notes.firstIndex(where: { $0.id == noteId }) else { return }

        let command = DeleteNoteCommand(
            measureIndex: measureIndex,
            note: note,
            originalIndex: noteIndex
        )
        execute(command)
        selectedNoteId = nil
    }

    func modifySelectedNote(pitch: Pitch? = nil, duration: NoteDuration? = nil, velocity: Int? = nil) {
        guard let noteId = selectedNoteId,
              let measureIndex = selectedNoteMeasureIndex,
              let oldNote = selectedNote else { return }

        var newNote = oldNote
        if let pitch = pitch {
            newNote = ScoreNote(
                id: oldNote.id,
                midiPitch: pitch.midiNumber,
                duration: duration ?? oldNote.duration,
                velocity: velocity ?? oldNote.velocity,
                isRest: false,
                fretboardPosition: oldNote.fretboardPosition
            )
        } else if let duration = duration {
            newNote = ScoreNote(
                id: oldNote.id,
                midiPitch: oldNote.midiPitch,
                duration: duration,
                velocity: velocity ?? oldNote.velocity,
                isRest: oldNote.isRest,
                fretboardPosition: oldNote.fretboardPosition
            )
        }

        let command = ModifyNoteCommand(
            measureIndex: measureIndex,
            noteId: noteId,
            newNote: newNote,
            oldNote: oldNote
        )
        execute(command)
    }

    func addMeasure() {
        let measureNumber = score.measures.count + 1
        let measure = ScoreMeasure(measureNumber: measureNumber, notes: [])
        let command = AddMeasureCommand(measure: measure)
        execute(command)
        selectedMeasureIndex = score.measures.count - 1
    }

    func deleteMeasure(at index: Int) {
        guard score.measures.count > 1, index < score.measures.count else { return }
        let measure = score.measures[index]
        let command = DeleteMeasureCommand(measureIndex: index, measure: measure)
        execute(command)

        if selectedMeasureIndex >= score.measures.count {
            selectedMeasureIndex = score.measures.count - 1
        }
    }

    func setFretboardPosition(for noteId: UUID, position: FretboardPosition?) {
        let oldAnnotation = score.fretboardAnnotations.first { $0.noteId == noteId }
        let command = SetFretboardPositionCommand(
            noteId: noteId,
            position: position,
            oldPosition: oldAnnotation?.position
        )
        execute(command)
    }

    func setTimeSignature(_ timeSignature: TimeSignatureData) {
        let command = ChangeTimeSignatureCommand(
            newTimeSignature: timeSignature,
            oldTimeSignature: score.timeSignature
        )
        execute(command)
    }

    func setKeySignature(_ keySignature: KeySignatureData) {
        let command = ChangeKeySignatureCommand(
            newKeySignature: keySignature,
            oldKeySignature: score.keySignature
        )
        execute(command)
    }

    func setTempo(_ tempo: Int) {
        let command = ChangeTempoCommand(newTempo: tempo, oldTempo: score.tempo)
        execute(command)
    }

    func autoAnnotateFretboard() {
        var positions: [FretboardNote] = []
        var prevPosition: FretboardPosition? = nil

        for measure in score.measures {
            for note in measure.notes where !note.isRest {
                let pitch = Pitch.from(midi: note.midiPitch)
                if let position = solver.bestPositionForPitch(pitch, near: prevPosition) {
                    positions.append(FretboardNote(
                        position: position,
                        pitch: pitch,
                        sourceNoteID: note.id
                    ))
                    setFretboardPosition(for: note.id, position: position)
                    prevPosition = position
                }
            }
        }

        fretboardNotes = positions
    }

    func regenerateFretboardNotes() {
        var notes: [FretboardNote] = []
        var prevPosition: FretboardPosition? = nil
        let annotationsByNoteID = Dictionary(
            score.fretboardAnnotations.map { ($0.noteId, $0.position) },
            uniquingKeysWith: { _, latest in latest }
        )

        for measure in score.measures {
            for note in measure.notes where !note.isRest {
                let pitch = Pitch.from(midi: note.midiPitch)
                if let position = annotationsByNoteID[note.id] {
                    notes.append(FretboardNote(
                        position: position,
                        pitch: pitch,
                        sourceNoteID: note.id
                    ))
                    prevPosition = position
                } else if let position = solver.bestPositionForPitch(pitch, near: prevPosition) {
                    notes.append(FretboardNote(
                        position: position,
                        pitch: pitch,
                        sourceNoteID: note.id
                    ))
                    prevPosition = position
                }
            }
        }

        fretboardNotes = notes
    }

    func selectNote(_ noteId: UUID?) {
        selectedNoteId = noteId
    }

    func selectMeasure(_ index: Int) {
        guard index >= 0, index < score.measures.count else { return }
        selectedMeasureIndex = index
        selectedNoteId = nil
    }
}
