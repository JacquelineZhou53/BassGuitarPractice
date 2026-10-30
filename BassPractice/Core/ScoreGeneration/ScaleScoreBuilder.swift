import Foundation

/// 将音阶/琶音的多个指法转换为可播放和渲染的 Score 对象
struct ScaleScoreBuilder {
    let scale: Scale
    let root: Pitch
    let fingerings: [FingeringPattern]
    let instrumentType: InstrumentType
    let tempo: Int
    let notesPerMeasure: Int
    
    private var config: FretboardConfig { instrumentType.defaultFretboardConfig }
    
    init(
        scale: Scale,
        root: Pitch,
        fingerings: [FingeringPattern],
        instrumentType: InstrumentType,
        tempo: Int = 80,
        notesPerMeasure: Int = 4
    ) {
        self.scale = scale
        self.root = root
        self.fingerings = fingerings
        self.instrumentType = instrumentType
        self.tempo = tempo
        self.notesPerMeasure = notesPerMeasure
    }
    
    /// 构建包含所有指法的 Score
    func buildScore() -> Score {
        var measures: [ScoreMeasure] = []
        var measureNumber = 1
        
        // 为每个指法生成音符并分组到小节
        for fingering in fingerings {
            let fingeringMeasures = buildMeasuresForFingering(
                fingering: fingering,
                startingMeasureNumber: measureNumber
            )
            measures.append(contentsOf: fingeringMeasures)
            measureNumber += fingeringMeasures.count
        }
        
        return Score(
            title: "\(root.noteName.displayName) \(scale.name) - 音阶练习",
            timeSignature: TimeSignatureData(numerator: 4, denominator: 4),
            keySignature: keySignatureForRoot(root, scale: scale),
            tempo: tempo,
            sourceType: .scalePractice,
            instrumentType: instrumentType,
            measures: measures
        )
    }
    
    /// 为单个指法生成小节
    private func buildMeasuresForFingering(
        fingering: FingeringPattern,
        startingMeasureNumber: Int
    ) -> [ScoreMeasure] {
        // 生成原音阶音符
        let baseNotes = fingering.positions.map { pos -> ScoreNote in
            let pitch = pos.pitch(on: config)
            return ScoreNote(
                midiPitch: pitch.midiNumber,
                duration: .quarter,
                velocity: 80,
                fretboardPosition: pos
            )
        }
        
        // 生成高八度音符
        let highOctavePitches = scale.pitches(root: root).map { pitch in
            Pitch.from(midi: pitch.midiNumber + 12)
        }
        let highOctaveFingerings = FingeringGenerator(config: config).generate(pitches: highOctavePitches)
        let highPositions = highOctaveFingerings.first?.positions ?? []
        let highNotes = highPositions.map { pos -> ScoreNote in
            let pitch = pos.pitch(on: config)
            return ScoreNote(
                midiPitch: pitch.midiNumber,
                duration: .quarter,
                velocity: 80,
                fretboardPosition: pos
            )
        }
        
        let allNotes = baseNotes + highNotes
        
        // 将音符分组到小节
        return packNotesIntoMeasures(
            notes: allNotes,
            startingMeasureNumber: startingMeasureNumber
        )
    }
    
    /// 将音符数组打包成小节
    private func packNotesIntoMeasures(
        notes: [ScoreNote],
        startingMeasureNumber: Int
    ) -> [ScoreMeasure] {
        var measures: [ScoreMeasure] = []
        var measureNumber = startingMeasureNumber
        
        for chunkStart in stride(from: 0, to: notes.count, by: notesPerMeasure) {
            let chunkEnd = min(chunkStart + notesPerMeasure, notes.count)
            var chunk = Array(notes[chunkStart..<chunkEnd])
            
            // 如果最后一个小节不满,用休止符填充
            if chunk.count < notesPerMeasure {
                let restCount = notesPerMeasure - chunk.count
                for _ in 0..<restCount {
                    chunk.append(.rest(duration: .quarter))
                }
            }
            
            measures.append(ScoreMeasure(
                measureNumber: measureNumber,
                notes: chunk
            ))
            measureNumber += 1
        }
        
        return measures
    }
    
    /// 根据根音和音阶确定调号
    private func keySignatureForRoot(_ root: Pitch, scale: Scale) -> KeySignatureData {
        let rootFifths: [NoteName: Int] = [
            .C: 0, .G: 1, .D: 2, .A: 3, .E: 4, .B: 5,
            .Fs: 6, .Cs: 7, .F: -1, .As: -2, .Ds: -3, .Gs: -4
        ]
        let fifths = rootFifths[root.noteName] ?? 0
        let mode = scale.category == .minor ? "minor" : "major"
        return KeySignatureData(fifths: fifths, mode: mode)
    }
    
    /// 获取指定指法在 Score 中的起始小节索引
    func measureIndexForFingering(fingeringIndex: Int) -> Int {
        var measureOffset = 0
        
        for i in 0..<fingeringIndex {
            let fingering = fingerings[i]
            let noteCount = fingering.positions.count + highOctaveNoteCount
            let measureCount = (noteCount + notesPerMeasure - 1) / notesPerMeasure
            measureOffset += measureCount
        }
        
        return measureOffset
    }
    
    /// 高八度音符数量(用于计算小节偏移)
    private var highOctaveNoteCount: Int {
        let highOctavePitches = scale.pitches(root: root).map { pitch in
            Pitch.from(midi: pitch.midiNumber + 12)
        }
        let highOctaveFingerings = FingeringGenerator(config: config).generate(pitches: highOctavePitches)
        return highOctaveFingerings.first?.positions.count ?? 0
    }
}
