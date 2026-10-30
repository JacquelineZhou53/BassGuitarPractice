import Foundation

struct MIDIToScoreConverter {
    let ticksPerQuarterNote: UInt16

    init(ticksPerQuarterNote: UInt16 = 480) {
        self.ticksPerQuarterNote = ticksPerQuarterNote
    }

    func convert(_ midiFile: MIDIFile, title: String = "Imported MIDI") -> Score {
        let tempoMap = midiFile.tempoMap
        let initialTempo: Int = {
            if let firstTempo = tempoMap.first {
                return Int(60_000_000 / firstTempo.microsecondsPerBeat)
            }
            return 120
        }()

        var timeSignature = TimeSignatureData()
        var keySignature = KeySignatureData()

        for track in midiFile.tracks {
            for event in track.events {
                if case .timeSignature(let num, let den, _) = event {
                    timeSignature = TimeSignatureData(numerator: Int(num), denominator: Int(den))
                }
                if case .keySignature(let key, let scale, _) = event {
                    keySignature = KeySignatureData(fifths: Int(key), mode: scale == 0 ? "major" : "minor")
                }
            }
        }

        let allNotes = extractNotes(from: midiFile)
        let quantizedNotes = quantizeNotes(allNotes)
        let measures = groupIntoMeasures(quantizedNotes, timeSignature: timeSignature)

        return Score(
            title: title,
            timeSignature: timeSignature,
            keySignature: keySignature,
            tempo: initialTempo,
            sourceType: .midiImport,
            measures: measures
        )
    }

    private struct RawNote {
        let pitch: UInt8
        let startTick: UInt32
        let endTick: UInt32
        let velocity: UInt8
    }

    private func extractNotes(from midiFile: MIDIFile) -> [RawNote] {
        var noteOns: [UInt8: (tick: UInt32, velocity: UInt8)] = [:]
        var rawNotes: [RawNote] = []

        let allEvents = midiFile.allEvents.sorted { $0.tick < $1.tick }

        for event in allEvents {
            switch event {
            case .noteOn(_, let note, let velocity, let tick):
                let key = note
                if noteOns[key] != nil {
                    let start = noteOns[key]!.tick
                    let vel = noteOns[key]!.velocity
                    rawNotes.append(RawNote(pitch: note, startTick: start, endTick: tick, velocity: vel))
                }
                noteOns[key] = (tick, velocity)

            case .noteOff(_, let note, let tick):
                if let start = noteOns[note] {
                    rawNotes.append(RawNote(pitch: note, startTick: start.tick, endTick: tick, velocity: start.velocity))
                    noteOns[note] = nil
                }

            default:
                break
            }
        }

        for (note, start) in noteOns {
            rawNotes.append(RawNote(pitch: note, startTick: start.tick, endTick: start.tick + UInt32(ticksPerQuarterNote), velocity: start.velocity))
        }

        return rawNotes.sorted { $0.startTick < $1.startTick }
    }

    private func quantizeNotes(_ rawNotes: [RawNote]) -> [ScoreNote] {
        return rawNotes.map { raw in
            let duration = Int(raw.endTick) - Int(raw.startTick)
            let noteDuration = closestDuration(to: duration, ticksPerQuarter: Int(ticksPerQuarterNote))

            return ScoreNote(
                midiPitch: Int(raw.pitch),
                duration: noteDuration,
                velocity: Int(raw.velocity)
            )
        }
    }

    private func quantizeToGrid(_ tick: Int, grid: Int) -> Int {
        let remainder = tick % grid
        if remainder < grid / 2 {
            return tick - remainder
        } else {
            return tick + grid - remainder
        }
    }

    private func closestDuration(to ticks: Int, ticksPerQuarter: Int) -> NoteDuration {
        let quarter = ticksPerQuarter
        let whole = quarter * 4
        let half = quarter * 2
        let eighth = quarter / 2
        let sixteenth = quarter / 4

        let durations: [(NoteDuration, Int)] = [
            (.whole, whole),
            (.half, half),
            (.quarter, quarter),
            (.eighth, eighth),
            (.sixteenth, sixteenth)
        ]

        return durations.min(by: { abs($0.1 - ticks) < abs($1.1 - ticks) })?.0 ?? .quarter
    }

    private func groupIntoMeasures(_ notes: [ScoreNote], timeSignature: TimeSignatureData) -> [ScoreMeasure] {
        guard !notes.isEmpty else { return [] }

        let ticksPerMeasure = timeSignature.ticksPerMeasure
        var measures: [ScoreMeasure] = []
        var currentMeasureNotes: [ScoreNote] = []
        var currentMeasureTicks: Int = 0
        var measureNumber = 1

        for note in notes {
            let noteTicks = note.duration.ticks

            if currentMeasureTicks + noteTicks > ticksPerMeasure && !currentMeasureNotes.isEmpty {
                measures.append(ScoreMeasure(
                    measureNumber: measureNumber,
                    notes: currentMeasureNotes
                ))
                measureNumber += 1
                currentMeasureNotes = []
                currentMeasureTicks = 0
            }

            currentMeasureNotes.append(note)
            currentMeasureTicks += noteTicks
        }

        if !currentMeasureNotes.isEmpty {
            measures.append(ScoreMeasure(
                measureNumber: measureNumber,
                notes: currentMeasureNotes
            ))
        }

        return measures
    }
}
