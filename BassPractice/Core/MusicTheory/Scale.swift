import Foundation

struct Scale: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let category: ScaleCategory
    let intervals: [Interval]

    var pitchClasses: [Int] {
        intervals.map { $0.semitones % 12 }
    }

    func pitches(root: Pitch) -> [Pitch] {
        intervals.map { root.transposed(by: $0.semitones) }
    }

    func midiNumbers(root: Int) -> [Int] {
        intervals.map { (root + $0.semitones) % 128 }
    }
}

enum ScaleCategory: String, Codable, CaseIterable {
    case major = "Major"
    case minor = "Minor"
    case modal = "Modal"
    case pentatonic = "Pentatonic"
    case blues = "Blues"
    case exotic = "Exotic"
    case arpeggio = "Arpeggio"
    case chord = "Chord"

    var displayName: String {
        switch self {
        case .major: return "大调音阶"
        case .minor: return "小调音阶"
        case .modal: return "调式音阶"
        case .pentatonic: return "五声音阶"
        case .blues: return "布鲁斯音阶"
        case .exotic: return "特殊音阶"
        case .arpeggio: return "琶音"
        case .chord: return "和弦"
        }
    }
}

extension Scale {
    static let major = Scale(
        id: "major",
        name: "大调 (Ionian)",
        category: .major,
        intervals: [.unison, .majorSecond, .majorThird, .perfectFourth, .perfectFifth, .majorSixth, .majorSeventh, .octave]
    )

    static let naturalMinor = Scale(
        id: "natural_minor",
        name: "自然小调 (Aeolian)",
        category: .minor,
        intervals: [.unison, .majorSecond, .minorThird, .perfectFourth, .perfectFifth, .minorSixth, .minorSeventh, .octave]
    )

    static let harmonicMinor = Scale(
        id: "harmonic_minor",
        name: "和声小调",
        category: .minor,
        intervals: [.unison, .majorSecond, .minorThird, .perfectFourth, .perfectFifth, .minorSixth, .majorSeventh, .octave]
    )

    static let melodicMinor = Scale(
        id: "melodic_minor",
        name: "旋律小调",
        category: .minor,
        intervals: [.unison, .majorSecond, .minorThird, .perfectFourth, .perfectFifth, .majorSixth, .majorSeventh, .octave]
    )

    static let dorian = Scale(
        id: "dorian",
        name: "Dorian",
        category: .modal,
        intervals: [.unison, .majorSecond, .minorThird, .perfectFourth, .perfectFifth, .majorSixth, .minorSeventh, .octave]
    )

    static let phrygian = Scale(
        id: "phrygian",
        name: "Phrygian",
        category: .modal,
        intervals: [.unison, .minorSecond, .minorThird, .perfectFourth, .perfectFifth, .minorSixth, .minorSeventh, .octave]
    )

    static let lydian = Scale(
        id: "lydian",
        name: "Lydian",
        category: .modal,
        intervals: [.unison, .majorSecond, .majorThird, .tritone, .perfectFifth, .majorSixth, .majorSeventh, .octave]
    )

    static let mixolydian = Scale(
        id: "mixolydian",
        name: "Mixolydian",
        category: .modal,
        intervals: [.unison, .majorSecond, .majorThird, .perfectFourth, .perfectFifth, .majorSixth, .minorSeventh, .octave]
    )

    static let locrian = Scale(
        id: "locrian",
        name: "Locrian",
        category: .modal,
        intervals: [.unison, .minorSecond, .minorThird, .perfectFourth, .tritone, .minorSixth, .minorSeventh, .octave]
    )

    static let majorPentatonic = Scale(
        id: "major_pentatonic",
        name: "大调五声",
        category: .pentatonic,
        intervals: [.unison, .majorSecond, .majorThird, .perfectFifth, .majorSixth, .octave]
    )

    static let minorPentatonic = Scale(
        id: "minor_pentatonic",
        name: "小调五声",
        category: .pentatonic,
        intervals: [.unison, .minorThird, .perfectFourth, .perfectFifth, .minorSeventh, .octave]
    )

    static let blues = Scale(
        id: "blues",
        name: "布鲁斯",
        category: .blues,
        intervals: [.unison, .minorThird, .perfectFourth, .tritone, .perfectFifth, .minorSeventh, .octave]
    )

    static let majorBlues = Scale(
        id: "major_blues",
        name: "大调布鲁斯",
        category: .blues,
        intervals: [.unison, .majorSecond, .minorThird, .majorThird, .perfectFifth, .majorSixth, .octave]
    )

    static let wholeTone = Scale(
        id: "whole_tone",
        name: "全音阶",
        category: .exotic,
        intervals: [.unison, .majorSecond, .majorThird, .tritone, .minorSixth, .minorSeventh, .octave]
    )

    static let diminished = Scale(
        id: "diminished",
        name: "减音阶",
        category: .exotic,
        intervals: [.unison, .majorSecond, .minorThird, .perfectFourth, .tritone, .minorSixth, .majorSixth, .majorSeventh, .octave]
    )

    static let chromatic = Scale(
        id: "chromatic",
        name: "半音阶",
        category: .exotic,
        intervals: [.unison, .minorSecond, .majorSecond, .minorThird, .majorThird, .perfectFourth,
                    .tritone, .perfectFifth, .minorSixth, .majorSixth, .minorSeventh, .majorSeventh, .octave]
    )

    static let allScales: [Scale] = [
        .major, .naturalMinor, .harmonicMinor, .melodicMinor,
        .dorian, .phrygian, .lydian, .mixolydian, .locrian,
        .majorPentatonic, .minorPentatonic,
        .blues, .majorBlues,
        .wholeTone, .diminished, .chromatic
    ]
}
