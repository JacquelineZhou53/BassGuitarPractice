import Foundation
import SwiftUI
import Observation

/// 音阶练习会话 ViewModel - 包装 PracticeSessionViewModel 并添加指法导航
@Observable
@MainActor
final class ScalePracticeSessionViewModel {
    let score: Score
    let fingerings: [FingeringPattern]
    let scale: Scale
    let root: Pitch
    
    private(set) var practiceViewModel: PracticeSessionViewModel
    
    var currentFingeringIndex: Int = 0
    var showFingeringNavigation: Bool = true
    
    init(score: Score, fingerings: [FingeringPattern], scale: Scale, root: Pitch) {
        self.score = score
        self.fingerings = fingerings
        self.scale = scale
        self.root = root
        self.practiceViewModel = PracticeSessionViewModel(score: score)
    }
    
    /// 切换到指定指法
    func switchToFingering(at index: Int) {
        guard index >= 0 && index < fingerings.count else { return }
        
        currentFingeringIndex = index
        
        // 计算该指法在 Score 中的起始小节
        let builder = ScaleScoreBuilder(
            scale: scale,
            root: root,
            fingerings: fingerings,
            instrumentType: score.instrumentType,
            tempo: score.tempo
        )
        
        let measureIndex = builder.measureIndexForFingering(fingeringIndex: index)
        
        // 跳转到对应小节
        practiceViewModel.seekToMeasure(measureIndex)
    }
    
    /// 获取当前指法的显示名称
    var currentFingeringName: String {
        guard currentFingeringIndex < fingerings.count else { return "" }
        return fingerings[currentFingeringIndex].positionName
    }
    
    /// 切换到下一个指法
    func nextFingering() {
        let nextIndex = (currentFingeringIndex + 1) % fingerings.count
        switchToFingering(at: nextIndex)
    }
    
    /// 切换到上一个指法
    func previousFingering() {
        let prevIndex = (currentFingeringIndex - 1 + fingerings.count) % fingerings.count
        switchToFingering(at: prevIndex)
    }
}
