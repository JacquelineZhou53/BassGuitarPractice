import Foundation

struct Chord: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let intervals: [Interval]

    func pitches(root: Pitch) -> [Pitch] {
        intervals.map { root.transposed(by: $0.semitones) }
    }
}

extension Chord {
    static let major = Chord(
        id: "major",
        name: "大三和弦",
        intervals: [.unison, .majorThird, .perfectFifth]
    )

    static let minor = Chord(
        id: "minor",
        name: "小三和弦",
        intervals: [.unison, .minorThird, .perfectFifth]
    )

    static let diminished = Chord(
        id: "diminished",
        name: "减三和弦",
        intervals: [.unison, .minorThird, .diminishedFifth]
    )

    static let augmented = Chord(
        id: "augmented",
        name: "增三和弦",
        intervals: [.unison, .majorThird, .augmentedFifth]
    )

    static let dominant7 = Chord(
        id: "dominant7",
        name: "属七 (Dom7)",
        intervals: [.unison, .majorThird, .perfectFifth, .minorSeventh]
    )

    static let major7 = Chord(
        id: "major7",
        name: "大七 (Maj7)",
        intervals: [.unison, .majorThird, .perfectFifth, .majorSeventh]
    )

    static let minor7 = Chord(
        id: "minor7",
        name: "小七 (Min7)",
        intervals: [.unison, .minorThird, .perfectFifth, .minorSeventh]
    )

    static let halfDiminished7 = Chord(
        id: "half_diminished7",
        name: "半减七 (m7b5)",
        intervals: [.unison, .minorThird, .diminishedFifth, .minorSeventh]
    )

    static let diminished7 = Chord(
        id: "diminished7",
        name: "减七 (dim7)",
        intervals: [.unison, .minorThird, .diminishedFifth, .diminishedSeventh]
    )

    static let minorMajor7 = Chord(
        id: "minor_major7",
        name: "小大七 (mMaj7)",
        intervals: [.unison, .minorThird, .perfectFifth, .majorSeventh]
    )

    static let sus2 = Chord(
        id: "sus2",
        name: "挂二 (sus2)",
        intervals: [.unison, .majorSecond, .perfectFifth]
    )

    static let sus4 = Chord(
        id: "sus4",
        name: "挂四 (sus4)",
        intervals: [.unison, .perfectFourth, .perfectFifth]
    )

    static let add9 = Chord(
        id: "add9",
        name: "加九 (add9)",
        intervals: [.unison, .majorThird, .perfectFifth, .majorNinth]
    )

    static let major9 = Chord(
        id: "major9",
        name: "大九 (Maj9)",
        intervals: [.unison, .majorThird, .perfectFifth, .majorSeventh, .majorNinth]
    )

    static let dominant9 = Chord(
        id: "dominant9",
        name: "属九 (9)",
        intervals: [.unison, .majorThird, .perfectFifth, .minorSeventh, .majorNinth]
    )

    static let minor9 = Chord(
        id: "minor9",
        name: "小九 (Min9)",
        intervals: [.unison, .minorThird, .perfectFifth, .minorSeventh, .majorNinth]
    )

    static let allChords: [Chord] = [
        .major, .minor, .diminished, .augmented,
        .dominant7, .major7, .minor7, .halfDiminished7, .diminished7, .minorMajor7,
        .sus2, .sus4,
        .add9, .major9, .dominant9, .minor9
    ]
}
