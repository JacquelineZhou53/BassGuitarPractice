import Foundation

struct ScaleDefinition: Identifiable, Hashable {
    let id: String
    let scale: Scale
    let rootNote: Pitch
    let fingerings: [FingeringPattern]

    var displayName: String {
        "\(rootNote.noteName.displayName) \(scale.name)"
    }
}

struct ScaleLibrary {
    static let rootNotes: [Pitch] = [
        Pitch(noteName: .C, octave: 1),
        Pitch(noteName: .Cs, octave: 1),
        Pitch(noteName: .D, octave: 1),
        Pitch(noteName: .Ds, octave: 1),
        Pitch(noteName: .E, octave: 1),
        Pitch(noteName: .F, octave: 1),
        Pitch(noteName: .Fs, octave: 1),
        Pitch(noteName: .G, octave: 1),
        Pitch(noteName: .Gs, octave: 1),
        Pitch(noteName: .A, octave: 1),
        Pitch(noteName: .As, octave: 1),
        Pitch(noteName: .B, octave: 1)
    ]

    static let guitarRootNotes: [Pitch] = [
        Pitch(noteName: .C, octave: 3),
        Pitch(noteName: .Cs, octave: 3),
        Pitch(noteName: .D, octave: 3),
        Pitch(noteName: .Ds, octave: 3),
        Pitch(noteName: .E, octave: 3),
        Pitch(noteName: .F, octave: 3),
        Pitch(noteName: .Fs, octave: 3),
        Pitch(noteName: .G, octave: 3),
        Pitch(noteName: .Gs, octave: 3),
        Pitch(noteName: .A, octave: 3),
        Pitch(noteName: .As, octave: 3),
        Pitch(noteName: .B, octave: 3)
    ]

    static func generateFingerings(
        for scale: Scale,
        root: Pitch,
        config: FretboardConfig = .standard5StringBass
    ) -> [FingeringPattern] {
        let generator = FingeringGenerator(config: config)
        let pitches = scale.pitches(root: root)
        return generator.generate(pitches: pitches)
    }

    static func generateArpeggioFingerings(
        for arpeggio: Arpeggio,
        root: Pitch,
        config: FretboardConfig = .standard5StringBass
    ) -> [FingeringPattern] {
        let generator = FingeringGenerator(config: config)
        let pitches = arpeggio.pitches(root: root)
        var constraints = FingeringConstraints.default
        constraints.maxFretSpan = 6
        constraints.maxPositionWidth = 7
        return generator.generate(pitches: pitches, constraints: constraints)
    }

    static func generateChordFingerings(
        for chord: Chord,
        root: Pitch,
        config: FretboardConfig = .standard5StringBass
    ) -> [FingeringPattern] {
        let generator = FingeringGenerator(config: config)
        let basePitches = chord.pitches(root: root)
        
        var pitches = basePitches
        if pitches.count < config.stringCount {
            if let rootOctave = basePitches.first?.transposed(by: 12) {
                pitches.append(rootOctave)
            }
        }
        
        let solver = StringFretSolver(config: config)
        pitches.sort { a, b in
            let minA = solver.allPositionsForPitch(a).map(\.fretNumber).min() ?? Int.max
            let minB = solver.allPositionsForPitch(b).map(\.fretNumber).min() ?? Int.max
            return minA < minB
        }
        
        var constraints = FingeringConstraints.default
        constraints.maxFretSpan = 8
        constraints.maxPositionWidth = 12
        constraints.minNotes = 3
        constraints.requireUniqueStrings = true
        constraints.maxPatterns = 50
        return generator.generate(pitches: pitches, constraints: constraints)
    }

    static func allScaleDefinitions(
        config: FretboardConfig = .standard5StringBass
    ) -> [ScaleCategory: [ScaleDefinition]] {
        var result: [ScaleCategory: [ScaleDefinition]] = [:]

        for scale in Scale.allScales {
            var definitions: [ScaleDefinition] = []
            for root in rootNotes {
                let fingerings = generateFingerings(for: scale, root: root, config: config)
                let def = ScaleDefinition(
                    id: "\(scale.id)_\(root.noteName.rawValue)",
                    scale: scale,
                    rootNote: root,
                    fingerings: fingerings
                )
                definitions.append(def)
            }
            result[scale.category] = definitions
        }

        return result
    }

    static func allArpeggioDefinitions(
        config: FretboardConfig = .standard5StringBass
    ) -> [ScaleDefinition] {
        var definitions: [ScaleDefinition] = []

        for arpeggio in Arpeggio.allArpeggios {
            for root in rootNotes {
                let fingerings = generateArpeggioFingerings(for: arpeggio, root: root, config: config)
                let scale = Scale(
                    id: arpeggio.id,
                    name: arpeggio.name,
                    category: .arpeggio,
                    intervals: arpeggio.intervals
                )
                let def = ScaleDefinition(
                    id: "\(arpeggio.id)_\(root.noteName.rawValue)",
                    scale: scale,
                    rootNote: root,
                    fingerings: fingerings
                )
                definitions.append(def)
            }
        }

        return definitions
    }
}
