import Foundation

protocol EditorCommand {
    func execute(on score: inout Score)
    func undo(on score: inout Score)
    var description: String { get }
}

struct AddNoteCommand: EditorCommand {
    let measureIndex: Int
    let noteIndex: Int
    let note: ScoreNote

    var description: String { "添加音符" }

    func execute(on score: inout Score) {
        guard measureIndex < score.measures.count else { return }
        let idx = min(noteIndex, score.measures[measureIndex].notes.count)
        score.measures[measureIndex].notes.insert(note, at: idx)
    }

    func undo(on score: inout Score) {
        guard measureIndex < score.measures.count else { return }
        score.measures[measureIndex].notes.removeAll { $0.id == note.id }
    }
}

struct DeleteNoteCommand: EditorCommand {
    let measureIndex: Int
    let note: ScoreNote
    let originalIndex: Int

    var description: String { "删除音符" }

    func execute(on score: inout Score) {
        guard measureIndex < score.measures.count else { return }
        score.measures[measureIndex].notes.removeAll { $0.id == note.id }
    }

    func undo(on score: inout Score) {
        guard measureIndex < score.measures.count else { return }
        let idx = min(originalIndex, score.measures[measureIndex].notes.count)
        score.measures[measureIndex].notes.insert(note, at: idx)
    }
}

struct ModifyNoteCommand: EditorCommand {
    let measureIndex: Int
    let noteId: UUID
    let newNote: ScoreNote
    let oldNote: ScoreNote

    var description: String { "修改音符" }

    func execute(on score: inout Score) {
        guard measureIndex < score.measures.count,
              let idx = score.measures[measureIndex].notes.firstIndex(where: { $0.id == noteId }) else { return }
        score.measures[measureIndex].notes[idx] = newNote
    }

    func undo(on score: inout Score) {
        guard measureIndex < score.measures.count,
              let idx = score.measures[measureIndex].notes.firstIndex(where: { $0.id == noteId }) else { return }
        score.measures[measureIndex].notes[idx] = oldNote
    }
}

struct AddMeasureCommand: EditorCommand {
    let measure: ScoreMeasure

    var description: String { "添加小节" }

    func execute(on score: inout Score) {
        score.measures.append(measure)
    }

    func undo(on score: inout Score) {
        if score.measures.last?.id == measure.id {
            score.measures.removeLast()
        }
    }
}

struct DeleteMeasureCommand: EditorCommand {
    let measureIndex: Int
    let measure: ScoreMeasure

    var description: String { "删除小节" }

    func execute(on score: inout Score) {
        guard measureIndex < score.measures.count else { return }
        score.measures.remove(at: measureIndex)
    }

    func undo(on score: inout Score) {
        let idx = min(measureIndex, score.measures.count)
        score.measures.insert(measure, at: idx)
    }
}

struct SetFretboardPositionCommand: EditorCommand {
    let noteId: UUID
    let position: FretboardPosition?
    let oldPosition: FretboardPosition?

    var description: String { "设置指板位置" }

    func execute(on score: inout Score) {
        updateAnnotation(in: &score, position: position)
    }

    func undo(on score: inout Score) {
        updateAnnotation(in: &score, position: oldPosition)
    }

    private func updateAnnotation(in score: inout Score, position: FretboardPosition?) {
        if let idx = score.fretboardAnnotations.firstIndex(where: { $0.noteId == noteId }) {
            if let pos = position {
                score.fretboardAnnotations[idx].position = pos
            } else {
                score.fretboardAnnotations.remove(at: idx)
            }
        } else if let pos = position {
            score.fretboardAnnotations.append(FretboardAnnotation(noteId: noteId, position: pos))
        }
    }
}

struct ChangeTimeSignatureCommand: EditorCommand {
    let newTimeSignature: TimeSignatureData
    let oldTimeSignature: TimeSignatureData

    var description: String { "更改拍号" }

    func execute(on score: inout Score) {
        score.timeSignature = newTimeSignature
    }

    func undo(on score: inout Score) {
        score.timeSignature = oldTimeSignature
    }
}

struct ChangeKeySignatureCommand: EditorCommand {
    let newKeySignature: KeySignatureData
    let oldKeySignature: KeySignatureData

    var description: String { "更改调号" }

    func execute(on score: inout Score) {
        score.keySignature = newKeySignature
    }

    func undo(on score: inout Score) {
        score.keySignature = oldKeySignature
    }
}

struct ChangeTempoCommand: EditorCommand {
    let newTempo: Int
    let oldTempo: Int

    var description: String { "更改速度" }

    func execute(on score: inout Score) {
        score.tempo = newTempo
    }

    func undo(on score: inout Score) {
        score.tempo = oldTempo
    }
}
