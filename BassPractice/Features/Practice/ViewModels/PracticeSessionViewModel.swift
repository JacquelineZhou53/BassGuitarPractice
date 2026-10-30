import SwiftUI
import Observation

struct LoopRange: Equatable {
    var startMeasure: Int
    var endMeasure: Int

    var measureCount: Int {
        endMeasure - startMeasure + 1
    }

    var displayString: String {
        "\(startMeasure + 1)-\(endMeasure + 1)"
    }
}

@Observable
@MainActor
final class PracticeSessionViewModel {
    var score: Score
    let playbackEngine: MIDIPlaybackEngine
    let metronome: MetronomeEngine

    var practiceTempo: Int
    var originalTempo: Int
    var isSlowMode: Bool = false
    var slowModeRate: Double = 0.5
    var useMetronome: Bool = false
    var metronomeVolume: Float = 0.5

    var loopEnabled: Bool = false
    var loopRange: LoopRange?

    var selectedMeasure: Int = 0
    var highlightNoteId: UUID?
    var selectedFretboardNoteID: UUID?

    var practiceStartTime: Date?
    var totalPracticeSeconds: TimeInterval = 0
    var repeatCount: Int = 0

    var config: FretboardConfig = .standard5StringBass

    var fretboardNotes: [FretboardNote] = []
    var onScoreChanged: ((Score) -> Void)?

    init(score: Score, onScoreChanged: ((Score) -> Void)? = nil) {
        self.score = score
        self.originalTempo = score.tempo
        self.practiceTempo = score.tempo
        self.playbackEngine = MIDIPlaybackEngine()
        self.metronome = MetronomeEngine()
        self.onScoreChanged = onScoreChanged

        playbackEngine.load(score: score)
        metronome.beatsPerMeasure = score.timeSignature.numerator

        setupCallbacks()
        regenerateFretboardNotes()
    }

    private func setupCallbacks() {
        metronome.onBeat = { [weak self] beat, isAccent in
            self?.handleMetronomeBeat(beat: beat, isAccent: isAccent)
        }
    }

    private func handleMetronomeBeat(beat: Int, isAccent: Bool) {
        if !loopEnabled { return }

        if beat == 0, let range = loopRange {
            let currentMeasure = playbackEngine.currentMeasureIndex
            if currentMeasure >= range.endMeasure {
                playbackEngine.seekTo(measure: range.startMeasure)
                repeatCount += 1
            }
        }
    }

    func togglePlayPause() {
        if playbackEngine.isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        if practiceStartTime == nil {
            practiceStartTime = Date()
        }

        if isSlowMode {
            playbackEngine.playbackRate = slowModeRate
        } else {
            playbackEngine.playbackRate = 1.0
        }

        playbackEngine.tempo = practiceTempo
        playbackEngine.play()

        if useMetronome {
            metronome.tempo = practiceTempo
            metronome.beatsPerMeasure = score.timeSignature.numerator
            metronome.volume = metronomeVolume
            metronome.start()
        }

        if loopEnabled, let range = loopRange {
            playbackEngine.setLoopRange(start: range.startMeasure, end: range.endMeasure)
        } else {
            playbackEngine.setLoopRange(start: nil, end: nil)
        }
    }

    func pause() {
        playbackEngine.pause()
        metronome.stop()
        updateTotalPracticeTime()
    }

    func stop() {
        playbackEngine.stop()
        metronome.stop()
        selectedMeasure = 0
        highlightNoteId = nil
        updateTotalPracticeTime()
    }

    func seekToMeasure(_ measure: Int) {
        playbackEngine.seekTo(measure: measure)
        selectedMeasure = measure
    }

    func setSlowMode(enabled: Bool) {
        isSlowMode = enabled
        if playbackEngine.isPlaying {
            playbackEngine.playbackRate = enabled ? slowModeRate : 1.0
        }
    }

    func setSlowModeRate(_ rate: Double) {
        slowModeRate = rate
        if isSlowMode && playbackEngine.isPlaying {
            playbackEngine.playbackRate = rate
        }
    }

    func setPracticeTempo(_ tempo: Int) {
        practiceTempo = tempo
        if playbackEngine.isPlaying {
            playbackEngine.tempo = tempo
        }
        if useMetronome && metronome.isRunning {
            metronome.tempo = tempo
        }
    }

