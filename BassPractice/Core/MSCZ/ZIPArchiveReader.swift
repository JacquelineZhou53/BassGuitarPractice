import Foundation
import Compression

enum ZIPArchiveError: Error, LocalizedError {
    case invalidArchive
    case unsupportedCompression(UInt16)
    case encryptedEntry
    case corruptedEntry(String)
    case decompressionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidArchive:
            return "MSCZ 文件不是有效的 ZIP 压缩包。"
        case .unsupportedCompression(let method):
            return "暂不支持 ZIP 压缩方式 \(method)。"
        case .encryptedEntry:
            return "MSCZ 文件已加密，无法读取。"
        case .corruptedEntry(let name):
            return "MSCZ 内的 \(name) 已损坏。"
        case .decompressionFailed(let name):
            return "无法解压 MSCZ 内的 \(name)。"
        }
    }
}

struct ZIPArchiveEntry {
    let name: String
    let data: Data
}

struct ZIPArchive {
    let entries: [ZIPArchiveEntry]

    init(data: Data) throws {
        let eocdOffset = try Self.findEndOfCentralDirectory(in: data)
        let entryCount = Int(Self.readUInt16(data, at: eocdOffset + 10))
        let centralDirectoryOffset = Int(Self.readUInt32(data, at: eocdOffset + 16))

        guard entryCount < 0xFFFF, centralDirectoryOffset < data.count else {
            throw ZIPArchiveError.invalidArchive
        }

        var entries: [ZIPArchiveEntry] = []
        var cursor = centralDirectoryOffset

        for _ in 0..<entryCount {
            guard cursor + 46 <= data.count,
                  Self.readUInt32(data, at: cursor) == 0x02014b50 else {
                throw ZIPArchiveError.invalidArchive
            }

            let flags = Self.readUInt16(data, at: cursor + 8)
            let method = Self.readUInt16(data, at: cursor + 10)
            let compressedSize = Int(Self.readUInt32(data, at: cursor + 20))
            let uncompressedSize = Int(Self.readUInt32(data, at: cursor + 24))
            let nameLength = Int(Self.readUInt16(data, at: cursor + 28))
            let extraLength = Int(Self.readUInt16(data, at: cursor + 30))
            let commentLength = Int(Self.readUInt16(data, at: cursor + 32))
            let localHeaderOffset = Int(Self.readUInt32(data, at: cursor + 42))

            guard cursor + 46 + nameLength <= data.count else {
                throw ZIPArchiveError.invalidArchive
            }

            let nameData = data[(cursor + 46)..<(cursor + 46 + nameLength)]
            let name = String(data: nameData, encoding: .utf8)
                ?? String(data: nameData, encoding: .isoLatin1)
                ?? "unnamed"

            guard flags & 0x0001 == 0 else {
                throw ZIPArchiveError.encryptedEntry
            }

            guard localHeaderOffset + 30 <= data.count,
                  Self.readUInt32(data, at: localHeaderOffset) == 0x04034b50 else {
                throw ZIPArchiveError.corruptedEntry(name)
            }

            let localNameLength = Int(Self.readUInt16(data, at: localHeaderOffset + 26))
            let localExtraLength = Int(Self.readUInt16(data, at: localHeaderOffset + 28))
            let dataStart = localHeaderOffset + 30 + localNameLength + localExtraLength
            guard dataStart + compressedSize <= data.count else {
                throw ZIPArchiveError.corruptedEntry(name)
            }

            let compressedData = data[dataStart..<(dataStart + compressedSize)]
            let entryData: Data

            switch method {
            case 0:
                entryData = Data(compressedData)
            case 8:
                entryData = try Self.inflate(
                    Data(compressedData),
                    expectedSize: uncompressedSize,
                    name: name
                )
            default:
                throw ZIPArchiveError.unsupportedCompression(method)
            }

            entries.append(ZIPArchiveEntry(name: name, data: entryData))
            cursor += 46 + nameLength + extraLength + commentLength
        }

        self.entries = entries
    }

    func data(forFileEndingWith suffix: String) -> (name: String, data: Data)? {
        let lowercasedSuffix = suffix.lowercased()
        guard let entry = entries.first(where: {
            $0.name.lowercased().hasSuffix(lowercasedSuffix)
        }) else {
            return nil
        }
        return (entry.name, entry.data)
    }

    private static func findEndOfCentralDirectory(in data: Data) throws -> Int {
        let minimumSize = 22
        guard data.count >= minimumSize else {
            throw ZIPArchiveError.invalidArchive
        }

        let searchLength = min(data.count, 65_557)
        let start = data.count - searchLength

        for index in stride(from: data.count - minimumSize, through: start, by: -1) {
            if readUInt32(data, at: index) == 0x06054b50 {
                return index
            }
        }

        throw ZIPArchiveError.invalidArchive
    }

    private static func inflate(_ data: Data, expectedSize: Int, name: String) throws -> Data {
        guard expectedSize > 0 else { return Data() }

        var output = [UInt8](repeating: 0, count: expectedSize)
        let decodedSize = data.withUnsafeBytes { rawBuffer -> Int in
            guard let source = rawBuffer.bindMemory(to: UInt8.self).baseAddress else {
                return 0
            }
            return compression_decode_buffer(
                &output,
                output.count,
                source,
                data.count,
                nil,
                COMPRESSION_ZLIB
            )
        }

        guard decodedSize > 0 else {
            throw ZIPArchiveError.decompressionFailed(name)
        }
        return Data(output.prefix(decodedSize))
    }

    private static func readUInt16(_ data: Data, at offset: Int) -> UInt16 {
        guard offset + 1 < data.count else { return 0 }
        return UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private static func readUInt32(_ data: Data, at offset: Int) -> UInt32 {
        guard offset + 3 < data.count else { return 0 }
        return UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}
