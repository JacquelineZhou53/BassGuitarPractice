import Foundation

struct MIDIExporter {
    func export(score: Score) -> Data {
        var bytes: [UInt8] = []

        writeHeaderChunk(&bytes, format: 0, trackCount: 1, ticksPerQuarter: 480)

        var trackBytes: [UInt8] = []
        writeTempoEvent(&trackBytes, tempo: score.tempo, tick: 0)
        writeTimeSignatureEvent(&trackBytes, timeSignature: score.timeSignature)
        writeKeySignatureEvent(&trackBytes, keySignature: score.keySignature)

        var currentTick: UInt32 = 0
        for measure in score.measures {
            for note in measure.notes {
                if note.isRest {
                    currentTick += UInt32(note.duration.ticks)
                    continue
                }

                let noteOnTick = currentTick
                let noteOffTick = currentTick + UInt32(note.duration.ticks)

                writeNoteOn(&trackBytes, channel: 0, note: UInt8(note.midiPitch), velocity: UInt8(note.velocity), tick: noteOnTick, lastTick: &currentTick)
                writeNoteOff(&trackBytes, channel: 0, note: UInt8(note.midiPitch), tick: noteOffTick, lastTick: &currentTick)
            }
        }

        writeEndOfTrack(&trackBytes)
        writeTrackChunk(&bytes, trackData: trackBytes)

        return Data(bytes)
    }

    private func writeHeaderChunk(_ bytes: inout [UInt8], format: UInt16, trackCount: UInt16, ticksPerQuarter: UInt16) {
        bytes.append(contentsOf: [0x4D, 0x54, 0x68, 0x64])
        writeUInt32(&bytes, 6)
        writeUInt16(&bytes, format)
        writeUInt16(&bytes, trackCount)
        writeUInt16(&bytes, ticksPerQuarter)
    }

    private func writeTrackChunk(_ bytes: inout [UInt8], trackData: [UInt8]) {
        bytes.append(contentsOf: [0x4D, 0x54, 0x72, 0x6B])
        writeUInt32(&bytes, UInt32(trackData.count))
        bytes.append(contentsOf: trackData)
    }

    private func writeTempoEvent(_ bytes: inout [UInt8], tempo: Int, tick: UInt32) {
        writeVLQ(&bytes, 0)
        bytes.append(0xFF)
        bytes.append(0x51)
        bytes.append(0x03)
        let mpb = UInt32(60_000_000 / tempo)
        bytes.append(UInt8((mpb >> 16) & 0xFF))
        bytes.append(UInt8((mpb >> 8) & 0xFF))
        bytes.append(UInt8(mpb & 0xFF))
    }

    private func writeTimeSignatureEvent(_ bytes: inout [UInt8], timeSignature: TimeSignatureData) {
        writeVLQ(&bytes, 0)
        bytes.append(0xFF)
        bytes.append(0x58)
        bytes.append(0x04)
        bytes.append(UInt8(timeSignature.numerator))

        var denom = timeSignature.denominator
        var log2denom: UInt8 = 0
        while denom > 1 {
            denom /= 2
            log2denom += 1
        }
        bytes.append(log2denom)
        bytes.append(24)
        bytes.append(8)
    }

    private func writeKeySignatureEvent(_ bytes: inout [UInt8], keySignature: KeySignatureData) {
        writeVLQ(&bytes, 0)
        bytes.append(0xFF)
        bytes.append(0x59)
        bytes.append(0x02)
        bytes.append(UInt8(bitPattern: Int8(keySignature.fifths)))
        bytes.append(keySignature.mode == "minor" ? 1 : 0)
    }

    private func writeNoteOn(_ bytes: inout [UInt8], channel: UInt8, note: UInt8, velocity: UInt8, tick: UInt32, lastTick: inout UInt32) {
        let delta = tick > lastTick ? tick - lastTick : 0
        if delta > 0 || bytes.isEmpty {
            writeVLQ(&bytes, delta)
        }
        bytes.append(0x90 | (channel & 0x0F))
        bytes.append(note & 0x7F)
        bytes.append(velocity & 0x7F)
        lastTick = tick
    }

    private func writeNoteOff(_ bytes: inout [UInt8], channel: UInt8, note: UInt8, tick: UInt32, lastTick: inout UInt32) {
        let delta = tick > lastTick ? tick - lastTick : 0
        writeVLQ(&bytes, delta)
        bytes.append(0x80 | (channel & 0x0F))
        bytes.append(note & 0x7F)
        bytes.append(0)
        lastTick = tick
    }

    private func writeEndOfTrack(_ bytes: inout [UInt8]) {
        writeVLQ(&bytes, 0)
        bytes.append(0xFF)
        bytes.append(0x2F)
        bytes.append(0x00)
    }

    private func writeUInt16(_ bytes: inout [UInt8], _ value: UInt16) {
        bytes.append(UInt8((value >> 8) & 0xFF))
        bytes.append(UInt8(value & 0xFF))
    }

    private func writeUInt32(_ bytes: inout [UInt8], _ value: UInt32) {
        bytes.append(UInt8((value >> 24) & 0xFF))
        bytes.append(UInt8((value >> 16) & 0xFF))
        bytes.append(UInt8((value >> 8) & 0xFF))
        bytes.append(UInt8(value & 0xFF))
    }

    private func writeVLQ(_ bytes: inout [UInt8], _ value: UInt32) {
        if value == 0 {
            bytes.append(0)
            return
        }

        var v = value
        var tempBytes: [UInt8] = []

        tempBytes.append(UInt8(v & 0x7F))
        v >>= 7

        while v > 0 {
            tempBytes.append(UInt8((v & 0x7F) | 0x80))
            v >>= 7
        }

        bytes.append(contentsOf: tempBytes.reversed())
    }
}
