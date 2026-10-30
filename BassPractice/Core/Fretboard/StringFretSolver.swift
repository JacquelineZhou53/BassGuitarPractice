import Foundation

struct StringFretSolver {
    let config: FretboardConfig

    init(config: FretboardConfig) {
        self.config = config
    }

    func fretForPitch(_ pitch: Pitch, onString stringIndex: Int) -> Int? {
        guard stringIndex >= 0, stringIndex < config.stringCount else { return nil }
        let fret = pitch.midiNumber - config.tuning[stringIndex].midiNumber
        guard fret >= 0, fret <= config.fretCount else { return nil }
        return fret
    }

    func fretForMidi(_ midi: Int, onString stringIndex: Int) -> Int? {
        guard let pitch = Pitch(midi: midi) else { return nil }
        return fretForPitch(pitch, onString: stringIndex)
    }

    func allPositionsForPitch(_ pitch: Pitch) -> [FretboardPosition] {
        var results: [FretboardPosition] = []
        for stringIndex in 0..<config.stringCount {
            if let fret = fretForPitch(pitch, onString: stringIndex) {
                results.append(FretboardPosition(stringIndex: stringIndex, fretNumber: fret))
            }
        }
        return results
    }

    func bestPositionForPitch(_ pitch: Pitch, near previousPosition: FretboardPosition?) -> FretboardPosition? {
        let candidates = allPositionsForPitch(pitch)
        guard !candidates.isEmpty else { return nil }

        guard let prev = previousPosition else {
            return candidates.min(by: { a, b in
                let scoreA = abs(a.stringIndex - 2) * 2 + a.fretNumber
                let scoreB = abs(b.stringIndex - 2) * 2 + b.fretNumber
                return scoreA < scoreB
            })
        }

        return candidates.min(by: { a, b in
            let distA = abs(a.fretNumber - prev.fretNumber) + abs(a.stringIndex - prev.stringIndex)
            let distB = abs(b.fretNumber - prev.fretNumber) + abs(b.stringIndex - prev.stringIndex)
            return distA < distB
        })
    }

    func isValidPosition(stringIndex: Int, fret: Int) -> Bool {
        stringIndex >= 0 && stringIndex < config.stringCount &&
        fret >= 0 && fret <= config.fretCount
    }
}
