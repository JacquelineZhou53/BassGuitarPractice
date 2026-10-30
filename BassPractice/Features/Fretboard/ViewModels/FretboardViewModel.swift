import SwiftUI
import Observation

@Observable
class FretboardViewModel {
    var config: FretboardConfig
    var notes: [FretboardNote] = []
    var selectedNoteID: UUID?
    var highlightNotes: [FretboardNote] = []
    var showFingerNumbers: Bool = true
    var noteColor: Color = .blue
    var visibleFretRange: ClosedRange<Int>?

    let solver: StringFretSolver
    let map: FretboardMap

    init(config: FretboardConfig = .standard5StringBass) {
        self.config = config
        self.solver = StringFretSolver(config: config)
        self.map = FretboardMap(config: config)
    }

    func loadFingeringPattern(_ pattern: FingeringPattern, color: Color = .blue) {
        notes = pattern.positions.map { pos in
            let pitch = pos.pitch(on: config)
            return FretboardNote(position: pos, pitch: pitch)
        }
        noteColor = color
        selectedNoteID = nil
    }

    func loadScale(scale: Scale, root: Pitch, fingering: FingeringPattern? = nil) {
        if let fingering = fingering {
            loadFingeringPattern(fingering)
        } else {
            let generator = FingeringGenerator(config: config)
            let pitches = scale.pitches(root: root)
            let patterns = generator.generate(pitches: pitches)
            if let first = patterns.first {
                loadFingeringPattern(first)
            }
        }
    }

    func showAllPositions(for pitch: Pitch) {
        let positions = solver.allPositionsForPitch(pitch)
        highlightNotes = positions.map { pos in
            FretboardNote(position: pos, pitch: pitch)
        }
    }

    func clearHighlights() {
        highlightNotes = []
    }

    func moveSelectedNote(to stringIndex: Int) {
        guard let selectedID = selectedNoteID,
              let idx = notes.firstIndex(where: { $0.id == selectedID }) else { return }
        _ = notes[idx].moveTo(string: stringIndex, config: config)
    }

    func addNote(at position: FretboardPosition) {
        let note = FretboardNote(position: position, config: config)
        notes.append(note)
        selectedNoteID = note.id
    }

    func removeSelectedNote() {
        guard let selectedID = selectedNoteID else { return }
        notes.removeAll { $0.id == selectedID }
        selectedNoteID = nil
    }

    func clearNotes() {
        notes = []
        selectedNoteID = nil
        highlightNotes = []
    }
}
