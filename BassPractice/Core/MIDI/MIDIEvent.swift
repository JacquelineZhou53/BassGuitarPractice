import Foundation

enum MIDIEvent: Codable, Hashable {
    case noteOn(channel: UInt8, note: UInt8, velocity: UInt8, tick: UInt32)
    case noteOff(channel: UInt8, note: UInt8, tick: UInt32)
    case tempoChange(microsecondsPerBeat: UInt32, tick: UInt32)
    case timeSignature(numerator: UInt8, denominator: UInt8, tick: UInt32)
    case keySignature(key: Int8, scale: UInt8, tick: UInt32)
    case programChange(channel: UInt8, program: UInt8, tick: UInt32)
    case controlChange(channel: UInt8, controller: UInt8, value: UInt8, tick: UInt32)
    case metaEvent(type: UInt8, data: [UInt8], tick: UInt32)
    case unknown(status: UInt8, data: [UInt8], tick: UInt32)

    var tick: UInt32 {
        switch self {
        case .noteOn(_, _, _, let tick): return tick
        case .noteOff(_, _, let tick): return tick
        case .tempoChange(_, let tick): return tick
        case .timeSignature(_, _, let tick): return tick
        case .keySignature(_, _, let tick): return tick
        case .programChange(_, _, let tick): return tick
        case .controlChange(_, _, _, let tick): return tick
        case .metaEvent(_, _, let tick): return tick
        case .unknown(_, _, let tick): return tick
        }
    }
}

struct MIDITrack: Codable, Hashable {
    let name: String?
    let events: [MIDIEvent]

    var noteOnEvents: [MIDIEvent] {
        events.filter { if case .noteOn = $0 { return true }; return false }
    }

    var noteOffEvents: [MIDIEvent] {
        events.filter { if case .noteOff = $0 { return true }; return false }
    }

    var tempoChanges: [MIDIEvent] {
        events.filter { if case .tempoChange = $0 { return true }; return false }
    }

    var timeSignatures: [MIDIEvent] {
        events.filter { if case .timeSignature = $0 { return true }; return false }
    }

    var keySignatures: [MIDIEvent] {
        events.filter { if case .keySignature = $0 { return true }; return false }
    }
}

struct MIDIFile: Codable {
    let format: UInt16
    let trackCount: UInt16
    let ticksPerQuarterNote: UInt16
    let tracks: [MIDITrack]

    var allEvents: [MIDIEvent] {
        tracks.flatMap(\.events).sorted { $0.tick < $1.tick }
    }

    var tempoMap: [(tick: UInt32, microsecondsPerBeat: UInt32)] {
        var map: [(UInt32, UInt32)] = []
        for track in tracks {
            for event in track.events {
                if case .tempoChange(let mpb, let tick) = event {
                    map.append((tick, mpb))
                }
            }
        }
        return map.sorted { $0.0 < $1.0 }
    }

    func tickToSeconds(tick: UInt32) -> Double {
        let tempo = tempoMap
        var currentTime: Double = 0
        var lastTick: UInt32 = 0
        var currentTempo: UInt32 = 500000

        for (tempoTick, mpb) in tempo {
            if tempoTick >= tick { break }
            let ticksElapsed = tempoTick - lastTick
            currentTime += Double(ticksElapsed) * Double(currentTempo) / Double(ticksPerQuarterNote) / 1_000_000.0
            lastTick = tempoTick
            currentTempo = mpb
        }

        let remainingTicks = tick - lastTick
        currentTime += Double(remainingTicks) * Double(currentTempo) / Double(ticksPerQuarterNote) / 1_000_000.0

        return currentTime
    }
}
