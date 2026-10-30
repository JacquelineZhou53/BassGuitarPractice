import Foundation

/// TabGenerator converts standard notation to tab (fretboard positions)
struct TabGenerator {
    let config: FretboardConfig
    private let solver: StringFretSolver
    
    init(config: FretboardConfig = .standard5StringBass) {
        self.config = config
        self.solver = StringFretSolver(config: config)
    }
    
    /// Convert a score's notes to fretboard positions
    func generateTab(for score: Score) -> Score {
        var tabScore = score
        var currentPosition: FretboardPosition? = nil
        
        for measureIndex in 0..<tabScore.measures.count {
            var measure = tabScore.measures[measureIndex]
            
            for noteIndex in 0..<measure.notes.count {
                var note = measure.notes[noteIndex]
                
                if !note.isRest {
                    let pitch = note.pitch
                    if let position = solver.bestPositionForPitch(pitch, near: currentPosition) {
                        note.fretboardPosition = position
                        currentPosition = position
                    }
                }
                
                measure.notes[noteIndex] = note
            }
            
            tabScore.measures[measureIndex] = measure
        }
        
        return tabScore
    }
    
    /// Convert a single note to fretboard position
    func positionForNote(_ note: ScoreNote, near previousPosition: FretboardPosition?) -> FretboardPosition? {
        guard !note.isRest else { return nil }
        let pitch = note.pitch
        return solver.bestPositionForPitch(pitch, near: previousPosition)
    }
}
