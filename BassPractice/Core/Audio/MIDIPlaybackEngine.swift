import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class MIDIPlaybackEngine {
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private var schedulingTimer: Timer?
    private var playbackStartTime: TimeInterval = 0
    private var scheduledEvents: [ScheduledEvent] = []
    private var currentEventIndex: Int = 0

    var isPlaying: Bool = false
    var currentTick: UInt32 = 0
    var currentMeasureIndex: Int = 0
    var currentNoteIndex: Int = 0
    var playbackProgress: Double = 0

    var tempo: Int = 120 {
        didSet { updatePlaybackRate() }
    }

    var playbackRate: Double = 1.0 {
        didSet { updatePlaybackRate() }
    }

    var volume: Float = 0.8 {
        didSet { sampler.masterGain = volume }
    }

    private(set) var score: Score?
    private var loopStartMeasure: Int?
    private var loopEndMeasure: Int?
    private var isLooping: Bool = false
    private var totalTicks: UInt32 = 0
    private var ticksPerQuarterNote: UInt32 = 480

    private struct ScheduledEvent {
        let tick: UInt32
        let measureIndex: Int
        let noteIndex: Int
        let midiNote: UInt8
        let velocity: UInt8
        let durationTicks: UInt32
        let isNoteOff: Bool
    }

    init() {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        sampler.masterGain = volume

        do {
            try engine.start()
        } catch {
            print("Audio engine start failed: \(error)")
        }
    }

    func load(score: Score) {
        self.score = score
        prepareEvents()
    }

    func setLoopRange(start: Int?, end: Int?) {
        loopStartMeasure = start
        loopEndMeasure = end
        isLooping = start != nil || end != nil
    }

    func play() {
        guard let score = score, !isPlaying else { return }

        isPlaying = true
        playbackStartTime = CACurrentMediaTime()
        currentEventIndex = 0
        currentTick = 0

        scheduleUpcomingEvents()

        schedulingTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func pause() {
        isPlaying = false
        schedulingTimer?.invalidate()
        schedulingTimer = nil
        sampler.sendController(123, withValue: 0, onChannel: 0)
    }

    func stop() {
        pause()
        currentTick = 0
        currentMeasureIndex = 0
        currentNoteIndex = 0
        playbackProgress = 0
    }

    func seekTo(measure: Int) {
        guard let score = score, measure >= 0, measure < score.measures.count else { return }

        var tick: UInt32 = 0
        for i in 0..<measure {
            for note in score.measures[i].notes {
                tick += UInt32(note.duration.ticks)
            }
        }

        currentTick = tick
        currentMeasureIndex = measure
        currentNoteIndex = 0
        playbackStartTime = CACurrentMediaTime() - tickToSeconds(tick: tick)

        sampler.sendController(123, withValue: 0, onChannel: 0)
        currentEventIndex = scheduledEvents.firstIndex { $0.tick >= currentTick } ?? 0
    }

    private func prepareEvents() {
        guard let score = score else { return }

        scheduledEvents = []
        var tick: UInt32 = 0

        for (measureIdx, measure) in score.measures.enumerated() {
            for (noteIdx, note) in measure.notes.enumerated() {
                if note.isRest {
                    tick += UInt32(note.duration.ticks)
                    continue
                }

                scheduledEvents.append(ScheduledEvent(
                    tick: tick,
                    measureIndex: measureIdx,
                    noteIndex: noteIdx,
                    midiNote: UInt8(note.midiPitch),
                    velocity: UInt8(note.velocity),
                    durationTicks: UInt32(note.duration.ticks),
                    isNoteOff: false
                ))

                scheduledEvents.append(ScheduledEvent(
                    tick: tick + UInt32(note.duration.ticks),
                    measureIndex: measureIdx,
                    noteIndex: noteIdx,
                    midiNote: UInt8(note.midiPitch),
                    velocity: 0,
                    durationTicks: 0,
                    isNoteOff: true
                ))

                tick += UInt32(note.duration.ticks)
            }
        }

        scheduledEvents.sort { $0.tick < $1.tick }
        totalTicks = tick
    }

    private func scheduleUpcomingEvents() {
        let lookaheadSeconds = 0.1
        let now = CACurrentMediaTime()

        while currentEventIndex < scheduledEvents.count {
            let event = scheduledEvents[currentEventIndex]
            let eventTime = playbackStartTime + tickToSeconds(tick: event.tick)
            let delay = eventTime - now

            if delay > lookaheadSeconds { break }

            let fireDelay = max(0, delay / playbackRate)

            DispatchQueue.main.asyncAfter(deadline: .now() + fireDelay) { [weak self] in
                guard let self = self else { return }
                if event.isNoteOff {
                    self.sampler.stopNote(event.midiNote, onChannel: 0)
                } else {
                    self.sampler.startNote(event.midiNote, withVelocity: event.velocity, onChannel: 0)
                }
            }

            currentEventIndex += 1
        }
    }

    @MainActor
    private func tick() {
        guard isPlaying, let score = score else { return }

        let elapsed = (CACurrentMediaTime() - playbackStartTime) * playbackRate
        currentTick = secondsToTick(seconds: elapsed)
        playbackProgress = totalTicks > 0 ? Double(currentTick) / Double(totalTicks) : 0

        updateCurrentPosition()
        scheduleUpcomingEvents()

        if currentEventIndex >= scheduledEvents.count {
            if isLooping, let loopStart = loopStartMeasure {
                seekTo(measure: loopStart)
                currentEventIndex = scheduledEvents.firstIndex { $0.measureIndex >= loopStart } ?? 0
            } else {
                stop()
            }
        }
    }

    private func updateCurrentPosition() {
        guard let score = score else { return }

        var tick: UInt32 = 0
        for (measureIdx, measure) in score.measures.enumerated() {
            for (noteIdx, note) in measure.notes.enumerated() {
                let noteEnd = tick + UInt32(note.duration.ticks)
                if currentTick >= tick && currentTick < noteEnd {
                    currentMeasureIndex = measureIdx
                    currentNoteIndex = noteIdx
                    return
                }
                tick = noteEnd
            }
        }
    }

    private func tickToSeconds(tick: UInt32) -> Double {
        let secondsPerBeat = 60.0 / Double(tempo)
        return Double(tick) / Double(ticksPerQuarterNote) * secondsPerBeat
    }

    private func secondsToTick(seconds: Double) -> UInt32 {
        let secondsPerBeat = 60.0 / Double(tempo)
        return UInt32(seconds / secondsPerBeat * Double(ticksPerQuarterNote))
    }

    private func updatePlaybackRate() {
        if isPlaying {
            let currentElapsed = CACurrentMediaTime() - playbackStartTime
            playbackStartTime = CACurrentMediaTime() - currentElapsed / playbackRate
        }
    }
}
