import Foundation

enum NoteDuration: Codable, Hashable {
    case whole
    case half
    case quarter
    case eighth
    case sixteenth
    case thirtySecond
    case dottedHalf
    case dottedQuarter
    case dottedEighth
    case eighthTriplet
    case sixteenthTriplet

    var ticks: Int {
        switch self {
        case .whole: return 1920
        case .half: return 960
        case .quarter: return 480
        case .eighth: return 240
        case .sixteenth: return 120
        case .thirtySecond: return 60
        case .dottedHalf: return 1440
        case .dottedQuarter: return 720
        case .dottedEighth: return 360
        case .eighthTriplet: return 160
        case .sixteenthTriplet: return 80
        }
    }

    var musicXMLType: String {
        switch self {
        case .whole, .dottedHalf: return "whole"
        case .half: return "half"
        case .quarter, .dottedQuarter: return "quarter"
        case .eighth, .dottedEighth, .eighthTriplet: return "eighth"
        case .sixteenth, .sixteenthTriplet: return "16th"
        case .thirtySecond: return "32nd"
        }
    }

    var dots: Int {
        switch self {
        case .dottedHalf, .dottedQuarter, .dottedEighth: return 1
        default: return 0
        }
    }

    var isTriplet: Bool {
        switch self {
        case .eighthTriplet, .sixteenthTriplet: return true
        default: return false
        }
    }
}

struct ScoreNote: Identifiable, Codable, Hashable {
    let id: UUID
    var midiPitch: Int
    var duration: NoteDuration
    var velocity: Int
    var isRest: Bool
    var fretboardPosition: FretboardPosition?

    init(id: UUID = UUID(), midiPitch: Int, duration: NoteDuration, velocity: Int = 80, isRest: Bool = false, fretboardPosition: FretboardPosition? = nil) {
        self.id = id
        self.midiPitch = midiPitch
        self.duration = duration
        self.velocity = velocity
        self.isRest = isRest
        self.fretboardPosition = fretboardPosition
    }

    var pitch: Pitch {
        Pitch.from(midi: midiPitch)
    }

    static func rest(duration: NoteDuration) -> ScoreNote {
        ScoreNote(midiPitch: 0, duration: duration, velocity: 0, isRest: true)
    }
}

struct ScoreMeasure: Identifiable, Codable, Hashable {
    let id: UUID
    var measureNumber: Int
    var notes: [ScoreNote]
    var timeSignature: TimeSignatureData?
    var keySignature: KeySignatureData?

    init(id: UUID = UUID(), measureNumber: Int, notes: [ScoreNote], timeSignature: TimeSignatureData? = nil, keySignature: KeySignatureData? = nil) {
        self.id = id
        self.measureNumber = measureNumber
        self.notes = notes
        self.timeSignature = timeSignature
        self.keySignature = keySignature
    }

    var totalTicks: Int {
        notes.reduce(0) { $0 + $1.duration.ticks }
    }
}

struct TimeSignatureData: Codable, Hashable {
    var numerator: Int
    var denominator: Int

    init(numerator: Int = 4, denominator: Int = 4) {
        self.numerator = numerator
        self.denominator = denominator
    }

    var ticksPerMeasure: Int {
        let ticksPerQuarter = 480
        return ticksPerQuarter * 4 * numerator / denominator
    }

    var displayString: String {
        "\(numerator)/\(denominator)"
    }
}

struct KeySignatureData: Codable, Hashable {
    var fifths: Int
    var mode: String

    init(fifths: Int = 0, mode: String = "major") {
        self.fifths = fifths
        self.mode = mode
    }

    static let cMajor = KeySignatureData(fifths: 0, mode: "major")
    static let aMinor = KeySignatureData(fifths: 0, mode: "minor")
    static let gMajor = KeySignatureData(fifths: 1, mode: "major")
    static let fMajor = KeySignatureData(fifths: -1, mode: "major")
    static let dMajor = KeySignatureData(fifths: 2, mode: "major")
    static let bFlatMajor = KeySignatureData(fifths: -2, mode: "major")
}

enum ScoreSource: String, Codable {
    case builtIn = "built_in"
    case midiImport = "midi_import"
    case pdfImport = "pdf_import"
    case msczImport = "mscz_import"
    case userCreated = "user_created"
    case scalePractice = "scale_practice"
}

enum InstrumentType: String, Codable, CaseIterable {
    case bass = "bass"
    case guitar = "guitar"

    var displayName: String {
        switch self {
        case .bass: return "贝斯"
        case .guitar: return "吉他"
        }
    }

    var defaultFretboardConfig: FretboardConfig {
        switch self {
        case .bass: return .standard5StringBass
        case .guitar: return .standard6StringGuitar
        }
    }
}

struct Score: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var composer: String
    var createTime: Date
    var modifyTime: Date
    var timeSignature: TimeSignatureData
    var keySignature: KeySignatureData
    var tempo: Int
    var sourceType: ScoreSource
    var instrumentType: InstrumentType
    var sourceFileURL: String?
    var measures: [ScoreMeasure]
    var fretboardAnnotations: [FretboardAnnotation]

    init(id: UUID = UUID(), title: String, composer: String = "", timeSignature: TimeSignatureData = TimeSignatureData(), keySignature: KeySignatureData = KeySignatureData(), tempo: Int = 120, sourceType: ScoreSource = .userCreated, instrumentType: InstrumentType = .bass, sourceFileURL: String? = nil, measures: [ScoreMeasure] = [], fretboardAnnotations: [FretboardAnnotation] = []) {
        self.id = id
        self.title = title
        self.composer = composer
        self.createTime = Date()
        self.modifyTime = Date()
        self.timeSignature = timeSignature
        self.keySignature = keySignature
        self.tempo = tempo
        self.sourceType = sourceType
        self.instrumentType = instrumentType
        self.sourceFileURL = sourceFileURL
        self.measures = measures
        self.fretboardAnnotations = fretboardAnnotations
    }

    var allNotes: [ScoreNote] {
        measures.flatMap(\.notes)
    }

    var totalDuration: Int {
        measures.reduce(0) { $0 + $1.totalTicks }
    }
}

struct FretboardAnnotation: Identifiable, Codable, Hashable {
    let id: UUID
    var noteId: UUID
    var position: FretboardPosition

    init(id: UUID = UUID(), noteId: UUID, position: FretboardPosition) {
        self.id = id
        self.noteId = noteId
        self.position = position
    }
}
