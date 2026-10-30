import Foundation

enum NoteName: String, Codable, CaseIterable, Hashable {
    case C, Cs, D, Ds, E, F, Fs, G, Gs, A, As, B

    var semitone: Int {
        switch self {
        case .C: return 0
        case .Cs: return 1
        case .D: return 2
        case .Ds: return 3
        case .E: return 4
        case .F: return 5
        case .Fs: return 6
        case .G: return 7
        case .Gs: return 8
        case .A: return 9
        case .As: return 10
        case .B: return 11
        }
    }

    var displayName: String {
        switch self {
        case .C: return "C"
        case .Cs: return "C♯"
        case .D: return "D"
        case .Ds: return "D♯"
        case .E: return "E"
        case .F: return "F"
        case .Fs: return "F♯"
        case .G: return "G"
        case .Gs: return "G♯"
        case .A: return "A"
        case .As: return "A♯"
        case .B: return "B"
        }
    }

    var flatName: String {
        switch self {
        case .Cs: return "D♭"
        case .Ds: return "E♭"
        case .Fs: return "G♭"
        case .Gs: return "A♭"
        case .As: return "B♭"
        default: return displayName
        }
    }

    init?(semitone: Int) {
        switch semitone % 12 {
        case 0: self = .C
        case 1: self = .Cs
        case 2: self = .D
        case 3: self = .Ds
        case 4: self = .E
        case 5: self = .F
        case 6: self = .Fs
        case 7: self = .G
        case 8: self = .Gs
        case 9: self = .A
        case 10: self = .As
        case 11: self = .B
        default: return nil
        }
    }
}

struct Pitch: Hashable, Codable, Comparable {
    let noteName: NoteName
    let octave: Int

    var midiNumber: Int {
        (octave + 1) * 12 + noteName.semitone
    }

    var frequency: Double {
        440.0 * pow(2.0, Double(midiNumber - 69) / 12.0)
    }

    init(noteName: NoteName, octave: Int) {
        self.noteName = noteName
        self.octave = octave
    }

    init?(midi: Int) {
        guard midi >= 0, midi <= 127 else { return nil }
        let octave = midi / 12 - 1
        let semitone = midi % 12
        guard let name = NoteName(semitone: semitone) else { return nil }
        self.noteName = name
        self.octave = octave
    }

    static func from(midi: Int) -> Pitch {
        Pitch(midi: midi) ?? Pitch(noteName: .C, octave: 4)
    }

    static func < (lhs: Pitch, rhs: Pitch) -> Bool {
        lhs.midiNumber < rhs.midiNumber
    }

    func transposed(by semitones: Int) -> Pitch {
        Pitch.from(midi: midiNumber + semitones)
    }

    var displayName: String {
        "\(noteName.displayName)\(octave)"
    }
}
