import SwiftUI

struct ChordDiagramView: View {
    let chord: GuitarChord
    
    private let stringCount = 6
    private let stringNames = ["E", "A", "D", "G", "B", "e"] // Low to high
    
    // Calculate which frets to display based on chord position
    private var displayedFrets: Int {
        // Find the highest fret used in this chord
        let maxFret = chord.fingering.compactMap { $0.fret }.max() ?? 0
        // Show at least 4 frets, or enough to fit the chord
        return max(4, maxFret - chord.baseFret + 2)
    }
    
    private var startFret: Int {
        return chord.baseFret
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let stringSpacing = width / CGFloat(stringCount + 1)
            let fretSpacing = height / CGFloat(displayedFrets + 1)
            
            ZStack {
                // Fret number label - more prominent
                if startFret > 1 {
                    VStack(spacing: 2) {
                        Text("从")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                        Text("\(startFret)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                        Text("品")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                    .padding(4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                    .position(x: 20, y: fretSpacing / 2)
                }
                
                // Fret lines (horizontal)
                ForEach(0...displayedFrets, id: \.self) { fret in
                    let y = CGFloat(fret) * fretSpacing + fretSpacing / 2
                    Path { path in
                        path.move(to: CGPoint(x: stringSpacing, y: y))
                        path.addLine(to: CGPoint(x: width - stringSpacing, y: y))
                    }
                    .stroke(Color.primary.opacity(0.3), lineWidth: fret == 0 ? 2 : 1)
                }
                
                // String lines (vertical)
                ForEach(0..<stringCount, id: \.self) { string in
                    let x = CGFloat(string + 1) * stringSpacing
                    Path { path in
                        path.move(to: CGPoint(x: x, y: fretSpacing / 2))
                        path.addLine(to: CGPoint(x: x, y: height - fretSpacing / 2))
                    }
                    .stroke(Color.primary.opacity(0.5), lineWidth: 1)
                }
                
                // Finger positions
                ForEach(0..<stringCount, id: \.self) { string in
                    let fingering = chord.fingering[string]
                    let x = CGFloat(string + 1) * stringSpacing
                    
                    Group {
                        if let fret = fingering.fret {
                            if fret >= startFret {
                                if fret == 0 {
                                    // Open string - draw circle at top
                                    Circle()
                                        .stroke(Color.primary, lineWidth: 2)
                                        .frame(width: 12, height: 12)
                                        .position(x: x, y: fretSpacing / 4)
                                } else {
                                    // Fretted note - draw filled circle with finger number
                                    // Position relative to startFret (baseFret)
                                    let relativeFret = fret - startFret + 1
                                    let y = CGFloat(relativeFret) * fretSpacing + fretSpacing / 2
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 24, height: 24)
                                        if let finger = fingering.finger {
                                            Text("\(finger)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .position(x: x, y: y)
                                }
                            }
                        } else {
                            // Muted string - draw X at top
                            Text("×")
                                .font(.title3)
                                .foregroundColor(.red)
                                .position(x: x, y: fretSpacing / 4)
                        }
                    }
                }
                
                // String names at bottom
                ForEach(0..<stringCount, id: \.self) { string in
                    let x = CGFloat(string + 1) * stringSpacing
                    Text(stringNames[string])
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .position(x: x, y: height - 10)
                }
            }
        }
        .aspectRatio(0.8, contentMode: .fit)
    }
}

struct ChordPracticeView: View {
    let chord: GuitarChord
    @State private var transposition: Int = 0
    @State private var useCapoMode: Bool = false // false = move fingering, true = use capo
    
    var currentTransposedChord: GuitarChord? {
        if transposition == 0 {
            return chord
        }
        
        if useCapoMode {
            // Capo mode: keep original fingering, just change the name
            return GuitarChord(
                id: "\(chord.id)_capo\(transposition)",
                name: "\(chord.name) (Capo \(transposition))",
                category: chord.category,
                fingering: chord.fingering, // Same fingering
                baseFret: chord.baseFret    // Same baseFret
            )
        } else {
            // Move fingering mode: shift all frets up
            return chord.transposed(by: transposition)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text(currentTransposedChord?.name ?? chord.name)
                .font(.title)
                .fontWeight(.bold)
            
            // 和弦构成说明 - 紧凑版
            let displayChordForInfo = currentTransposedChord ?? chord
            if let rootNote = displayChordForInfo.rootNote {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("根音:\(rootNote)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        let notes = displayChordForInfo.chordNotes(transposition: transposition)
                        Text(notes.joined(separator: "、"))
                            .font(.caption)
                            .foregroundColor(.purple)
                            .fontWeight(.medium)
                    }
                }
                .padding(6)
                .background(Color.purple.opacity(0.08))
                .cornerRadius(6)
            }
            
            ChordDiagramView(chord: currentTransposedChord ?? chord)
                .frame(maxWidth: 200, maxHeight: 240)
            
            // Transposition control - compact
            HStack(spacing: 12) {
                Text("移调")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: { transposition -= 1 }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.red)
                }
                
                Text(transposition == 0 ? "原调" : "\(transposition > 0 ? "+" : "")\(transposition)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 50)
                
                Button(action: { transposition += 1 }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
                
                Picker("", selection: $useCapoMode) {
                    Text("指型").tag(false)
                    Text("Capo").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
            
            if transposition != 0 {
                Button("重置") { transposition = 0 }
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            // Fingering info - compact
            let displayChord = currentTransposedChord ?? chord
            fingeringListView(displayChord: displayChord)
        }
        .padding(8)
    }
    
    private func fingeringListView(displayChord: GuitarChord) -> some View {
        let stringLabels = ["6E", "5A", "4D", "3G", "2B", "1e"]
        let stringBasePitches = [40, 45, 50, 55, 59, 64]
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        
        return VStack(alignment: .leading, spacing: 4) {
            Text("指法")
                .font(.caption)
                .fontWeight(.semibold)
            
            ForEach(stringLabels.indices, id: \.self) { stringIndex in
                fingeringRow(
                    index: stringIndex,
                    label: stringLabels[stringIndex],
                    fingering: displayChord.fingering[stringIndex],
                    basePitch: stringBasePitches[stringIndex],
                    noteNames: noteNames
                )
            }
        }
        .padding(6)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
    
    @ViewBuilder
    private func fingeringRow(index: Int, label: String, fingering: GuitarChord.StringFingering, basePitch: Int, noteNames: [String]) -> some View {
        if index < 6 {
            let displayChord = currentTransposedChord ?? chord
            
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption2)
                    .frame(width: 30)
                
                if let fret = fingering.fret {
                    if fret == 0 {
                        let noteName = noteNames[basePitch % 12]
                        Text("空(\(noteName))")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        let midiNote = basePitch + fret
                        let noteName = noteNames[midiNote % 12]
                        
                        let chordNotes = displayChord.chordNotes(transposition: transposition)
                        let intervalNames = displayChord.intervalNames
                        let roleText = chordNotes.firstIndex(of: noteName).map { "/\(intervalNames[$0])" } ?? ""
                        
                        HStack(spacing: 2) {
                            Text("\(fret)")
                                .fontWeight(fret >= 5 ? .bold : .regular)
                            Text("(\(noteName)\(roleText))")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        
                        if let finger = fingering.finger {
                            Text("\(finger)指")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("×")
                        .foregroundColor(.red)
                }
            }
        }
    }
}
