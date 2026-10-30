import Testing
@testable import BassPracticeCore

@Suite("Pitch Tests")
struct PitchTests {
    @Test("MIDI number calculation")
    func midiNumber() {
        let c4 = Pitch(noteName: .C, octave: 4)
        #expect(c4.midiNumber == 60)

        let a4 = Pitch(noteName: .A, octave: 4)
        #expect(a4.midiNumber == 69)

        let b0 = Pitch(noteName: .B, octave: 0)
        #expect(b0.midiNumber == 23)
    }

    @Test("Pitch from MIDI")
    func fromMidi() {
        let pitch = Pitch.from(midi: 60)
        #expect(pitch.noteName == .C)
        #expect(pitch.octave == 4)

        let pitch2 = Pitch.from(midi: 69)
        #expect(pitch2.noteName == .A)
        #expect(pitch2.octave == 4)
    }

    @Test("Transposition")
    func transpose() {
        let c4 = Pitch(noteName: .C, octave: 4)
        let e4 = c4.transposed(by: 4)
        #expect(e4.noteName == .E)
        #expect(e4.octave == 4)
    }
}

@Suite("FretboardConfig Tests")
struct FretboardConfigTests {
    @Test("Standard 5-string bass tuning")
    func tuning() {
        let config = FretboardConfig.standard5StringBass
        #expect(config.stringCount == 5)
        #expect(config.fretCount == 24)
        #expect(config.tuning.count == 5)
        #expect(config.tuning[0].noteName == .B)
        #expect(config.tuning[0].octave == 0)
        #expect(config.tuning[4].noteName == .G)
        #expect(config.tuning[4].octave == 2)
    }
}

@Suite("StringFretSolver Tests")
struct StringFretSolverTests {
    let config = FretboardConfig.standard5StringBass
    let solver = StringFretSolver(config: FretboardConfig.standard5StringBass)

    @Test("Fret calculation for pitch on string")
    func fretForPitch() {
        let d2 = Pitch(noteName: .D, octave: 2)
        let fretOnDString = solver.fretForPitch(d2, onString: 3)
        #expect(fretOnDString == 0)

        let fretOnGString = solver.fretForPitch(d2, onString: 4)
        #expect(fretOnGString == nil)

        let fretOnBString = solver.fretForPitch(d2, onString: 0)
        #expect(fretOnBString == 15)
    }

    @Test("All positions for pitch")
    func allPositions() {
        let d2 = Pitch(noteName: .D, octave: 2)
        let positions = solver.allPositionsForPitch(d2)
        #expect(positions.count >= 3)
    }

    @Test("Invalid position returns nil")
    func invalidPosition() {
        let b0 = Pitch(noteName: .B, octave: 0)
        let fretOnGString = solver.fretForPitch(b0, onString: 4)
        #expect(fretOnGString == nil)
    }
}

@Suite("FingeringGenerator Tests")
struct FingeringGeneratorTests {
    let config = FretboardConfig.standard5StringBass
    let generator = FingeringGenerator(config: FretboardConfig.standard5StringBass)

    @Test("Generate fingerings for minor pentatonic")
    func generateMinorPentatonic() {
        let root = Pitch(noteName: .A, octave: 1)
        let scale = Scale.minorPentatonic
        let pitches = scale.pitches(root: root)
        let patterns = generator.generate(pitches: pitches)

        #expect(!patterns.isEmpty)
        #expect(patterns.count <= 30)

        for pattern in patterns {
            #expect(pattern.positions.count == pitches.count)
        }
    }

    @Test("Fret span constraint")
    func fretSpanConstraint() {
        let root = Pitch(noteName: .C, octave: 2)
        let scale = Scale.major
        let pitches = scale.pitches(root: root)
        let patterns = generator.generate(pitches: pitches)

        for pattern in patterns {
            let frets = pattern.positions.map(\.fretNumber)
            let span = (frets.max() ?? 0) - (frets.min() ?? 0)
            #expect(span <= 6)
        }
    }
}

@Suite("Scale Tests")
struct ScaleTests {
    @Test("Scale pitch generation")
    func pitches() {
        let scale = Scale.major
        let root = Pitch(noteName: .C, octave: 4)
        let pitches = scale.pitches(root: root)

        #expect(pitches.count == 8)
        #expect(pitches[0].noteName == .C)
        #expect(pitches[1].noteName == .D)
        #expect(pitches[2].noteName == .E)
        #expect(pitches[7].noteName == .C)
        #expect(pitches[7].octave == 5)
    }

    @Test("Minor pentatonic intervals")
    func minorPentatonic() {
        let scale = Scale.minorPentatonic
        #expect(scale.intervals.count == 6)
        #expect(scale.intervals[0].semitones == 0)
        #expect(scale.intervals[1].semitones == 3)
        #expect(scale.intervals[2].semitones == 5)
        #expect(scale.intervals[3].semitones == 7)
        #expect(scale.intervals[4].semitones == 10)
        #expect(scale.intervals[5].semitones == 12)
    }
}

@Suite("MusicXMLExporter Tests")
struct MusicXMLExporterTests {
    @Test("Empty measure exports a full-measure rest")
    func emptyMeasure() {
        let score = Score(
            title: "Empty",
            measures: [ScoreMeasure(measureNumber: 1, notes: [])]
        )
        let xml = MusicXMLExporter().export(score: score)

        #expect(xml.contains("<rest measure=\"yes\"/>"))
        #expect(xml.contains("<duration>1920</duration>"))
    }

    @Test("Empty measure honors the score time signature")
    func emptyMeasureTimeSignature() {
        let score = Score(
            title: "Waltz",
            timeSignature: TimeSignatureData(numerator: 3, denominator: 4),
            measures: [ScoreMeasure(measureNumber: 1, notes: [])]
        )
        let xml = MusicXMLExporter().export(score: score)

        #expect(xml.contains("<rest measure=\"yes\"/>"))
        #expect(xml.contains("<duration>1440</duration>"))
    }

    @Test("Measure with notes is exported normally")
    func measureWithNotes() {
        let note = ScoreNote(midiPitch: 40, duration: .quarter)
        let score = Score(
            title: "One Note",
            measures: [ScoreMeasure(measureNumber: 1, notes: [note])]
        )
        let xml = MusicXMLExporter().export(score: score)

        #expect(!xml.contains("measure=\"yes\""))
        #expect(xml.contains("<duration>480</duration>"))
    }
}
