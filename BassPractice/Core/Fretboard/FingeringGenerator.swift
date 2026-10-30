import Foundation

struct FingeringPattern: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let positions: [FretboardPosition]
    let baseFret: Int
    let positionName: String

    init(id: UUID = UUID(), name: String, positions: [FretboardPosition], baseFret: Int, positionName: String = "") {
        self.id = id
        self.name = name
        self.positions = positions
        self.baseFret = baseFret
        self.positionName = positionName
    }
}

struct FingeringConstraints {
    var maxFretSpan: Int = 5
    var maxPositionWidth: Int = 6
    var maxPatterns: Int = 30
    var minNotes: Int = 4
    var requireUniqueStrings: Bool = false

    static let `default` = FingeringConstraints()
}

struct FingeringGenerator {
    let config: FretboardConfig
    let solver: StringFretSolver

    init(config: FretboardConfig) {
        self.config = config
        self.solver = StringFretSolver(config: config)
    }

    func generate(pitches: [Pitch], constraints: FingeringConstraints = .default) -> [FingeringPattern] {
        guard pitches.count >= constraints.minNotes else {
            return generateSimple(pitches: pitches)
        }

        let candidatesPerNote: [[FretboardPosition]] = pitches.map { pitch in
            solver.allPositionsForPitch(pitch)
        }

        guard candidatesPerNote.allSatisfy({ !$0.isEmpty }) else { return [] }

        var results: [FingeringPattern] = []
        var currentPath: [FretboardPosition] = []

        backtrack(
            candidates: candidatesPerNote,
            index: 0,
            currentPath: &currentPath,
            results: &results,
            constraints: constraints
        )

        return deduplicateAndRank(results, pitches: pitches)
    }

    private func generateSimple(pitches: [Pitch]) -> [FingeringPattern] {
        var positions: [FretboardPosition] = []
        var prevPos: FretboardPosition? = nil

        for pitch in pitches {
            if let pos = solver.bestPositionForPitch(pitch, near: prevPos) {
                positions.append(pos)
                prevPos = pos
            }
        }

        guard !positions.isEmpty else { return [] }

        let baseFret = positions.map(\.fretNumber).min() ?? 0
        return [FingeringPattern(
            name: "标准指法",
            positions: positions,
            baseFret: baseFret,
            positionName: "\(baseFret)把位"
        )]
    }

    private func backtrack(
        candidates: [[FretboardPosition]],
        index: Int,
        currentPath: inout [FretboardPosition],
        results: inout [FingeringPattern],
        constraints: FingeringConstraints
    ) {
        guard results.count < constraints.maxPatterns else { return }

        guard index < candidates.count else {
            let baseFret = currentPath.map(\.fretNumber).min() ?? 0
            results.append(FingeringPattern(
                name: "指法 \(results.count + 1)",
                positions: currentPath,
                baseFret: baseFret,
                positionName: baseFret == 0 ? "开放把位" : "\(baseFret)把位"
            ))
            return
        }

        let sortedCandidates = candidates[index].sorted { a, b in
            let prefA = preferenceScore(a, prev: currentPath.last)
            let prefB = preferenceScore(b, prev: currentPath.last)
            return prefA < prefB
        }

        for position in sortedCandidates {
            if constraints.requireUniqueStrings {
                let usedStrings = Set(currentPath.map(\.stringIndex))
                if usedStrings.contains(position.stringIndex) { continue }
            }

            if let lastPos = currentPath.last {
                let fretSpan = abs(position.fretNumber - lastPos.fretNumber)
                if fretSpan > constraints.maxFretSpan { continue }

                let allFrets = currentPath.map(\.fretNumber) + [position.fretNumber]
                let span = (allFrets.max() ?? 0) - (allFrets.min() ?? 0)
                if span > constraints.maxPositionWidth { continue }
            }

            currentPath.append(position)
            backtrack(candidates: candidates, index: index + 1, currentPath: &currentPath, results: &results, constraints: constraints)
            currentPath.removeLast()
        }
    }

    private func preferenceScore(_ pos: FretboardPosition, prev: FretboardPosition?) -> Int {
        var score = 0

        if pos.fretNumber == 0 { score += 5 }
        if pos.fretNumber >= 1 && pos.fretNumber <= 5 { score -= 2 }

        if let prev = prev {
            score += abs(pos.fretNumber - prev.fretNumber) * 2
            score += abs(pos.stringIndex - prev.stringIndex)
        } else {
            score += abs(pos.stringIndex - 2)
        }

        return score
    }

    private func deduplicateAndRank(_ patterns: [FingeringPattern], pitches: [Pitch]) -> [FingeringPattern] {
        var unique: [FingeringPattern] = []
        var seen: Set<String> = []

        for pattern in patterns {
            let key = pattern.positions.map { "\($0.stringIndex)-\($0.fretNumber)" }.joined(separator: ",")
            if !seen.contains(key) {
                seen.insert(key)
                unique.append(pattern)
            }
        }

        let ranked = unique.enumerated().map { index, pattern in
            FingeringPattern(
                id: pattern.id,
                name: "指法 \(index + 1)",
                positions: pattern.positions,
                baseFret: pattern.baseFret,
                positionName: pattern.positionName
            )
        }

        return ranked
    }
}
