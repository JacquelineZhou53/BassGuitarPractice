import Foundation

struct GuitarChord: Identifiable, Hashable {
    let id: String
    let name: String
    let category: ChordCategory
    let fingering: [StringFingering] // 6 strings (low E to high E), nil = muted
    let baseFret: Int // 1 for open chords, higher for barre chords
    let intervals: [Int]? // Semitones from root (e.g., [0, 4, 7] for major triad). If nil, will be computed dynamically.
    
    init(id: String, name: String, category: ChordCategory, fingering: [StringFingering], baseFret: Int, intervals: [Int]? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.fingering = fingering
        self.baseFret = baseFret
        self.intervals = intervals ?? GuitarChord.getIntervals(for: name, category: category)
    }
    
    struct StringFingering: Hashable {
        let fret: Int? // nil = muted (X), 0 = open (O), >0 = fret number
        let finger: Int? // 1=index, 2=middle, 3=ring, 4=pinky, nil for open/muted
    }
    
    enum ChordCategory: String, CaseIterable, Identifiable {
        case major = "大调和弦"
        case minor = "小调和弦"
        case seventh = "七和弦"
        case sus = "挂留和弦"
        case barre = "封闭和弦"
        case diminished = "减和弦"
        case augmented = "增和弦"
        case ninth = "九和弦"
        case sixth = "六和弦"
        case eleventh = "十一和弦"
        case thirteenth = "十三和弦"
        case add = "添加音和弦"
        case minorSixth = "小调六和弦"
        case minorMajorSeventh = "小大七和弦"
        
        var id: String { rawValue }
    }
    
    // 根据和弦名称提取根音（例如 "C" from "Cmaj7", "F#" from "F#m"）
    var rootNote: String? {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        for note in noteNames {
            if name.hasPrefix(note) {
                return note
            }
        }
        return nil
    }
    
    // 获取移调后的根音
    func transposedRootNote(by semitones: Int) -> String? {
        guard let root = rootNote else { return nil }
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        guard let rootIndex = noteNames.firstIndex(of: root) else { return nil }
        
        let newIndex = (rootIndex + semitones + 12) % 12
        return noteNames[newIndex]
    }
    
    // 获取和弦内音（考虑移调）
    func chordNotes(transposition: Int = 0) -> [String] {
        guard let root = transposedRootNote(by: transposition) else { return [] }
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        guard let rootIndex = noteNames.firstIndex(of: root) else { return [] }
        
        // Use stored intervals if available, otherwise compute dynamically
        let chordIntervals = intervals ?? GuitarChord.getIntervals(for: name, category: category)
        
        return chordIntervals.map { interval in
            let noteIndex = (rootIndex + interval) % 12
            return noteNames[noteIndex]
        }
    }
    
    // 音程名称映射
    var intervalNames: [String] {
        let chordIntervals = intervals ?? GuitarChord.getIntervals(for: name, category: category)
        let intervalMap: [Int: String] = [
            0: "根音",
            1: "小二度",
            2: "大二度",
            3: "小三度",
            4: "大三度",
            5: "纯四度",
            6: "增四度/减五度",
            7: "纯五度",
            8: "小六度",
            9: "大六度",
            10: "小七度",
            11: "大七度",
            12: "八度"
        ]
        return chordIntervals.map { intervalMap[$0] ?? "\($0)度" }
    }
}

