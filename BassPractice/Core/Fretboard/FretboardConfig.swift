import Foundation

struct FretboardConfig: Codable, Hashable {
    let stringCount: Int
    let fretCount: Int
    let tuning: [Pitch]

    var lowestPitch: Pitch { tuning[0] }
    var highestPitch: Pitch {
        Pitch.from(midi: tuning[stringCount - 1].midiNumber + fretCount)
    }

    init(stringCount: Int, fretCount: Int, tuning: [Pitch]) {
        self.stringCount = stringCount
        self.fretCount = fretCount
        self.tuning = tuning
    }

    static let standard5StringBass = FretboardConfig(
        stringCount: 5,
        fretCount: 24,
        tuning: [
            Pitch(noteName: .B, octave: 0),
            Pitch(noteName: .E, octave: 1),
            Pitch(noteName: .A, octave: 1),
            Pitch(noteName: .D, octave: 2),
            Pitch(noteName: .G, octave: 2)
        ]
    )

    static let standard4StringBass = FretboardConfig(
        stringCount: 4,
        fretCount: 24,
        tuning: [
            Pitch(noteName: .E, octave: 1),
            Pitch(noteName: .A, octave: 1),
            Pitch(noteName: .D, octave: 2),
            Pitch(noteName: .G, octave: 2)
        ]
    )

    static let standard6StringGuitar = FretboardConfig(
        stringCount: 6,
        fretCount: 22,
        tuning: [
            Pitch(noteName: .E, octave: 2),
            Pitch(noteName: .A, octave: 2),
            Pitch(noteName: .D, octave: 3),
            Pitch(noteName: .G, octave: 3),
            Pitch(noteName: .B, octave: 3),
            Pitch(noteName: .E, octave: 4)
        ]
    )

    func stringLabel(at index: Int) -> String {
        guard index >= 0, index < tuning.count else { return "?" }
        return tuning[index].noteName.displayName
    }

    func fretMarkers() -> [Int] {
        let singleDots = [3, 5, 7, 9, 15, 17, 19, 21]
        let doubleDots = [12, 24]
        return singleDots + doubleDots
    }

    func isDoubleDot(fret: Int) -> Bool {
        [12, 24].contains(fret)
    }
}
