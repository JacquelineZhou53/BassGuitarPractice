import Foundation

struct FretboardPosition: Hashable, Codable {
    let stringIndex: Int
    let fretNumber: Int
    var finger: Int?

    init(stringIndex: Int, fretNumber: Int, finger: Int? = nil) {
        self.stringIndex = stringIndex
        self.fretNumber = fretNumber
        self.finger = finger
    }

    func pitch(on config: FretboardConfig) -> Pitch {
        let openString = config.tuning[stringIndex]
        return Pitch.from(midi: openString.midiNumber + fretNumber)
    }

    var isOnStandardDot: Bool {
        [3, 5, 7, 9, 12, 15, 17, 19, 21, 24].contains(fretNumber)
    }
}

struct FretboardNote: Identifiable, Hashable, Codable {
    let id: UUID
    var position: FretboardPosition
    var pitch: Pitch
    /// The note in the source score this fretboard marker belongs to, if any.
    /// Keeping this link lets edits write back to `Score.fretboardAnnotations`.
    var sourceNoteID: UUID?

    init(id: UUID = UUID(), position: FretboardPosition, pitch: Pitch, sourceNoteID: UUID? = nil) {
        self.id = id
        self.position = position
        self.pitch = pitch
        self.sourceNoteID = sourceNoteID
    }

    init(position: FretboardPosition, config: FretboardConfig, sourceNoteID: UUID? = nil) {
        self.id = UUID()
        self.position = position
        self.pitch = position.pitch(on: config)
        self.sourceNoteID = sourceNoteID
    }

    mutating func moveTo(string newIndex: Int, config: FretboardConfig) -> Bool {
        let newFret = pitch.midiNumber - config.tuning[newIndex].midiNumber
        guard newFret >= 0, newFret <= config.fretCount else { return false }
        self.position = FretboardPosition(
            stringIndex: newIndex,
            fretNumber: newFret,
            finger: self.position.finger
        )
        return true
    }

    func allValidPositions(on config: FretboardConfig) -> [FretboardPosition] {
        var positions: [FretboardPosition] = []
        for stringIndex in 0..<config.stringCount {
            let fret = pitch.midiNumber - config.tuning[stringIndex].midiNumber
            if fret >= 0 && fret <= config.fretCount {
                positions.append(FretboardPosition(
                    stringIndex: stringIndex,
                    fretNumber: fret,
                    finger: position.finger
                ))
            }
        }
        return positions
    }
}
