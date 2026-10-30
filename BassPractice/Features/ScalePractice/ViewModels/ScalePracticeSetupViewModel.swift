import Foundation
import SwiftUI

/// 音阶练习设置页面的 ViewModel
@Observable
class ScalePracticeSetupViewModel {
    let scale: Scale
    let root: Pitch
    let fingerings: [FingeringPattern]
    
    var instrumentType: InstrumentType
    var selectedFingeringIndices: Set<Int>
    var tempo: Int
    var displayMode: ScalePracticeDisplayMode
    
    init(
        scale: Scale,
        root: Pitch,
        fingerings: [FingeringPattern],
        instrumentType: InstrumentType,
        selectedFingeringIndices: Set<Int>? = nil,
        tempo: Int = 80,
        displayMode: ScalePracticeDisplayMode = .selectedOnly
    ) {
        self.scale = scale
        self.root = root
        self.fingerings = fingerings
        self.instrumentType = instrumentType
        self.selectedFingeringIndices = selectedFingeringIndices ?? [0]
        self.tempo = tempo
        self.displayMode = displayMode
    }
}

/// 音阶练习显示模式
enum ScalePracticeDisplayMode: String, CaseIterable {
    case selectedOnly = "selected_only"
    case allFingerings = "all_fingerings"
    
    var displayName: String {
        switch self {
        case .selectedOnly: return "仅选中指法"
        case .allFingerings: return "所有指法"
        }
    }
}
