import Foundation

enum MSCZParserError: Error, LocalizedError {
    case invalidArchive
    case missingScoreXML
    case invalidXML(String)
    case noNotation

    var errorDescription: String? {
        switch self {
        case .invalidArchive:
            return "MSCZ 文件不是有效的 MuseScore 压缩包。"
        case .missingScoreXML:
            return "MSCZ 内没有找到 MuseScore 谱面数据。"
        case .invalidXML(let message):
            return "MSCZ 谱面 XML 解析失败：\(message)"
        case .noNotation:
            return "这个 MuseScore 文件里没有找到可导入的音符。"
        }
    }
}

struct MSCZParseResult {
    let standardScore: Score
    let tabScore: Score?
    let hasTabStaff: Bool
}

struct MSCZParser {
    func parse(data: Data, title: String) throws -> MSCZParseResult {
        let xmlData: Data

        if data.starts(with: [0x50, 0x4B]) {
            let archive = try ZIPArchive(data: data)
            guard let scoreFile = archive.data(forFileEndingWith: ".mscx") else {
                throw MSCZParserError.missingScoreXML
            }
            xmlData = scoreFile.data
        } else {
            xmlData = data
        }

        return try MSCXParser().parse(data: xmlData, title: title)
    }
}

private struct MSCXStaffDraft {
    let id: String
    var measures: [ScoreMeasure] = []
    var isTabStaff: Bool = false

    var notes: [ScoreNote] {
        measures.flatMap(\.notes)
    }

    var averagePitch: Double? {
        let pitches = notes.filter { !$0.isRest }.map(\.midiPitch)
        guard !pitches.isEmpty else { return nil }
        return Double(pitches.reduce(0, +)) / Double(pitches.count)
    }
}

private struct MSCXMeasureDraft {
    var number: Int
    var voices: [[MSCXEventDraft]] = []
    var timeSignature: TimeSignatureData?
    var keySignature: KeySignatureData?
}

private enum MSCXEventDraft {
    case note(pitch: Int, duration: NoteDuration)
    case rest(duration: NoteDuration)
}

private struct MSCXDurationDraft {
    var type: String?
    var dots: Int = 0
    var ticks: Int?
    var isMeasure = false
    var tuplet: (normal: Int, actual: Int)?
}

private struct MSCXChordDraft {
    var pitches: [Int] = []
    var duration = MSCXDurationDraft()
    var isGrace = false
}

private struct MSCXRestDraft {
    var duration = MSCXDurationDraft()
}

private struct MSCXPartDraft {
    var name: String?
    var staffIDs: [String] = []
    var clefs: [String: String] = [:]
}

private final class MSCXParser: NSObject, XMLParserDelegate {
    private var metaTitle: String?
    private var metaComposer: String?
    private var scoreTempo: Int?

    private var staves: [MSCXStaffDraft] = []
    private var parts: [MSCXPartDraft] = []

    private var currentStaff: MSCXStaffDraft?
    private var currentMeasure: MSCXMeasureDraft?
    private var currentVoice: [MSCXEventDraft]?
    private var currentChord: MSCXChordDraft?
    private var currentRest: MSCXRestDraft?
    private var currentNotePitch: Int?

    private var currentPart: MSCXPartDraft?
    private var currentPartStaffID: String?
    private var partDepth = 0

    private var pendingTimeSignature: TimeSignatureData?
    private var pendingKeySignature: KeySignatureData?
    private var currentTimeSignature = TimeSignatureData()
    private var currentKeySignature = KeySignatureData()
    private var pendingTempo: Int?

    private var inTimeSignature = false
    private var pendingSigN: Int?
    private var pendingSigD: Int?

    private var inKeySignature = false
    private var pendingKeyFifths: Int?

    private var inTempo = false
    private var pendingTuplet: (normal: Int, actual: Int)?
    private var pendingTupletNormal: Int?
    private var pendingTupletActual: Int?

    private var currentMetaName: String?
    private var textBuffer = ""

    private var inClef = false
    private var currentClefSign: String?

