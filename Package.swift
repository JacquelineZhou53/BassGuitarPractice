// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BassPractice",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "BassPracticeCore", targets: ["BassPracticeCore"]),
    ],
    targets: [
        .target(
            name: "BassPracticeCore",
            path: "BassPractice",
            exclude: ["Features/Notation/Resources/osmd/vexflow-min.js", "Features/Notation/Resources/osmd/opensheetmusicdisplay.min.js", "Features/Notation/Resources/notation_template.html"],
            sources: [
                "Core/MusicTheory/Pitch.swift",
                "Core/MusicTheory/Interval.swift",
                "Core/MusicTheory/Scale.swift",
                "Core/MusicTheory/Arpeggio.swift",
                "Core/Fretboard/FretboardConfig.swift",
                "Core/Fretboard/FretboardPosition.swift",
                "Core/Fretboard/FretboardMap.swift",
                "Core/Fretboard/StringFretSolver.swift",
                "Core/Fretboard/FingeringGenerator.swift",
                "Core/MIDI/MIDIEvent.swift",
                "Core/MIDI/MIDIParser.swift",
                "Core/MIDI/MIDIToScoreConverter.swift",
                "Core/MSCZ/ZIPArchiveReader.swift",
                "Core/MSCZ/MSCZParser.swift",
                "Models/Score.swift",
                "Rendering/MusicXMLExporter.swift",
                "Rendering/MIDIExporter.swift",
            ]
        ),
        .testTarget(
            name: "BassPracticeTests",
            dependencies: ["BassPracticeCore"],
            path: "BassPracticeTests"
        ),
    ]
)
