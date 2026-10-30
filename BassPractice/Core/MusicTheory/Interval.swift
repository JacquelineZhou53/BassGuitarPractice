import Foundation

struct Interval: Hashable, Codable {
    let semitones: Int
    let name: String

    init(semitones: Int, name: String = "") {
        self.semitones = semitones
        self.name = name
    }

    static let unison = Interval(semitones: 0, name: "Unison")
    static let minorSecond = Interval(semitones: 1, name: "m2")
    static let majorSecond = Interval(semitones: 2, name: "M2")
    static let minorThird = Interval(semitones: 3, name: "m3")
    static let majorThird = Interval(semitones: 4, name: "M3")
    static let perfectFourth = Interval(semitones: 5, name: "P4")
    static let tritone = Interval(semitones: 6, name: "TT")
    static let perfectFifth = Interval(semitones: 7, name: "P5")
    static let diminishedFifth = Interval(semitones: 6, name: "d5")
    static let augmentedFifth = Interval(semitones: 8, name: "A5")
    static let minorSixth = Interval(semitones: 8, name: "m6")
    static let majorSixth = Interval(semitones: 9, name: "M6")
    static let minorSeventh = Interval(semitones: 10, name: "m7")
    static let diminishedSeventh = Interval(semitones: 9, name: "d7")
    static let majorSeventh = Interval(semitones: 11, name: "M7")
    static let octave = Interval(semitones: 12, name: "P8")
    static let minorNinth = Interval(semitones: 13, name: "m9")
    static let majorNinth = Interval(semitones: 14, name: "M9")
    static let minorTenth = Interval(semitones: 15, name: "m10")
    static let majorTenth = Interval(semitones: 16, name: "M10")
    static let perfectEleventh = Interval(semitones: 17, name: "P11")
    static let perfectTwelfth = Interval(semitones: 19, name: "P12")
    static let doubleOctave = Interval(semitones: 24, name: "P15")
}