    func parse(data: Data, title: String) throws -> MSCZParseResult {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.shouldResolveExternalEntities = false

        guard parser.parse() else {
            throw MSCZParserError.invalidXML(parser.parserError?.localizedDescription ?? "未知错误")
        }

        let candidates = staves.filter { !$0.notes.isEmpty }
        guard !candidates.isEmpty else {
            throw MSCZParserError.noNotation
        }

        let bassStaffIDs = Set(
            parts.filter { part in
                let name = part.name?.lowercased() ?? ""
                let hasBassName = name.contains("bass")
                    || name.contains("basso")
                    || name.contains("贝斯")
                    || name.contains("低音")
                let hasBassClef = part.clefs.values.contains { $0.uppercased() == "F" }
                return hasBassName || hasBassClef
            }
            .flatMap(\.staffIDs)
        )

        let preferred = candidates.filter { bassStaffIDs.contains($0.id) }
        let pool = preferred.isEmpty ? candidates : preferred
        
        // 分离标准谱和TAB谱
        let standardStaves = pool.filter { !$0.isTabStaff }
        let tabStaves = pool.filter { $0.isTabStaff }
        
        let staff = (standardStaves.isEmpty ? pool : standardStaves).min { lhs, rhs in
            (lhs.averagePitch ?? .greatestFiniteMagnitude)
                < (rhs.averagePitch ?? .greatestFiniteMagnitude)
        } ?? pool[0]

        let scoreTimeSignature = staff.measures.first?.timeSignature ?? TimeSignatureData()
        let scoreKeySignature = staff.measures.first?.keySignature ?? KeySignatureData()

        let standardScore = Score(
            title: metaTitle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? metaTitle!.trimmingCharacters(in: .whitespacesAndNewlines)
                : title,
            composer: metaComposer?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            timeSignature: scoreTimeSignature,
            keySignature: scoreKeySignature,
            tempo: scoreTempo ?? 120,
            sourceType: .msczImport,
            measures: staff.measures
        )
        
        // 如果有TAB谱，提取TAB谱；如果没有，自动生成
        var tabScore: Score?
        if let tabStaff = tabStaves.first {
            let tabTimeSignature = tabStaff.measures.first?.timeSignature ?? scoreTimeSignature
            let tabKeySignature = tabStaff.measures.first?.keySignature ?? scoreKeySignature
            
            tabScore = Score(
                title: standardScore.title,
                composer: standardScore.composer,
                timeSignature: tabTimeSignature,
                keySignature: tabKeySignature,
                tempo: standardScore.tempo,
                sourceType: .msczImport,
                measures: tabStaff.measures
            )
        } else {
            // 自动生成TAB谱
            let tabGenerator = TabGenerator()
            tabScore = tabGenerator.generateTab(for: standardScore)
        }

        return MSCZParseResult(
            standardScore: standardScore,
            tabScore: tabScore,
            hasTabStaff: !tabStaves.isEmpty
        )
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        textBuffer = ""

        switch elementName {
        case "Part":
            partDepth += 1
            currentPart = MSCXPartDraft()

        case "Staff":
            let id = attributeDict["id"] ?? "1"
            if partDepth > 0 {
                currentPart?.staffIDs.append(id)
                currentPartStaffID = id
            } else {
                currentStaff = MSCXStaffDraft(id: id)
            }

        case "trackName":
            break

        case "defaultClef":
            break

        case "Measure":
            guard currentStaff != nil else { break }
            let number = Int(attributeDict["number"] ?? "") ?? ((currentStaff?.measures.count ?? 0) + 1)
            currentMeasure = MSCXMeasureDraft(number: number)

        case "voice":
            guard currentMeasure != nil else { break }
            currentVoice = []

        case "Chord":
            guard currentVoice != nil else { break }
            currentChord = MSCXChordDraft()
            currentChord?.duration.tuplet = pendingTuplet
            pendingTuplet = nil

        case "Rest":
            guard currentVoice != nil else { break }
            currentRest = MSCXRestDraft()
            currentRest?.duration.tuplet = pendingTuplet
            pendingTuplet = nil

        case "Note":
            currentNotePitch = nil

        case "TimeSig":
            inTimeSignature = true
            pendingSigN = nil
            pendingSigD = nil

        case "KeySig":
            inKeySignature = true
            pendingKeyFifths = nil

        case "Tempo":
            inTempo = true

        case "Tuplet":
            pendingTupletNormal = nil
            pendingTupletActual = nil

        case "clef":
            inClef = true
            currentClefSign = nil

        case "metaTag":
            currentMetaName = attributeDict["name"]

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        textBuffer += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let text = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "metaTag":
            if currentMetaName == "workTitle" {
                metaTitle = text
            } else if currentMetaName == "composer" {
                metaComposer = text
            }
            currentMetaName = nil

        case "trackName":
            if partDepth > 0 {
                currentPart?.name = text
            }

        case "defaultClef":
            if partDepth > 0, let staffID = currentPartStaffID {
                currentPart?.clefs[staffID] = text
            }

        case "durationType":
            let value = normalizeDurationType(text)
            if currentChord != nil {
                currentChord?.duration.type = value
                if value == "measure" {
                    currentChord?.duration.isMeasure = true
                }
            } else if currentRest != nil {
                currentRest?.duration.type = value
                if value == "measure" {
                    currentRest?.duration.isMeasure = true
                }
            }

        case "dots":
            let dots = Int(text) ?? 0
            if currentChord != nil {
                currentChord?.duration.dots = dots
            } else if currentRest != nil {
                currentRest?.duration.dots = dots
            }

        case "duration":
            if let ticks = Int(text) {
                if currentChord != nil {
                    currentChord?.duration.ticks = ticks
                } else if currentRest != nil {
                    currentRest?.duration.ticks = ticks
                }
            }

        case "grace":
            if text == "1" {
                currentChord?.isGrace = true
            }

        case "pitch":
            if let pitch = Int(text) {
                currentNotePitch = pitch
            }

        case "Note":
            if let pitch = currentNotePitch {
                currentChord?.pitches.append(pitch)
            }
            currentNotePitch = nil

        case "Chord":
            if let chord = currentChord, !chord.isGrace, !chord.pitches.isEmpty,
               let pitch = chord.pitches.min() {
                let duration = resolveDuration(
                    chord.duration,
                    timeSignature: pendingTimeSignature ?? currentTimeSignature
                )
                currentVoice?.append(.note(pitch: pitch, duration: duration))
            }
            currentChord = nil

        case "Rest":
            if let rest = currentRest {
                let duration = resolveDuration(
                    rest.duration,
                    timeSignature: pendingTimeSignature ?? currentTimeSignature
                )
                currentVoice?.append(.rest(duration: duration))
            }
            currentRest = nil

        case "voice":
            if let voice = currentVoice, !voice.isEmpty {
                currentMeasure?.voices.append(voice)
            }
            currentVoice = nil

        case "Measure":
            finishMeasure()
            currentMeasure = nil

        case "Staff":
            if partDepth > 0 {
                currentPartStaffID = nil
            } else if let staff = currentStaff {
                staves.append(staff)
                currentStaff = nil
            }

        case "Part":
            if let part = currentPart {
                parts.append(part)
            }
            currentPart = nil
            currentPartStaffID = nil
            partDepth = max(0, partDepth - 1)

        case "sigN":
            if inTimeSignature {
                pendingSigN = Int(text)
            }

        case "sigD":
            if inTimeSignature {
                pendingSigD = Int(text)
            }

        case "TimeSig":
            if inTimeSignature, let numerator = pendingSigN, let denominator = pendingSigD {
                pendingTimeSignature = TimeSignatureData(
                    numerator: numerator,
                    denominator: denominator
                )
            }
            inTimeSignature = false

        case "accidental":
            if inKeySignature, let fifths = Int(text) {
                pendingKeyFifths = fifths
            }

        case "concertKey":
            if inKeySignature, let fifths = Int(text) {
                pendingKeyFifths = fifths
            }

        case "KeySig":
            if inKeySignature {
                pendingKeySignature = KeySignatureData(
                    fifths: pendingKeyFifths ?? 0,
                    mode: "major"
                )
            }
            inKeySignature = false

        case "tempo":
            if inTempo, let value = Double(text), value > 0 {
                let bpm = value <= 10 ? value * 60 : value
                if bpm >= 20, bpm <= 400 {
                    pendingTempo = Int(bpm.rounded())
                }
            }

        case "Tempo":
            if let tempo = pendingTempo {
                if scoreTempo == nil {
                    scoreTempo = tempo
                }
                pendingTempo = nil
            }
            inTempo = false

        case "normalNotes":
            if let value = Int(text) {
                pendingTupletNormal = value
            }

        case "actualNotes":
            if let value = Int(text) {
                pendingTupletActual = value
            }

        case "Tuplet":
            var tuplet: (normal: Int, actual: Int)?
            if let normal = pendingTupletNormal, let actual = pendingTupletActual, normal > 0, actual > 0 {
                tuplet = (normal: normal, actual: actual)
            } else if let count = Int(text), count == 3 {
                tuplet = (normal: 3, actual: 2)
            }

            if let tuplet {
                if currentChord != nil {
                    currentChord?.duration.tuplet = tuplet
                } else if currentRest != nil {
                    currentRest?.duration.tuplet = tuplet
                } else {
                    pendingTuplet = tuplet
                }
            }

            pendingTupletNormal = nil
            pendingTupletActual = nil

        case "sign":
            if inClef {
                currentClefSign = text
            }

        case "clef":
            if inClef, let sign = currentClefSign {
                // 检测是否为TAB谱表
                if sign.uppercased().contains("TAB") {
                    currentStaff?.isTabStaff = true
                }
                inClef = false
                currentClefSign = nil
            }

        default:
            break
        }

        textBuffer = ""
    }