    func setLoop(start: Int, end: Int) {
        loopRange = LoopRange(startMeasure: start, endMeasure: end)
        loopEnabled = true
        if playbackEngine.isPlaying {
            playbackEngine.setLoopRange(start: start, end: end)
        }
    }

    func clearLoop() {
        loopRange = nil
        loopEnabled = false
        playbackEngine.setLoopRange(start: nil, end: nil)
    }

    func setLoopToCurrentRegion(start: Int, end: Int) {
        setLoop(start: start, end: end)
    }

    func resetToOriginalTempo() {
        practiceTempo = originalTempo
        setPracticeTempo(originalTempo)
    }

    var tempoPercentage: Int {
        guard originalTempo > 0 else { return 100 }
        return Int(Double(practiceTempo) / Double(originalTempo) * 100)
    }

    var currentPracticeTime: TimeInterval {
        guard let start = practiceStartTime else { return totalPracticeSeconds }
        return totalPracticeSeconds + Date().timeIntervalSince(start)
    }

    private func updateTotalPracticeTime() {
        if let start = practiceStartTime {
            totalPracticeSeconds += Date().timeIntervalSince(start)
            practiceStartTime = nil
        }
    }

    var formattedPracticeTime: String {
        let time = currentPracticeTime
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func regenerateFretboardNotes() {
        let solver = StringFretSolver(config: config)
        var notes: [FretboardNote] = []
        var prevPosition: FretboardPosition? = nil
        let annotationsByNoteID = Dictionary(
            score.fretboardAnnotations.map { ($0.noteId, $0.position) },
            uniquingKeysWith: { _, latest in latest }
        )

        for measure in score.measures {
            for scoreNote in measure.notes where !scoreNote.isRest {
                let pitch = Pitch.from(midi: scoreNote.midiPitch)

                if let position = annotationsByNoteID[scoreNote.id] {
                    notes.append(FretboardNote(
                        position: position,
                        pitch: pitch,
                        sourceNoteID: scoreNote.id
                    ))
                    prevPosition = position
                } else if let position = solver.bestPositionForPitch(pitch, near: prevPosition) {
                    notes.append(FretboardNote(
                        position: position,
                        pitch: pitch,
                        sourceNoteID: scoreNote.id
                    ))
                    prevPosition = position
                }
            }
        }

        fretboardNotes = notes
    }

    func updateFretboardNotes(_ notes: [FretboardNote]) {
        fretboardNotes = notes
    }

    func setFretboardPosition(for sourceNoteID: UUID, position: FretboardPosition) {
        if let index = score.fretboardAnnotations.firstIndex(where: { $0.noteId == sourceNoteID }) {
            score.fretboardAnnotations[index].position = position
        } else {
            score.fretboardAnnotations.append(
                FretboardAnnotation(noteId: sourceNoteID, position: position)
            )
        }

        if let index = fretboardNotes.firstIndex(where: { $0.sourceNoteID == sourceNoteID }) {
            fretboardNotes[index].position = position
        }

        score.modifyTime = Date()
        onScoreChanged?(score)
    }

    var currentFretboardNotes: [FretboardNote] {
        let currentNoteIdx = playbackEngine.currentNoteIndex
        let currentMeasureIdx = playbackEngine.currentMeasureIndex
        let notesBySourceID = Dictionary(
            fretboardNotes.compactMap { note in
                note.sourceNoteID.map { ($0, note) }
            },
            uniquingKeysWith: { _, latest in latest }
        )

        var visibleNotes: [FretboardNote] = []

        for (mIdx, measure) in score.measures.enumerated() {
            for (nIdx, scoreNote) in measure.notes.enumerated() where !scoreNote.isRest {
                guard let fretboardNote = notesBySourceID[scoreNote.id] else { continue }
                let isCurrent = mIdx == currentMeasureIdx && nIdx == currentNoteIdx
                if isCurrent || (mIdx == currentMeasureIdx && nIdx >= currentNoteIdx && nIdx < currentNoteIdx + 4) {
                    visibleNotes.append(fretboardNote)
                }
            }
        }

        return visibleNotes.isEmpty ? fretboardNotes : visibleNotes
    }
}
