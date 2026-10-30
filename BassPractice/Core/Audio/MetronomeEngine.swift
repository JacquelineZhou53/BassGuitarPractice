import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class MetronomeEngine {
    private var audioEngine: AVAudioEngine?
    private var timer: Timer?
    private var beatStartTime: TimeInterval = 0

    var isRunning: Bool = false
    var currentBeat: Int = 0
    var currentBeatInMeasure: Int = 0

    var tempo: Int = 120 {
        didSet {
            if isRunning {
                stop()
                start()
            }
        }
    }

    var beatsPerMeasure: Int = 4 {
        didSet {
            if isRunning {
                stop()
                start()
            }
        }
    }

    var volume: Float = 0.5
    var accentFirstBeat: Bool = true
    var soundEnabled: Bool = true

    var onBeat: ((Int, Bool) -> Void)?

    private let accentFrequency: Float = 1000.0
    private let normalFrequency: Float = 800.0

    func start() {
        guard !isRunning else { return }
        isRunning = true
        currentBeat = 0
        currentBeatInMeasure = 0
        beatStartTime = CACurrentMediaTime()

        if soundEnabled {
            setupAudio()
        }

        let interval = 60.0 / Double(tempo)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickBeat()
            }
        }

        tickBeat()
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        audioEngine?.stop()
        audioEngine = nil
        currentBeat = 0
        currentBeatInMeasure = 0
    }

    private func tickBeat() {
        let isAccent = accentFirstBeat && currentBeatInMeasure == 0

        if soundEnabled {
            playClickSound(accent: isAccent)
        }

        onBeat?(currentBeatInMeasure, isAccent)
        currentBeat += 1
        currentBeatInMeasure = (currentBeatInMeasure + 1) % beatsPerMeasure
    }

    private func setupAudio() {
        let engine = AVAudioEngine()
        audioEngine = engine

        do {
            try engine.start()
        } catch {
            print("Metronome audio engine failed: \(error)")
        }
    }

    private func playClickSound(accent: Bool) {
        guard let engine = audioEngine else { return }

        let sampleRate: Double = 44100
        let duration: Double = 0.03
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount
        let freq = accent ? accentFrequency : normalFrequency
        let amplitude = accent ? Double(volume) : Double(volume) * 0.7

        if let data = buffer.floatChannelData {
            let channelData = data[0]
            for i in 0..<Int(frameCount) {
                let t = Double(i) / sampleRate
                let envelope = exp(-t * 80)
                channelData[i] = Float(sin(2.0 * .pi * Double(freq) * t) * amplitude * envelope)
            }
        }

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.scheduleBuffer(buffer, at: nil, options: .interrupts) { [weak engine, weak player] in
            player?.stop()
            engine?.detach(player!)
        }

        if !player.isPlaying {
            player.play()
        }
    }

    var secondsPerBeat: Double {
        60.0 / Double(tempo)
    }

    var elapsedBeats: Int {
        guard isRunning else { return 0 }
        let elapsed = CACurrentMediaTime() - beatStartTime
        return Int(elapsed / secondsPerBeat)
    }
}