// 和弦类型到音程的映射
extension GuitarChord {
    static func getIntervals(for chordName: String, category: ChordCategory) -> [Int] {
        // 从和弦名称提取基础类型（去掉根音和变音记号）
        let baseType = chordName.replacingOccurrences(of: "^[A-G]#?", with: "", options: .regularExpression)
        
        switch category {
        case .major:
            return [0, 4, 7] // 根音, 大三度, 纯五度
        case .minor:
            return [0, 3, 7] // 根音, 小三度, 纯五度
        case .seventh:
            if baseType.contains("maj7") || baseType.contains("M7") {
                return [0, 4, 7, 11] // 大七和弦
            } else if baseType.contains("m7") {
                return [0, 3, 7, 10] // 小七和弦
            } else {
                return [0, 4, 7, 10] // 属七和弦
            }
        case .sus:
            if baseType.contains("sus2") {
                return [0, 2, 7] // 挂二
            } else {
                return [0, 5, 7] // 挂四
            }
        case .barre:
            // 封闭和弦根据名称判断类型
            if baseType.contains("m") && !baseType.contains("maj") {
                return [0, 3, 7] // 小和弦
            } else {
                return [0, 4, 7] // 大和弦
            }
        case .diminished:
            if baseType.contains("dim7") {
                return [0, 3, 6, 9] // 减七
            } else {
                return [0, 3, 6] // 减三
            }
        case .augmented:
            if baseType.contains("aug7") || baseType.contains("7#5") {
                return [0, 4, 8, 10] // 增七
            } else {
                return [0, 4, 8] // 增三
            }
        case .ninth:
            if baseType.contains("maj9") {
                return [0, 4, 7, 11, 14] // 大九
            } else if baseType.contains("m9") {
                return [0, 3, 7, 10, 14] // 小九
            } else {
                return [0, 4, 7, 10, 14] // 属九
            }
        case .sixth:
            if baseType.contains("m6") {
                return [0, 3, 7, 9] // 小六
            } else {
                return [0, 4, 7, 9] // 大六
            }
        case .eleventh:
            return [0, 4, 7, 10, 14, 17] // 十一和弦
        case .thirteenth:
            return [0, 4, 7, 10, 14, 17, 21] // 十三和弦
        case .add:
            if baseType.contains("add9") {
                return [0, 4, 7, 14] // 添加九音
            } else {
                return [0, 4, 7] // 默认大三和弦
            }
        case .minorSixth:
            return [0, 3, 7, 9] // 小六和弦
        case .minorMajorSeventh:
            return [0, 3, 7, 11] // 小大七和弦
        }
    }
}

