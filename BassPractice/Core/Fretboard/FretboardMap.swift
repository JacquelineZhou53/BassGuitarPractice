import Foundation

struct FretboardMap {
    let config: FretboardConfig

    init(config: FretboardConfig) {
        self.config = config
    }

    func pitch(at stringIndex: Int, fret: Int) -> Pitch? {
        guard stringIndex >= 0, stringIndex < config.stringCount else { return nil }
        guard fret >= 0, fret <= config.fretCount else { return nil }
        return Pitch.from(midi: config.tuning[stringIndex].midiNumber + fret)
    }

    func allPositions(for pitch: Pitch) -> [FretboardPosition] {
        var positions: [FretboardPosition] = []
        for stringIndex in 0..<config.stringCount {
            let fret = pitch.midiNumber - config.tuning[stringIndex].midiNumber
            if fret >= 0 && fret <= config.fretCount {
                positions.append(FretboardPosition(stringIndex: stringIndex, fretNumber: fret))
            }
        }
        return positions
    }

    func allPositions(forMidi midi: Int) -> [FretboardPosition] {
        guard let pitch = Pitch(midi: midi) else { return [] }
        return allPositions(for: pitch)
    }

    func noteAt(stringIndex: Int, fret: Int) -> FretboardNote? {
        guard let pitch = pitch(at: stringIndex, fret: fret) else { return nil }
        let position = FretboardPosition(stringIndex: stringIndex, fretNumber: fret)
        return FretboardNote(position: position, pitch: pitch)
    }

    func positions(forPitchClass pitchClass: Int) -> [FretboardPosition] {
        var positions: [FretboardPosition] = []
        for stringIndex in 0..<config.stringCount {
            let openString = config.tuning[stringIndex].midiNumber
            for fret in 0...config.fretCount {
                let midi = openString + fret
                if midi % 12 == pitchClass {
                    positions.append(FretboardPosition(stringIndex: stringIndex, fretNumber: fret))
                }
            }
        }
        return positions
    }

    func positions(forScale scale: Scale, root: Pitch) -> [[FretboardPosition]] {
        let pitches = scale.pitches(root: root)
        let uniquePitchClasses = Array(Set(pitches.map { $0.midiNumber % 12 })).sorted()
        return uniquePitchClasses.map { pitchClass in
            positions(forPitchClass: pitchClass)
        }
    }
}
