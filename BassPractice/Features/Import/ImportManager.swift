import Foundation
import SwiftData

enum ImportManagerError: Error, LocalizedError {
    case unsupportedType(String)
    case missingFile
    case unableToRead(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedType(let ext):
            return "暂不支持 .\(ext) 文件。目前支持 PDF、MIDI、MSCZ 和 MSCX。"
        case .missingFile:
            return "无法访问所选文件。"
        case .unableToRead(let message):
            return "读取文件失败：\(message)"
        }
    }
}

enum ImportManager {
    /// Converts an external file into a Score ready to be persisted.
    /// PDF files produce a metadata-only Score whose `sourceFileURL` points at
    /// the copied PDF; notation files produce a normal editable Score.
    static func makeScore(from url: URL, instrumentType: InstrumentType = .bass) throws -> Score {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard url.isFileURL else {
            throw ImportManagerError.missingFile
        }

        let title = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension.lowercased()
        let config = instrumentType.defaultFretboardConfig

        switch ext {
        case "pdf":
            let relativePath = try ImportedFileStore.copyImportedFile(from: url)
            return Score(
                title: title,
                sourceType: .pdfImport,
                instrumentType: instrumentType,
                sourceFileURL: relativePath
            )

        case "mid", "midi":
            let data = try readData(from: url)
            let midiFile = try MIDIParser(data: data).parse()
            let converter = MIDIToScoreConverter(ticksPerQuarterNote: midiFile.ticksPerQuarterNote)
            var score = converter.convert(midiFile, title: title)
            score.instrumentType = instrumentType
            score.sourceFileURL = try ImportedFileStore.copyImportedFile(from: url)
            let tabScore = TabGenerator(config: config).generateTab(for: score)
            score = mergeTabPositions(standard: score, tab: tabScore)
            return score

        case "mscz", "mscx":
            let data = try readData(from: url)
            let result = try MSCZParser().parse(data: data, title: title)
            var score = result.standardScore
            score.instrumentType = instrumentType
            score.sourceFileURL = try ImportedFileStore.copyImportedFile(from: url)
            let tabScore: Score
            if result.hasTabStaff, let resultTab = result.tabScore {
                tabScore = resultTab
            } else {
                tabScore = TabGenerator(config: config).generateTab(for: score)
            }
            score = mergeTabPositions(standard: score, tab: tabScore)
            return score

        default:
            throw ImportManagerError.unsupportedType(ext)
        }
    }

    @MainActor
    static func persist(_ score: Score, in modelContext: ModelContext) throws {
        modelContext.insert(StoredScore(score: score))
        try modelContext.save()
    }

    private static func readData(from url: URL) throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw ImportManagerError.unableToRead(error.localizedDescription)
        }
    }

    private static func mergeTabPositions(standard: Score, tab: Score) -> Score {
        var merged = standard
        for mi in 0..<merged.measures.count {
            guard mi < tab.measures.count else { break }
            let tabNotes = tab.measures[mi].notes
            for ni in 0..<merged.measures[mi].notes.count {
                guard ni < tabNotes.count, let pos = tabNotes[ni].fretboardPosition else { continue }
                merged.measures[mi].notes[ni].fretboardPosition = pos
            }
        }
        return merged
    }
}