    private func finishMeasure() {
        guard var measure = currentMeasure, let staff = currentStaff else { return }

        if let pending = pendingTimeSignature {
            measure.timeSignature = pending
            currentTimeSignature = pending
            pendingTimeSignature = nil
        }

        if let pending = pendingKeySignature {
            measure.keySignature = pending
            currentKeySignature = pending
            pendingKeySignature = nil
        }

        let voice = measure.voices.max { $0.count < $1.count } ?? []
        var notes: [ScoreNote] = []

        for event in voice {
            switch event {
            case .note(let pitch, let duration):
                notes.append(ScoreNote(midiPitch: pitch, duration: duration))
            case .rest(let duration):
                notes.append(.rest(duration: duration))
            }
        }

        let targetTicks = (measure.timeSignature ?? currentTimeSignature).ticksPerMeasure
        notes = fillMeasure(notes, to: targetTicks)

        let scoreMeasure = ScoreMeasure(
            measureNumber: measure.number,
            notes: notes,
            timeSignature: measure.timeSignature,
            keySignature: measure.keySignature
        )

        var updatedStaff = staff
        updatedStaff.measures.append(scoreMeasure)
        currentStaff = updatedStaff
    }

    private func normalizeDurationType(_ value: String) -> String {
        switch value {
        case "16", "16th": return "16th"
        case "32", "32nd": return "32nd"
        case "64", "64th": return "64th"
        case "128", "128th": return "128th"
        case "breve", "long": return "whole"
        default: return value
        }
    }

