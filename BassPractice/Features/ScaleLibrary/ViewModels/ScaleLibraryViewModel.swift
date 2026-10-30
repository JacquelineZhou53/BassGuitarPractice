import SwiftUI
import Observation
import Combine

@Observable
class ScaleLibraryViewModel {
    var instrumentType: InstrumentType = .bass
    var selectedCategory: ScaleCategory? = .pentatonic
    var selectedScale: Scale?
    var selectedGuitarChord: GuitarChord?
    var chordTransposition: Int = 0 // Semitones to transpose guitar chords
    var selectedRoot: Pitch?
    var selectedFingeringIndex: Int = 0
    var fingerings: [FingeringPattern] = []

    var config: FretboardConfig { instrumentType.defaultFretboardConfig }

    var arpeggioScales: [Scale] {
        Arpeggio.allArpeggios.map { arp in
            Scale(id: arp.id, name: arp.name, category: .arpeggio, intervals: arp.intervals)
        }
    }

    var guitarChordCategories: [GuitarChord.ChordCategory] {
        GuitarChord.ChordCategory.allCases
    }

    var scalesInCategory: [Scale] {
        guard let category = selectedCategory else { return [] }
        if category == .arpeggio {
            return arpeggioScales
        }
        return Scale.allScales.filter { $0.category == category }
    }

    var rootNotes: [Pitch] {
        switch instrumentType {
        case .bass:
            return ScaleLibrary.rootNotes
        case .guitar:
            return ScaleLibrary.guitarRootNotes
        }
    }

    func selectScale(_ scale: Scale) {
        print("ViewModel: selectScale called with \(scale.name)")
        self.selectedScale = scale
        self.selectedGuitarChord = nil
        self.selectedRoot = nil
        self.selectedFingeringIndex = 0
        self.fingerings = []
        print("ViewModel: selectedScale is now \(selectedScale?.name ?? "nil")")
    }

    func selectGuitarChord(_ chord: GuitarChord) {
        self.selectedGuitarChord = chord
        self.chordTransposition = 0 // Reset transposition when selecting a new chord
        self.selectedScale = nil
        self.selectedRoot = nil
        self.selectedFingeringIndex = 0
        self.fingerings = []
    }
    
    func setChordTransposition(_ semitones: Int) {
        self.chordTransposition = semitones
    }
    
    var currentTransposedChord: GuitarChord? {
        guard let chord = selectedGuitarChord else { return nil }
        if chordTransposition == 0 {
            return chord
        }
        return chord.transposed(by: chordTransposition)
    }

    func selectRoot(_ root: Pitch) {
        self.selectedRoot = root
        self.selectedFingeringIndex = 0
        regenerateFingerings()
    }

    func selectScaleAndRoot(_ scale: Scale, root: Pitch) {
        self.selectedScale = scale
        self.selectedRoot = root
        self.selectedFingeringIndex = 0
        regenerateFingerings()
    }

    private func regenerateFingerings() {
        guard let scale = selectedScale, let root = selectedRoot else { return }

        if scale.category == .arpeggio {
            let arpeggio = Arpeggio.allArpeggios.first { $0.id == scale.id }
            if let arp = arpeggio {
                fingerings = ScaleLibrary.generateArpeggioFingerings(for: arp, root: root, config: config)
            }
        } else {
            fingerings = ScaleLibrary.generateFingerings(for: scale, root: root, config: config)
        }
    }

    var currentFingering: FingeringPattern? {
        guard selectedFingeringIndex < fingerings.count else { return nil }
        return fingerings[selectedFingeringIndex]
    }

    func selectFingering(at index: Int) {
        guard index < fingerings.count else { return }
        selectedFingeringIndex = index
    }

    var isSelectedComplete: Bool {
        if selectedGuitarChord != nil {
            return true // Guitar chords don't need root selection
        }
        return selectedScale != nil && selectedRoot != nil && !fingerings.isEmpty
    }
}

// Wrapper to make ScaleLibraryViewModel compatible with @ObservedObject
class ScaleLibraryViewModelWrapper: ObservableObject {
    @Published var transposition: Int = 0
    let viewModel: ScaleLibraryViewModel
    
    init(viewModel: ScaleLibraryViewModel) {
        self.viewModel = viewModel
        self.transposition = viewModel.chordTransposition
    }
    
    func setTransposition(_ value: Int) {
        self.transposition = value
        viewModel.chordTransposition = value
    }
    
    var currentTransposedChord: GuitarChord? {
        guard let chord = viewModel.selectedGuitarChord else { return nil }
        if transposition == 0 {
            return chord
        }
        return chord.transposed(by: transposition)
    }
}
