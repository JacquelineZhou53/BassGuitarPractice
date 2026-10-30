import Foundation

final class MIDIParser {
    private var data: Data
    private var offset: Int = 0

    init(data: Data) {
        self.data = data
    }

    enum MIDIError: Error, LocalizedError {
        case invalidHeader
        case invalidTrack
        case unexpectedEndOfFile
        case unsupportedFormat

        var errorDescription: String? {
            switch self {
            case .invalidHeader: return "Invalid MIDI header"
            case .invalidTrack: return "Invalid MIDI track"
            case .unexpectedEndOfFile: return "Unexpected end of file"
            case .unsupportedFormat: return "Unsupported MIDI format"
            }
        }
    }

    func parse() throws -> MIDIFile {
        offset = 0

        let headerChunk = try readBytes(4)
        guard String(bytes: headerChunk, encoding: .ascii) == "MThd" else {
            throw MIDIError.invalidHeader
        }

        let headerLength = try readUInt32()
        guard headerLength >= 6 else {
            throw MIDIError.invalidHeader
        }

        let format = try readUInt16()
        let trackCount = try readUInt16()
        let division = try readUInt16()

        guard format == 0 || format == 1 else {
            throw MIDIError.unsupportedFormat
        }

        var tracks: [MIDITrack] = []
        for _ in 0..<trackCount {
            tracks.append(try readTrack())
        }

        return MIDIFile(format: format, trackCount: trackCount, ticksPerQuarterNote: division, tracks: tracks)
    }

    private func readTrack() throws -> MIDITrack {
        let trackChunk = try readBytes(4)
        guard String(bytes: trackChunk, encoding: .ascii) == "MTrk" else {
            throw MIDIError.invalidTrack
        }

        let trackLength = Int(try readUInt32())
        let trackEnd = offset + trackLength

        var events: [MIDIEvent] = []
        var currentTick: UInt32 = 0
        var runningStatus: UInt8 = 0
        var trackName: String? = nil

        while offset < trackEnd {
            let delta = readVLQ()
            currentTick += delta

            guard offset < trackEnd else { break }

            var statusByte = data[offset]

            if statusByte < 0x80 {
                statusByte = runningStatus
            } else {
                offset += 1
                if statusByte < 0xF0 {
                    runningStatus = statusByte
                }
            }

            let event = try parseEvent(status: statusByte, tick: currentTick, trackName: &trackName)
            events.append(event)
        }

        offset = trackEnd
        return MIDITrack(name: trackName, events: events)
    }

    private func parseEvent(status: UInt8, tick: UInt32, trackName: inout String?) throws -> MIDIEvent {
        let type = status & 0xF0
        let channel = status & 0x0F

        switch type {
        case 0x80:
            let note = try readByte()
            _ = try readByte()
            return .noteOff(channel: channel, note: note, tick: tick)

        case 0x90:
            let note = try readByte()
            let velocity = try readByte()
            if velocity == 0 {
                return .noteOff(channel: channel, note: note, tick: tick)
            }
            return .noteOn(channel: channel, note: note, velocity: velocity, tick: tick)

        case 0xA0:
            let note = try readByte()
            let pressure = try readByte()
            return .unknown(status: status, data: [note, pressure], tick: tick)

        case 0xB0:
            let controller = try readByte()
            let value = try readByte()
            return .controlChange(channel: channel, controller: controller, value: value, tick: tick)

        case 0xC0:
            let program = try readByte()
            return .programChange(channel: channel, program: program, tick: tick)

        case 0xD0:
            let pressure = try readByte()
            return .unknown(status: status, data: [pressure], tick: tick)

        case 0xE0:
            let lsb = try readByte()
            let msb = try readByte()
            return .unknown(status: status, data: [lsb, msb], tick: tick)

        case 0xF0:
            return try parseMetaOrSysExEvent(status: status, tick: tick, trackName: &trackName)

        default:
            return .unknown(status: status, data: [], tick: tick)
        }
    }

    private func parseMetaOrSysExEvent(status: UInt8, tick: UInt32, trackName: inout String?) throws -> MIDIEvent {
        switch status {
        case 0xFF:
            let metaType = try readByte()
            let length = Int(readVLQ())
            let metaData = try readBytes(length)

            switch metaType {
            case 0x03:
                trackName = String(bytes: metaData, encoding: .utf8)
                return .metaEvent(type: metaType, data: Array(metaData), tick: tick)

            case 0x51:
                guard metaData.count >= 3 else { throw MIDIError.invalidTrack }
                let mpb = UInt32(metaData[0]) << 16 | UInt32(metaData[1]) << 8 | UInt32(metaData[2])
                return .tempoChange(microsecondsPerBeat: mpb, tick: tick)

            case 0x58:
                guard metaData.count >= 4 else { throw MIDIError.invalidTrack }
                return .timeSignature(numerator: metaData[0], denominator: UInt8(pow(2.0, Double(metaData[1]))), tick: tick)

            case 0x59:
                guard metaData.count >= 2 else { throw MIDIError.invalidTrack }
                return .keySignature(key: Int8(bitPattern: metaData[0]), scale: metaData[1], tick: tick)

            default:
                return .metaEvent(type: metaType, data: Array(metaData), tick: tick)
            }

        case 0xF0, 0xF7:
            let length = Int(readVLQ())
            let sysExData = try readBytes(length)
            return .unknown(status: status, data: Array(sysExData), tick: tick)

        default:
            return .unknown(status: status, data: [], tick: tick)
        }
    }

    private func readByte() throws -> UInt8 {
        guard offset < data.count else {
            throw MIDIError.unexpectedEndOfFile
        }
        let byte = data[offset]
        offset += 1
        return byte
    }

    private func readBytes(_ count: Int) throws -> Data {
        guard offset + count <= data.count else {
            throw MIDIError.unexpectedEndOfFile
        }
        let slice = data[offset..<(offset + count)]
        offset += count
        return slice
    }

    private func readUInt16() throws -> UInt16 {
        let bytes = try readBytes(2)
        return UInt16(bytes[0]) << 8 | UInt16(bytes[1])
    }

    private func readUInt32() throws -> UInt32 {
        let bytes = try readBytes(4)
        return UInt32(bytes[0]) << 24 | UInt32(bytes[1]) << 16 | UInt32(bytes[2]) << 8 | UInt32(bytes[3])
    }

    private func readVLQ() -> UInt32 {
        var result: UInt32 = 0
        var byte: UInt8

        repeat {
            guard offset < data.count else { return result }
            byte = data[offset]
            offset += 1
            result = (result << 7) | UInt32(byte & 0x7F)
        } while byte & 0x80 != 0

        return result
    }
}
