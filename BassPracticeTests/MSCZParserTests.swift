import Testing
import Foundation
import Compression
@testable import BassPracticeCore

@Suite("MSCZ Parser Tests")
struct MSCZParserTests {
    private let scoreXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <museScore version="4.20">
      <Score>
        <metaTag name="workTitle">Bass Test</metaTag>
        <metaTag name="composer">Composer</metaTag>
        <Part>
          <Staff id="1">
            <defaultClef>F</defaultClef>
          </Staff>
          <trackName>Bass</trackName>
        </Part>
        <Staff id="1">
          <Measure number="1">
            <voice>
              <TimeSig><sigN>4</sigN><sigD>4</sigD></TimeSig>
              <KeySig><accidental>2</accidental></KeySig>
              <Tempo><tempo>2</tempo></Tempo>
              <Chord>
                <durationType>quarter</durationType>
                <Note><pitch>40</pitch></Note>
              </Chord>
              <Rest><durationType>half</durationType></Rest>
              <Chord>
                <durationType>quarter</durationType>
                <Note><pitch>43</pitch></Note>
              </Chord>
            </voice>
          </Measure>
        </Staff>
      </Score>
    </museScore>
    """

    @Test("Parses a plain MSCX score")
    func parsesMSCX() throws {
        let data = try #require(scoreXML.data(using: .utf8))
        let score = try MSCZParser().parse(data: data, title: "fallback")

        #expect(score.title == "Bass Test")
        #expect(score.composer == "Composer")
        #expect(score.tempo == 120)
        #expect(score.timeSignature == TimeSignatureData(numerator: 4, denominator: 4))
        #expect(score.keySignature.fifths == 2)
        #expect(score.measures.count == 1)

        let notes = score.measures[0].notes
        #expect(notes.count == 3)
        #expect(notes[0].midiPitch == 40)
        #expect(notes[1].isRest)
        #expect(notes[2].midiPitch == 43)
    }

    @Test("Reads a deflated MSCZ container")
    func parsesDeflatedMSCZ() throws {
        let zipData = makeZIP(
            entries: [("score.mscx", Data(scoreXML.utf8), .deflate)]
        )
        let score = try MSCZParser().parse(data: zipData, title: "fallback")

        #expect(score.title == "Bass Test")
        #expect(score.measures.count == 1)
        #expect(score.measures[0].notes.filter { !$0.isRest }.count == 2)
    }

    @Test("Prefers the bass staff in a multi-staff score")
    func prefersBassStaff() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <museScore version="4.20">
          <Score>
            <Part>
              <Staff id="1"><defaultClef>G</defaultClef></Staff>
              <trackName>Piano</trackName>
            </Part>
            <Part>
              <Staff id="2"><defaultClef>F</defaultClef></Staff>
              <trackName>Bass</trackName>
            </Part>
            <Staff id="1">
              <Measure number="1">
                <voice>
                  <Chord><durationType>whole</durationType><Note><pitch>72</pitch></Note></Chord>
                </voice>
              </Measure>
            </Staff>
            <Staff id="2">
              <Measure number="1">
                <voice>
                  <Chord><durationType>whole</durationType><Note><pitch>40</pitch></Note></Chord>
                </voice>
              </Measure>
            </Staff>
          </Score>
        </museScore>
        """

        let data = try #require(xml.data(using: .utf8))
        let score = try MSCZParser().parse(data: data, title: "fallback")
        let notes = score.measures.flatMap(\.notes).filter { !$0.isRest }

        #expect(notes.count == 1)
        #expect(notes[0].midiPitch == 40)
    }
}

private enum ZIPTestCompression {
    case store
    case deflate
}

private func makeZIP(entries: [(name: String, data: Data, compression: ZIPTestCompression)]) -> Data {
    struct CentralEntry {
        let name: Data
        let method: UInt16
        let compressedSize: UInt32
        let uncompressedSize: UInt32
        let localOffset: UInt32
    }

    var output = Data()
    var centralEntries: [CentralEntry] = []

    for entry in entries {
        let nameData = Data(entry.name.utf8)
        let localOffset = UInt32(output.count)
        let method: UInt16
        let payload: Data

        switch entry.compression {
        case .store:
            method = 0
            payload = entry.data
        case .deflate:
            method = 8
            payload = deflate(entry.data)
        }

        appendUInt32(0x04034b50, to: &output)
        appendUInt16(20, to: &output)
        appendUInt16(0, to: &output)
        appendUInt16(method, to: &output)
        appendUInt16(0, to: &output)
        appendUInt16(0, to: &output)
        appendUInt32(0, to: &output)
        appendUInt32(UInt32(payload.count), to: &output)
        appendUInt32(UInt32(entry.data.count), to: &output)
        appendUInt16(UInt16(nameData.count), to: &output)
        appendUInt16(0, to: &output)
        output.append(nameData)
        output.append(payload)

        centralEntries.append(CentralEntry(
            name: nameData,
            method: method,
            compressedSize: UInt32(payload.count),
            uncompressedSize: UInt32(entry.data.count),
            localOffset: localOffset
        ))
    }

    let centralOffset = UInt32(output.count)

    for entry in centralEntries {
        appendUInt32(0x02014b50, to: &output)
        appendUInt16(20, to: &output)
        appendUInt16(20, to: &output)
        appendUInt16(0, to: &output)
        appendUInt16(entry.method, to: &output)
        appendUInt16(0, to: &output)
        appendUInt16(0, to: &output)
        appendUInt32(0, to: &output)
        appendUInt32(entry.compressedSize, to: &output)
        appendUInt32(entry.uncompressedSize, to: &output)
        appendUInt16(UInt16(entry.name.count), to: &output)
        appendUInt16(0, to: &output)
        appendUInt16(0, to: &output)
        appendUInt16(0, to: &output)
        appendUInt16(0, to: &output)
        appendUInt32(0, to: &output)
        appendUInt32(entry.localOffset, to: &output)
        output.append(entry.name)
    }

    let centralSize = UInt32(output.count) - centralOffset

    appendUInt32(0x06054b50, to: &output)
    appendUInt16(0, to: &output)
    appendUInt16(0, to: &output)
    appendUInt16(UInt16(centralEntries.count), to: &output)
    appendUInt16(UInt16(centralEntries.count), to: &output)
    appendUInt32(centralSize, to: &output)
    appendUInt32(centralOffset, to: &output)
    appendUInt16(0, to: &output)

    return output
}

private func deflate(_ data: Data) -> Data {
    guard !data.isEmpty else { return Data() }

    var output = [UInt8](repeating: 0, count: data.count + 64)
    let size = data.withUnsafeBytes { rawBuffer -> Int in
        guard let source = rawBuffer.bindMemory(to: UInt8.self).baseAddress else {
            return 0
        }
        return compression_encode_buffer(
            &output,
            output.count,
            source,
            data.count,
            nil,
            COMPRESSION_ZLIB
        )
    }
    return Data(output.prefix(size))
}

private func appendUInt16(_ value: UInt16, to data: inout Data) {
    data.append(UInt8(value & 0xFF))
    data.append(UInt8((value >> 8) & 0xFF))
}

private func appendUInt32(_ value: UInt32, to data: inout Data) {
    data.append(UInt8(value & 0xFF))
    data.append(UInt8((value >> 8) & 0xFF))
    data.append(UInt8((value >> 16) & 0xFF))
    data.append(UInt8((value >> 24) & 0xFF))
}