extension GuitarChord {
    static let allChords: [GuitarChord] = [
        // 大调和弦
        GuitarChord(id: "C", name: "C", category: .major, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 1, finger: 1),       // 2B fret 1, index finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "G", name: "G", category: .major, fingering: [
            .init(fret: 3, finger: 2),       // 6E fret 3, middle finger
            .init(fret: 2, finger: 1),       // 5A fret 2, index finger
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 3, finger: 3)        // 1E fret 3, ring finger
        ], baseFret: 1),
        GuitarChord(id: "D", name: "D", category: .major, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: nil, finger: nil),   // 5A muted
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 2, finger: 1),       // 3G fret 2, index finger
            .init(fret: 3, finger: 3),       // 2B fret 3, ring finger
            .init(fret: 2, finger: 2)        // 1E fret 2, middle finger
        ], baseFret: 1),
        GuitarChord(id: "E", name: "E", category: .major, fingering: [
            .init(fret: 0, finger: nil),     // 6E open
            .init(fret: 2, finger: 2),       // 5A fret 2, middle finger
            .init(fret: 2, finger: 3),       // 4D fret 2, ring finger
            .init(fret: 1, finger: 1),       // 3G fret 1, index finger
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "A", name: "A", category: .major, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 0, finger: nil),     // 5A open
            .init(fret: 2, finger: 1),       // 4D fret 2, index finger
            .init(fret: 2, finger: 2),       // 3G fret 2, middle finger
            .init(fret: 2, finger: 3),       // 2B fret 2, ring finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        
        // 小调和弦
        GuitarChord(id: "Am", name: "Am", category: .minor, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 0, finger: nil),     // 5A open
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 2, finger: 3),       // 3G fret 2, ring finger
            .init(fret: 1, finger: 1),       // 2B fret 1, index finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "Em", name: "Em", category: .minor, fingering: [
            .init(fret: 0, finger: nil),     // 6E open
            .init(fret: 2, finger: 2),       // 5A fret 2, middle finger
            .init(fret: 2, finger: 3),       // 4D fret 2, ring finger
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "Dm", name: "Dm", category: .minor, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: nil, finger: nil),   // 5A muted
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 2, finger: 2),       // 3G fret 2, middle finger
            .init(fret: 3, finger: 3),       // 2B fret 3, ring finger
            .init(fret: 1, finger: 1)        // 1E fret 1, index finger
        ], baseFret: 1),
        
        // 七和弦
        GuitarChord(id: "G7", name: "G7", category: .seventh, fingering: [
            .init(fret: 3, finger: 3),       // 6E fret 3, ring finger
            .init(fret: 2, finger: 1),       // 5A fret 2, index finger
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 1, finger: 2)        // 1E fret 1, middle finger
        ], baseFret: 1),
        GuitarChord(id: "C7", name: "C7", category: .seventh, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 3, finger: 4),       // 3G fret 3, pinky
            .init(fret: 1, finger: 1),       // 2B fret 1, index finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "D7", name: "D7", category: .seventh, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: nil, finger: nil),   // 5A muted
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 2, finger: 1),       // 3G fret 2, index finger
            .init(fret: 1, finger: 2),       // 2B fret 1, middle finger
            .init(fret: 2, finger: 3)        // 1E fret 2, ring finger
        ], baseFret: 1),
        GuitarChord(id: "E7", name: "E7", category: .seventh, fingering: [
            .init(fret: 0, finger: nil),     // 6E open
            .init(fret: 2, finger: 2),       // 5A fret 2, middle finger
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 1, finger: 1),       // 3G fret 1, index finger
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "A7", name: "A7", category: .seventh, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 0, finger: nil),     // 5A open
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 2, finger: 3),       // 2B fret 2, ring finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        
        // 挂留和弦
        GuitarChord(id: "Csus4", name: "Csus4", category: .sus, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 3, finger: 4),       // 4D fret 3, pinky
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 1, finger: 1),       // 2B fret 1, index finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "Dsus4", name: "Dsus4", category: .sus, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: nil, finger: nil),   // 5A muted
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 3, finger: 3),       // 3G fret 3, ring finger
            .init(fret: 3, finger: 4),       // 2B fret 3, pinky
            .init(fret: 3, finger: 2)        // 1E fret 3, middle finger
        ], baseFret: 1),
        GuitarChord(id: "Gsus4", name: "Gsus4", category: .sus, fingering: [
            .init(fret: 3, finger: 3),       // 6E fret 3, ring finger
            .init(fret: 3, finger: 4),       // 5A fret 3, pinky
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 1, finger: 1),       // 2B fret 1, index finger
            .init(fret: 3, finger: 2)        // 1E fret 3, middle finger
        ], baseFret: 1),
        GuitarChord(id: "Asus4", name: "Asus4", category: .sus, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 0, finger: nil),     // 5A open
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 2, finger: 3),       // 3G fret 2, ring finger
            .init(fret: 3, finger: 4),       // 2B fret 3, pinky
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        
        // 封闭和弦（大横按）
        GuitarChord(id: "F", name: "F", category: .barre, fingering: [
            .init(fret: 1, finger: 1),       // 6E fret 1, barre (index)
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 3, finger: 4),       // 4D fret 3, pinky
            .init(fret: 2, finger: 2),       // 3G fret 2, middle finger
            .init(fret: 1, finger: 1),       // 2B fret 1, barre (index)
            .init(fret: 1, finger: 1)        // 1E fret 1, barre (index)
        ], baseFret: 1),
        GuitarChord(id: "Fm", name: "Fm", category: .barre, fingering: [
            .init(fret: 1, finger: 1),       // 6E fret 1, barre (index)
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 3, finger: 4),       // 4D fret 3, pinky
            .init(fret: 1, finger: 1),       // 3G fret 1, barre (index)
            .init(fret: 1, finger: 1),       // 2B fret 1, barre (index)
            .init(fret: 1, finger: 1)        // 1E fret 1, barre (index)
        ], baseFret: 1),
        GuitarChord(id: "Bm", name: "Bm", category: .barre, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 2, finger: 1),       // 5A fret 2, barre (index)
            .init(fret: 4, finger: 3),       // 4D fret 4, ring finger
            .init(fret: 4, finger: 4),       // 3G fret 4, pinky
            .init(fret: 3, finger: 2),       // 2B fret 3, middle finger
            .init(fret: 2, finger: 1)        // 1E fret 2, barre (index)
        ], baseFret: 1),
        GuitarChord(id: "Cm", name: "Cm", category: .barre, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 1),       // 5A fret 3, barre (index)
            .init(fret: 5, finger: 3),       // 4D fret 5, ring finger
            .init(fret: 5, finger: 4),       // 3G fret 5, pinky
            .init(fret: 4, finger: 2),       // 2B fret 4, middle finger
            .init(fret: 3, finger: 1)        // 1E fret 3, barre (index)
        ], baseFret: 3),
        GuitarChord(id: "Gm", name: "Gm", category: .barre, fingering: [
            .init(fret: 3, finger: 1),       // 6E fret 3, barre (index)
            .init(fret: 5, finger: 3),       // 5A fret 5, ring finger
            .init(fret: 5, finger: 4),       // 4D fret 5, pinky
            .init(fret: 3, finger: 1),       // 3G fret 3, barre (index)
            .init(fret: 3, finger: 1),       // 2B fret 3, barre (index)
            .init(fret: 3, finger: 1)        // 1E fret 3, barre (index)
        ], baseFret: 3),
        GuitarChord(id: "B", name: "B", category: .barre, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 2, finger: 1),       // 5A fret 2, barre (index)
            .init(fret: 4, finger: 3),       // 4D fret 4, ring finger
            .init(fret: 4, finger: 4),       // 3G fret 4, pinky
            .init(fret: 3, finger: 2),       // 2B fret 3, middle finger
            .init(fret: 2, finger: 1)        // 1E fret 2, barre (index)
        ], baseFret: 2),
        
        // 更多七和弦
        GuitarChord(id: "B7", name: "B7", category: .seventh, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 2, finger: 1),       // 5A fret 2, index finger
            .init(fret: 1, finger: 2),       // 4D fret 1, middle finger
            .init(fret: 2, finger: 3),       // 3G fret 2, ring finger
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 2, finger: 4)        // 1E fret 2, pinky
        ], baseFret: 1),
        GuitarChord(id: "Fmaj7", name: "Fmaj7", category: .seventh, fingering: [
            .init(fret: 1, finger: 1),       // 6E fret 1, barre (index)
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 2, finger: 2),       // 3G fret 2, middle finger
            .init(fret: 1, finger: 1),       // 2B fret 1, barre (index)
            .init(fret: 1, finger: 1)        // 1E fret 1, barre (index)
        ], baseFret: 1),
        GuitarChord(id: "F7", name: "F7", category: .seventh, fingering: [
            .init(fret: 1, finger: 1),       // 6E fret 1, barre (index)
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 1, finger: 1),       // 4D fret 1, barre (index)
            .init(fret: 2, finger: 2),       // 3G fret 2, middle finger
            .init(fret: 1, finger: 1),       // 2B fret 1, barre (index)
            .init(fret: 1, finger: 1)        // 1E fret 1, barre (index)
        ], baseFret: 1),
        GuitarChord(id: "Cmaj7", name: "Cmaj7", category: .seventh, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "Em7", name: "Em7", category: .seventh, fingering: [
            .init(fret: 0, finger: nil),     // 6E open
            .init(fret: 2, finger: 2),       // 5A fret 2, middle finger
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "Am7", name: "Am7", category: .seventh, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 0, finger: nil),     // 5A open
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 1, finger: 1),       // 2B fret 1, index finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "Dm7", name: "Dm7", category: .seventh, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: nil, finger: nil),   // 5A muted
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 2, finger: 2),       // 3G fret 2, middle finger
            .init(fret: 1, finger: 1),       // 2B fret 1, index finger
            .init(fret: 1, finger: 1)        // 1E fret 1, index finger
        ], baseFret: 1),
        
        // 减和弦
        GuitarChord(id: "Bdim", name: "Bdim", category: .diminished, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 2, finger: 1),       // 5A fret 2, index finger
            .init(fret: 3, finger: 2),       // 4D fret 3, middle finger
            .init(fret: 4, finger: 3),       // 3G fret 4, ring finger
            .init(fret: 2, finger: 1),       // 2B fret 2, index finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "Cdim", name: "Cdim", category: .diminished, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 4, finger: 4),       // 4D fret 4, pinky
            .init(fret: 2, finger: 1),       // 3G fret 2, index finger
            .init(fret: 3, finger: 2),       // 2B fret 3, middle finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        
        // 增和弦
        GuitarChord(id: "Caug", name: "Caug", category: .augmented, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 1, finger: 1),       // 3G fret 1, index finger
            .init(fret: 1, finger: 1),       // 2B fret 1, index finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "Eaug", name: "Eaug", category: .augmented, fingering: [
            .init(fret: 0, finger: nil),     // 6E open
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 1, finger: 1),       // 3G fret 1, index finger
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        
        // 更多封闭和弦
        GuitarChord(id: "F#m", name: "F#m", category: .barre, fingering: [
            .init(fret: 2, finger: 1),       // 6E fret 2, barre (index)
            .init(fret: 4, finger: 3),       // 5A fret 4, ring finger
            .init(fret: 4, finger: 4),       // 4D fret 4, pinky
            .init(fret: 2, finger: 1),       // 3G fret 2, barre (index)
            .init(fret: 2, finger: 1),       // 2B fret 2, barre (index)
            .init(fret: 2, finger: 1)        // 1E fret 2, barre (index)
        ], baseFret: 2),
        GuitarChord(id: "G#m", name: "G#m", category: .barre, fingering: [
            .init(fret: 4, finger: 1),       // 6E fret 4, barre (index)
            .init(fret: 6, finger: 3),       // 5A fret 6, ring finger
            .init(fret: 6, finger: 4),       // 4D fret 6, pinky
            .init(fret: 4, finger: 1),       // 3G fret 4, barre (index)
            .init(fret: 4, finger: 1),       // 2B fret 4, barre (index)
            .init(fret: 4, finger: 1)        // 1E fret 4, barre (index)
        ], baseFret: 4),
        GuitarChord(id: "Ab", name: "Ab", category: .barre, fingering: [
            .init(fret: 4, finger: 1),       // 6E fret 4, barre (index)
            .init(fret: 6, finger: 3),       // 5A fret 6, ring finger
            .init(fret: 6, finger: 4),       // 4D fret 6, pinky
            .init(fret: 5, finger: 2),       // 3G fret 5, middle finger
            .init(fret: 4, finger: 1),       // 2B fret 4, barre (index)
            .init(fret: 4, finger: 1)        // 1E fret 4, barre (index)
        ], baseFret: 4),
        GuitarChord(id: "Db", name: "Db", category: .barre, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 4, finger: 1),       // 5A fret 4, barre (index)
            .init(fret: 6, finger: 3),       // 4D fret 6, ring finger
            .init(fret: 6, finger: 4),       // 3G fret 6, pinky
            .init(fret: 5, finger: 2),       // 2B fret 5, middle finger
            .init(fret: 4, finger: 1)        // 1E fret 4, barre (index)
        ], baseFret: 4),
        GuitarChord(id: "Eb", name: "Eb", category: .barre, fingering: [
            .init(fret: 6, finger: 1),       // 6E fret 6, barre (index)
            .init(fret: 8, finger: 3),       // 5A fret 8, ring finger
            .init(fret: 8, finger: 4),       // 4D fret 8, pinky
            .init(fret: 6, finger: 1),       // 3G fret 6, barre (index)
            .init(fret: 6, finger: 1),       // 2B fret 6, barre (index)
            .init(fret: 6, finger: 1)        // 1E fret 6, barre (index)
        ], baseFret: 6),
        
        // 九和弦
        GuitarChord(id: "C9", name: "C9", category: .ninth, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 3, finger: 4),       // 3G fret 3, pinky
            .init(fret: 3, finger: 3),       // 2B fret 3, ring finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "G9", name: "G9", category: .ninth, fingering: [
            .init(fret: 3, finger: 3),       // 6E fret 3, ring finger
            .init(fret: 2, finger: 1),       // 5A fret 2, index finger
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 1, finger: 2),       // 2B fret 1, middle finger
            .init(fret: 3, finger: 4)        // 1E fret 3, pinky
        ], baseFret: 1),
        GuitarChord(id: "D9", name: "D9", category: .ninth, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: nil, finger: nil),   // 5A muted
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 2, finger: 1),       // 3G fret 2, index finger
            .init(fret: 1, finger: 2),       // 2B fret 1, middle finger
            .init(fret: 2, finger: 3)        // 1E fret 2, ring finger
        ], baseFret: 1),
        GuitarChord(id: "A9", name: "A9", category: .ninth, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 0, finger: nil),     // 5A open
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 2, finger: 3),       // 3G fret 2, ring finger
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "E9", name: "E9", category: .ninth, fingering: [
            .init(fret: 0, finger: nil),     // 6E open
            .init(fret: 2, finger: 2),       // 5A fret 2, middle finger
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 1, finger: 1),       // 3G fret 1, index finger
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        
        // 更多大调和弦（不同把位）
        GuitarChord(id: "C_8", name: "C (8把位)", category: .major, fingering: [
            .init(fret: 8, finger: 1),       // 6E fret 8, barre (index)
            .init(fret: 10, finger: 3),      // 5A fret 10, ring finger
            .init(fret: 10, finger: 4),      // 4D fret 10, pinky
            .init(fret: 9, finger: 2),       // 3G fret 9, middle finger
            .init(fret: 8, finger: 1),       // 2B fret 8, barre (index)
            .init(fret: 8, finger: 1)        // 1E fret 8, barre (index)
        ], baseFret: 8),
        GuitarChord(id: "G_10", name: "G (10把位)", category: .major, fingering: [
            .init(fret: 10, finger: 1),      // 6E fret 10, barre (index)
            .init(fret: 12, finger: 3),      // 5A fret 12, ring finger
            .init(fret: 12, finger: 4),      // 4D fret 12, pinky
            .init(fret: 10, finger: 1),      // 3G fret 10, barre (index)
            .init(fret: 10, finger: 1),      // 2B fret 10, barre (index)
            .init(fret: 10, finger: 1)       // 1E fret 10, barre (index)
        ], baseFret: 10),
        
        // 更多小调和弦（不同把位）
        GuitarChord(id: "Am_5", name: "Am (5把位)", category: .minor, fingering: [
            .init(fret: 5, finger: 1),       // 6E fret 5, barre (index)
            .init(fret: 7, finger: 3),       // 5A fret 7, ring finger
            .init(fret: 7, finger: 4),       // 4D fret 7, pinky
            .init(fret: 5, finger: 1),       // 3G fret 5, barre (index)
            .init(fret: 5, finger: 1),       // 2B fret 5, barre (index)
            .init(fret: 5, finger: 1)        // 1E fret 5, barre (index)
        ], baseFret: 5),
        GuitarChord(id: "Em_7", name: "Em (7把位)", category: .minor, fingering: [
            .init(fret: 7, finger: 1),       // 6E fret 7, barre (index)
            .init(fret: 9, finger: 3),       // 5A fret 9, ring finger
            .init(fret: 9, finger: 4),       // 4D fret 9, pinky
            .init(fret: 7, finger: 1),       // 3G fret 7, barre (index)
            .init(fret: 7, finger: 1),       // 2B fret 7, barre (index)
            .init(fret: 7, finger: 1)        // 1E fret 7, barre (index)
        ], baseFret: 7),
        
        // 更多七和弦变体
        GuitarChord(id: "Gmaj7", name: "Gmaj7", category: .seventh, fingering: [
            .init(fret: 3, finger: 3),       // 6E fret 3, ring finger
            .init(fret: 2, finger: 1),       // 5A fret 2, index finger
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 2, finger: 2)        // 1E fret 2, middle finger
        ], baseFret: 1),
        GuitarChord(id: "Dmaj7", name: "Dmaj7", category: .seventh, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: nil, finger: nil),   // 5A muted
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 2, finger: 2),       // 3G fret 2, middle finger
            .init(fret: 2, finger: 3),       // 2B fret 2, ring finger
            .init(fret: 2, finger: 4)        // 1E fret 2, pinky
        ], baseFret: 1),
        GuitarChord(id: "Amaj7", name: "Amaj7", category: .seventh, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 0, finger: nil),     // 5A open
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 1, finger: 1),       // 3G fret 1, index finger
            .init(fret: 2, finger: 3),       // 2B fret 2, ring finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "Emaj7", name: "Emaj7", category: .seventh, fingering: [
            .init(fret: 0, finger: nil),     // 6E open
            .init(fret: 2, finger: 2),       // 5A fret 2, middle finger
            .init(fret: 1, finger: 1),       // 4D fret 1, index finger
            .init(fret: 1, finger: 1),       // 3G fret 1, index finger
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        
        // 六和弦
        GuitarChord(id: "C6", name: "C6", category: .sixth, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "G6", name: "G6", category: .sixth, fingering: [
            .init(fret: 3, finger: 3),       // 6E fret 3, ring finger
            .init(fret: 2, finger: 1),       // 5A fret 2, index finger
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "D6", name: "D6", category: .sixth, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: nil, finger: nil),   // 5A muted
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 2, finger: 1),       // 3G fret 2, index finger
            .init(fret: 2, finger: 2),       // 2B fret 2, middle finger
            .init(fret: 2, finger: 3)        // 1E fret 2, ring finger
        ], baseFret: 1),
        GuitarChord(id: "A6", name: "A6", category: .sixth, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 0, finger: nil),     // 5A open
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 2, finger: 3),       // 3G fret 2, ring finger
            .init(fret: 2, finger: 4),       // 2B fret 2, pinky
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "E6", name: "E6", category: .sixth, fingering: [
            .init(fret: 0, finger: nil),     // 6E open
            .init(fret: 2, finger: 2),       // 5A fret 2, middle finger
            .init(fret: 2, finger: 3),       // 4D fret 2, ring finger
            .init(fret: 1, finger: 1),       // 3G fret 1, index finger
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        
        // 小调六和弦
        GuitarChord(id: "Cm6", name: "Cm6", category: .minorSixth, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 5, finger: 4),       // 4D fret 5, pinky
            .init(fret: 3, finger: 2),       // 3G fret 3, middle finger
            .init(fret: 4, finger: 3),       // 2B fret 4, ring finger
            .init(fret: 3, finger: 1)        // 1E fret 3, index finger
        ], baseFret: 3),
        GuitarChord(id: "Am6", name: "Am6", category: .minorSixth, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 0, finger: nil),     // 5A open
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 2, finger: 3),       // 3G fret 2, ring finger
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "Em6", name: "Em6", category: .minorSixth, fingering: [
            .init(fret: 0, finger: nil),     // 6E open
            .init(fret: 2, finger: 2),       // 5A fret 2, middle finger
            .init(fret: 2, finger: 3),       // 4D fret 2, ring finger
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        
        // 添加音和弦
        GuitarChord(id: "Cadd9", name: "Cadd9", category: .add, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 3, finger: 4),       // 2B fret 3, pinky
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "Dadd9", name: "Dadd9", category: .add, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: nil, finger: nil),   // 5A muted
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 2, finger: 1),       // 3G fret 2, index finger
            .init(fret: 3, finger: 3),       // 2B fret 3, ring finger
            .init(fret: 2, finger: 2)        // 1E fret 2, middle finger
        ], baseFret: 1),
        GuitarChord(id: "Gadd9", name: "Gadd9", category: .add, fingering: [
            .init(fret: 3, finger: 3),       // 6E fret 3, ring finger
            .init(fret: 2, finger: 1),       // 5A fret 2, index finger
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 3, finger: 4),       // 2B fret 3, pinky
            .init(fret: 3, finger: 2)        // 1E fret 3, middle finger
        ], baseFret: 1),
        GuitarChord(id: "Eadd9", name: "Eadd9", category: .add, fingering: [
            .init(fret: 0, finger: nil),     // 6E open
            .init(fret: 2, finger: 2),       // 5A fret 2, middle finger
            .init(fret: 2, finger: 3),       // 4D fret 2, ring finger
            .init(fret: 1, finger: 1),       // 3G fret 1, index finger
            .init(fret: 2, finger: 2),       // 2B fret 2, middle finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "Aadd9", name: "Aadd9", category: .add, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 0, finger: nil),     // 5A open
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 2, finger: 3),       // 3G fret 2, ring finger
            .init(fret: 2, finger: 4),       // 2B fret 2, pinky
            .init(fret: 2, finger: 1)        // 1E fret 2, index finger
        ], baseFret: 1),
        
        // 挂二和弦
        GuitarChord(id: "Csus2", name: "Csus2", category: .sus, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 3, finger: 4),       // 4D fret 3, pinky
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 1, finger: 1),       // 2B fret 1, index finger
            .init(fret: 1, finger: 1)        // 1E fret 1, index finger
        ], baseFret: 1),
        GuitarChord(id: "Dsus2", name: "Dsus2", category: .sus, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: nil, finger: nil),   // 5A muted
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 2, finger: 2),       // 3G fret 2, middle finger
            .init(fret: 3, finger: 3),       // 2B fret 3, ring finger
            .init(fret: 2, finger: 1)        // 1E fret 2, index finger
        ], baseFret: 1),
        GuitarChord(id: "Gsus2", name: "Gsus2", category: .sus, fingering: [
            .init(fret: 3, finger: 3),       // 6E fret 3, ring finger
            .init(fret: 0, finger: nil),     // 5A open
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 3, finger: 4),       // 2B fret 3, pinky
            .init(fret: 3, finger: 2)        // 1E fret 3, middle finger
        ], baseFret: 1),
        GuitarChord(id: "Asus2", name: "Asus2", category: .sus, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 0, finger: nil),     // 5A open
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 2, finger: 3),       // 3G fret 2, ring finger
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        
        // 减七和弦
        GuitarChord(id: "Bdim7", name: "Bdim7", category: .diminished, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 2, finger: 1),       // 5A fret 2, index finger
            .init(fret: 3, finger: 2),       // 4D fret 3, middle finger
            .init(fret: 4, finger: 3),       // 3G fret 4, ring finger
            .init(fret: 1, finger: 1),       // 2B fret 1, index finger
            .init(fret: 2, finger: 2)        // 1E fret 2, middle finger
        ], baseFret: 1),
        GuitarChord(id: "Cdim7", name: "Cdim7", category: .diminished, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 4, finger: 4),       // 4D fret 4, pinky
            .init(fret: 2, finger: 1),       // 3G fret 2, index finger
            .init(fret: 2, finger: 2),       // 2B fret 2, middle finger
            .init(fret: 3, finger: 3)        // 1E fret 3, ring finger
        ], baseFret: 1),
        
        // 增七和弦
        GuitarChord(id: "Caug7", name: "Caug7", category: .augmented, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 3, finger: 4),       // 3G fret 3, pinky
            .init(fret: 2, finger: 1),       // 2B fret 2, index finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "Eaug7", name: "Eaug7", category: .augmented, fingering: [
            .init(fret: 0, finger: nil),     // 6E open
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 3, finger: 4),       // 3G fret 3, pinky
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        
        // 小大七和弦（minor-major 7th）
        GuitarChord(id: "CmM7", name: "CmM7", category: .minorMajorSeventh, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 5, finger: 4),       // 4D fret 5, pinky
            .init(fret: 5, finger: 4),       // 3G fret 5, pinky
            .init(fret: 4, finger: 3),       // 2B fret 4, ring finger
            .init(fret: 3, finger: 1)        // 1E fret 3, index finger
        ], baseFret: 3),
        GuitarChord(id: "EmM7", name: "EmM7", category: .minorMajorSeventh, fingering: [
            .init(fret: 0, finger: nil),     // 6E open
            .init(fret: 2, finger: 2),       // 5A fret 2, middle finger
            .init(fret: 1, finger: 1),       // 4D fret 1, index finger
            .init(fret: 1, finger: 1),       // 3G fret 1, index finger
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        
        // 十一和弦
        GuitarChord(id: "C11", name: "C11", category: .eleventh, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 5, finger: 4),       // 4D fret 5, pinky
            .init(fret: 3, finger: 2),       // 3G fret 3, middle finger
            .init(fret: 3, finger: 3),       // 2B fret 3, ring finger
            .init(fret: 3, finger: 1)        // 1E fret 3, index finger
        ], baseFret: 3),
        GuitarChord(id: "G11", name: "G11", category: .eleventh, fingering: [
            .init(fret: 3, finger: 3),       // 6E fret 3, ring finger
            .init(fret: 2, finger: 1),       // 5A fret 2, index finger
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 1, finger: 2),       // 2B fret 1, middle finger
            .init(fret: 1, finger: 1)        // 1E fret 1, index finger
        ], baseFret: 1),
        
        // 十三和弦
        GuitarChord(id: "C13", name: "C13", category: .thirteenth, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 3, finger: 4),       // 3G fret 3, pinky
            .init(fret: 3, finger: 3),       // 2B fret 3, ring finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "G13", name: "G13", category: .thirteenth, fingering: [
            .init(fret: 3, finger: 3),       // 6E fret 3, ring finger
            .init(fret: 2, finger: 1),       // 5A fret 2, index finger
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 2, finger: 2)        // 1E fret 2, middle finger
        ], baseFret: 1),
        
        // 大九和弦
        GuitarChord(id: "Cmaj9", name: "Cmaj9", category: .ninth, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1),
        GuitarChord(id: "Gmaj9", name: "Gmaj9", category: .ninth, fingering: [
            .init(fret: 3, finger: 3),       // 6E fret 3, ring finger
            .init(fret: 2, finger: 1),       // 5A fret 2, index finger
            .init(fret: 0, finger: nil),     // 4D open
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 0, finger: nil),     // 2B open
            .init(fret: 2, finger: 2)        // 1E fret 2, middle finger
        ], baseFret: 1),
        
        // 小九和弦
        GuitarChord(id: "Cm9", name: "Cm9", category: .ninth, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 3, finger: 3),       // 5A fret 3, ring finger
            .init(fret: 5, finger: 4),       // 4D fret 5, pinky
            .init(fret: 3, finger: 2),       // 3G fret 3, middle finger
            .init(fret: 3, finger: 3),       // 2B fret 3, ring finger
            .init(fret: 3, finger: 1)        // 1E fret 3, index finger
        ], baseFret: 3),
        GuitarChord(id: "Am9", name: "Am9", category: .ninth, fingering: [
            .init(fret: nil, finger: nil),   // 6E muted
            .init(fret: 0, finger: nil),     // 5A open
            .init(fret: 2, finger: 2),       // 4D fret 2, middle finger
            .init(fret: 0, finger: nil),     // 3G open
            .init(fret: 1, finger: 1),       // 2B fret 1, index finger
            .init(fret: 0, finger: nil)      // 1E open
        ], baseFret: 1)
    ]
    
    static func chords(in category: ChordCategory) -> [GuitarChord] {
        allChords.filter { $0.category == category }
    }
    
    /// Transpose this chord by the given number of semitones
    /// - Parameter semitones: Number of semitones to transpose (positive = up, negative = down)
    /// - Returns: A new GuitarChord transposed by the specified amount
    func transposed(by semitones: Int) -> GuitarChord {
        guard semitones != 0 else { return self }
        
        let newBaseFret = max(1, baseFret + semitones)
        let fretOffset = newBaseFret - baseFret
        
        let transposedFingering = fingering.map { stringFingering in
            if let fret = stringFingering.fret {
                let newFret = max(0, fret + fretOffset)
                // Keep original finger assignment, or nil if it was open/muted
                // User will need to determine appropriate fingering for transposed position
                return GuitarChord.StringFingering(fret: newFret, finger: stringFingering.finger)
            } else {
                // Muted strings stay muted
                return stringFingering
            }
        }
        
        return GuitarChord(
            id: "\(id)_t\(semitones)",
            name: "\(name) (+\(semitones))",
            category: category,
            fingering: transposedFingering,
            baseFret: newBaseFret
        )
    }
}
