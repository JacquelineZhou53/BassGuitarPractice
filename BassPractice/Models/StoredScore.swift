import Foundation
import SwiftData

@Model
final class StoredScore {
    @Attribute(.unique) var id: UUID
    var title: String
    var composer: String
    var createTime: Date
    var modifyTime: Date
    var timeSignatureNumerator: Int
    var timeSignatureDenominator: Int
    var keySignatureFifths: Int
    var keySignatureMode: String
    var tempo: Int
    var sourceTypeRaw: String
    var instrumentTypeRaw: String
    var sourceFileURL: String?
    var measuresData: Data
    var annotationsData: Data

    init(score: Score) {
        self.id = score.id
        self.title = score.title
        self.composer = score.composer
        self.createTime = score.createTime
        self.modifyTime = score.modifyTime
        self.timeSignatureNumerator = score.timeSignature.numerator
        self.timeSignatureDenominator = score.timeSignature.denominator
        self.keySignatureFifths = score.keySignature.fifths
        self.keySignatureMode = score.keySignature.mode
        self.tempo = score.tempo
        self.sourceTypeRaw = score.sourceType.rawValue
        self.instrumentTypeRaw = score.instrumentType.rawValue
        self.sourceFileURL = score.sourceFileURL

        let encoder = JSONEncoder()
        self.measuresData = (try? encoder.encode(score.measures)) ?? Data()
        self.annotationsData = (try? encoder.encode(score.fretboardAnnotations)) ?? Data()
    }

    func toScore() -> Score {
        let decoder = JSONDecoder()
        let measures = (try? decoder.decode([ScoreMeasure].self, from: measuresData)) ?? []
        let annotations = (try? decoder.decode([FretboardAnnotation].self, from: annotationsData)) ?? []

        return Score(
            id: id,
            title: title,
            composer: composer,
            timeSignature: TimeSignatureData(numerator: timeSignatureNumerator, denominator: timeSignatureDenominator),
            keySignature: KeySignatureData(fifths: keySignatureFifths, mode: keySignatureMode),
            tempo: tempo,
            sourceType: ScoreSource(rawValue: sourceTypeRaw) ?? .userCreated,
            instrumentType: InstrumentType(rawValue: instrumentTypeRaw) ?? .bass,
            sourceFileURL: sourceFileURL,
            measures: measures,
            fretboardAnnotations: annotations
        )
    }

    var sourceType: ScoreSource {
        ScoreSource(rawValue: sourceTypeRaw) ?? .userCreated
    }

    var instrumentType: InstrumentType {
        InstrumentType(rawValue: instrumentTypeRaw) ?? .bass
    }

    var isPDF: Bool {
        sourceType == .pdfImport
    }

    var hasNotation: Bool {
        guard let measures = try? JSONDecoder().decode([ScoreMeasure].self, from: measuresData) else {
            return false
        }
        return measures.contains { !$0.notes.isEmpty }
    }

    func update(from score: Score) {
        self.title = score.title
        self.composer = score.composer
        self.modifyTime = score.modifyTime
        self.timeSignatureNumerator = score.timeSignature.numerator
        self.timeSignatureDenominator = score.timeSignature.denominator
        self.keySignatureFifths = score.keySignature.fifths
        self.keySignatureMode = score.keySignature.mode
        self.tempo = score.tempo
        self.sourceTypeRaw = score.sourceType.rawValue
        self.instrumentTypeRaw = score.instrumentType.rawValue
        self.sourceFileURL = score.sourceFileURL

        let encoder = JSONEncoder()
        self.measuresData = (try? encoder.encode(score.measures)) ?? Data()
        self.annotationsData = (try? encoder.encode(score.fretboardAnnotations)) ?? Data()
    }
}

@Model
final class ScoreLibrary {
    @Attribute(.unique) var id: UUID
    var name: String
    var scoreIds: [UUID]

    init(name: String, scoreIds: [UUID] = []) {
        self.id = UUID()
        self.name = name
        self.scoreIds = scoreIds
    }
}
