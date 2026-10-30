import SwiftUI

struct FretboardLayout {
    let config: FretboardConfig
    let size: CGSize
    let visibleFretRange: ClosedRange<Int>?

    let leftPadding: CGFloat = 44
    let rightPadding: CGFloat = 20
    let topPadding: CGFloat = 24
    let bottomPadding: CGFloat = 24

    var visibleFrets: ClosedRange<Int> {
        if let range = visibleFretRange {
            return range
        }
        return 0...min(config.fretCount, 24)
    }

    var fretCount: Int {
        visibleFrets.upperBound - visibleFrets.lowerBound + 1
    }

    var playableWidth: CGFloat { size.width - leftPadding - rightPadding }
    var playableHeight: CGFloat { size.height - topPadding - bottomPadding }

    var stringSpacing: CGFloat {
        guard config.stringCount > 1 else { return playableHeight }
        return playableHeight / CGFloat(config.stringCount - 1)
    }

    var fretWidth: CGFloat {
        guard fretCount > 1 else { return playableWidth }
        return playableWidth / CGFloat(fretCount - 1)
    }

    func position(for fretPos: FretboardPosition) -> CGPoint {
        let fretOffset = CGFloat(fretPos.fretNumber - visibleFrets.lowerBound)
        let x: CGFloat
        if fretPos.fretNumber == 0 {
            x = leftPadding - fretWidth * 0.5
        } else {
            x = leftPadding + fretOffset * fretWidth - fretWidth * 0.5
        }
        // 反转弦的顺序：高音弦在上，低音弦在下
        let reversedStringIndex = config.stringCount - 1 - fretPos.stringIndex
        let y = topPadding + CGFloat(reversedStringIndex) * stringSpacing
        return CGPoint(x: x, y: y)
    }

    func nearestString(to y: CGFloat) -> Int {
        let relative = y - topPadding
        guard stringSpacing > 0 else { return 0 }
        let index = Int(round(relative / stringSpacing))
        // 反转：屏幕上的index需要转换回实际的stringIndex
        let actualIndex = config.stringCount - 1 - index
        return max(0, min(config.stringCount - 1, actualIndex))
    }

    func nearestFret(to x: CGFloat) -> Int {
        let relative = x - leftPadding
        guard fretWidth > 0 else { return 0 }
        let fret = Int(round(relative / fretWidth)) + visibleFrets.lowerBound
        return max(visibleFrets.lowerBound, min(visibleFrets.upperBound, fret))
    }

    func fretX(fret: Int) -> CGFloat {
        if fret == 0 {
            return leftPadding - fretWidth
        }
        let offset = CGFloat(fret - visibleFrets.lowerBound)
        return leftPadding + offset * fretWidth
    }

    func stringY(stringIndex: Int) -> CGFloat {
        // 反转弦的顺序：高音弦在上，低音弦在下
        let reversedStringIndex = config.stringCount - 1 - stringIndex
        return topPadding + CGFloat(reversedStringIndex) * stringSpacing
    }
}