    private func resolveDuration(
        _ draft: MSCXDurationDraft,
        timeSignature: TimeSignatureData
    ) -> NoteDuration {
        if let ticks = draft.ticks, ticks > 0 {
            return closestDuration(ticks: ticks)
        }

        if draft.isMeasure || draft.type == "measure" {
            return fullMeasureDuration(for: timeSignature)
        }

        var duration = baseDuration(for: draft.type)

        if let tuplet = draft.tuplet,
           tuplet.normal == 3, tuplet.actual == 2 {
            duration = tripletDuration(for: duration) ?? duration
        } else if draft.dots > 0 {
            duration = dottedDuration(for: duration) ?? duration
        }

        return duration
    }

    private func baseDuration(for type: String?) -> NoteDuration {
        switch type {
        case "whole": return .whole
        case "half": return .half
        case "quarter": return .quarter
        case "eighth": return .eighth
        case "16th": return .sixteenth
        case "32nd", "64th", "128th": return .thirtySecond
        default: return .quarter
        }
    }

    private func dottedDuration(for duration: NoteDuration) -> NoteDuration? {
        switch duration {
        case .whole: return nil
        case .half: return .dottedHalf
        case .quarter: return .dottedQuarter
        case .eighth: return .dottedEighth
        default: return duration
        }
    }

    private func tripletDuration(for duration: NoteDuration) -> NoteDuration? {
        switch duration {
        case .eighth: return .eighthTriplet
        case .sixteenth: return .sixteenthTriplet
        default: return nil
        }
    }

    private func fullMeasureDuration(for timeSignature: TimeSignatureData) -> NoteDuration {
        switch (timeSignature.numerator, timeSignature.denominator) {
        case (4, 4): return .whole
        case (3, 4), (6, 8), (9, 8), (12, 8): return .dottedHalf
        case (2, 4), (2, 2): return .half
        case (3, 8): return .dottedQuarter
        default: return .whole
        }
    }

    private func closestDuration(ticks: Int) -> NoteDuration {
        let durations: [NoteDuration] = [
            .whole, .dottedHalf, .half, .dottedQuarter, .quarter,
            .dottedEighth, .eighth, .sixteenth, .thirtySecond
        ]
        return durations.min { abs($0.ticks - ticks) < abs($1.ticks - ticks) } ?? .quarter
    }

    private func fillMeasure(_ notes: [ScoreNote], to targetTicks: Int) -> [ScoreNote] {
        let usedTicks = notes.reduce(0) { $0 + $1.duration.ticks }
        var remaining = targetTicks - usedTicks
        guard remaining > 0 else { return notes }

        var result = notes
        let rests: [NoteDuration] = [
            .whole, .dottedHalf, .half, .dottedQuarter,
            .quarter, .dottedEighth, .eighth, .sixteenth, .thirtySecond
        ]

        while remaining >= NoteDuration.thirtySecond.ticks {
            guard let duration = rests.first(where: { $0.ticks <= remaining }) else { break }
            result.append(.rest(duration: duration))
            remaining -= duration.ticks
        }

        return result
    }
}
