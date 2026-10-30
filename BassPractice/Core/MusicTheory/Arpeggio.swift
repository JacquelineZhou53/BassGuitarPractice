import Foundation

struct Arpeggio: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let intervals: [Interval]

    var pitchClasses: [Int] {
        intervals.map { $0.semitones % 12 }
    }

    func pitches(root: Pitch) -> [Pitch] {
        intervals.map { root.transposed(by: $0.semitones) }
    }
}

extension Arpeggio {
    static let majorTriad = Arpeggio(
        id: "major_triad",
        name: "大三和弦",
        intervals: [.unison, .majorThird, .perfectFifth, .octave]
    )

    static let minorTriad = Arpeggio(
        id: "minor_triad",
        name: "小三和弦",
        intervals: [.unison, .minorThird, .perfectFifth, .octave]
    )

    static let diminishedTriad = Arpeggio(
        id: "diminished_triad",
        name: "减三和弦",
        intervals: [.unison, .minorThird, .tritone, .octave]
    )

    static let augmentedTriad = Arpeggio(
        id: "augmented_triad",
        name: "增三和弦",
        intervals: [.unison, .majorThird, .minorSixth, .octave]
    )

    static let dominant7th = Arpeggio(
        id: "dominant_7th",
        name: "属七 (Dom7)",
        intervals: [.unison, .majorThird, .perfectFifth, .minorSeventh, .octave]
    )

    static let major7th = Arpeggio(
        id: "major_7th",
        name: "大七 (Maj7)",
        intervals: [.unison, .majorThird, .perfectFifth, .majorSeventh, .octave]
    )

    static let minor7th = Arpeggio(
        id: "minor_7th",
        name: "小七 (Min7)",
        intervals: [.unison, .minorThird, .perfectFifth, .minorSeventh, .octave]
    )

    static let halfDiminished7th = Arpeggio(
        id: "half_diminished_7th",
        name: "半减七 (m7♭5)",
        intervals: [.unison, .minorThird, .tritone, .minorSeventh, .octave]
    )

    static let diminished7th = Arpeggio(
        id: "diminished_7th",
        name: "减七 (dim7)",
        intervals: [.unison, .minorThird, .tritone, .majorSixth, .octave]
    )

    static let minorMajor7th = Arpeggio(
        id: "minor_major_7th",
        name: "小大七 (mMaj7)",
        intervals: [.unison, .minorThird, .perfectFifth, .majorSeventh, .octave]
    )

    static let augmented7th = Arpeggio(
        id: "augmented_7th",
        name: "增七 (+7)",
        intervals: [.unison, .majorThird, .minorSixth, .minorSeventh, .octave]
    )

    static let dominant9th = Arpeggio(
        id: "dominant_9th",
        name: "属九 (9)",
        intervals: [.unison, .majorThird, .perfectFifth, .minorSeventh, .majorNinth, .octave]
    )

    static let major9th = Arpeggio(
        id: "major_9th",
        name: "大九 (Maj9)",
        intervals: [.unison, .majorThird, .perfectFifth, .majorSeventh, .majorNinth, .octave]
    )

    static let minor9th = Arpeggio(
        id: "minor_9th",
        name: "小九 (Min9)",
        intervals: [.unison, .minorThird, .perfectFifth, .minorSeventh, .majorNinth, .octave]
    )

    static let sus4 = Arpeggio(
        id: "sus4",
        name: "挂四 (sus4)",
        intervals: [.unison, .perfectFourth, .perfectFifth, .octave]
    )

    static let sus2 = Arpeggio(
        id: "sus2",
        name: "挂二 (sus2)",
        intervals: [.unison, .majorSecond, .perfectFifth, .octave]
    )

    static let allArpeggios: [Arpeggio] = [
        .majorTriad, .minorTriad, .diminishedTriad, .augmentedTriad,
        .dominant7th, .major7th, .minor7th, .halfDiminished7th, .diminished7th, .minorMajor7th, .augmented7th,
        .dominant9th, .major9th, .minor9th,
        .sus4, .sus2
    ]
}
