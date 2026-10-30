import SwiftUI

struct FretboardView: View {
    let config: FretboardConfig
    @Binding var notes: [FretboardNote]
    @Binding var selectedNoteID: UUID?
    var highlightNotes: [FretboardNote] = []
    var showFingerNumbers: Bool = true
    var noteColor: Color = .blue
    var highlightColor: Color = .orange
    var visibleFretRange: ClosedRange<Int>? = nil
    var isEditable: Bool = false
    var onNoteMoved: ((FretboardNote) -> Void)? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var dragMoved = false
    @State private var dragLocation: CGPoint?
    @State private var invalidStringIndex: Int?

    var body: some View {
        GeometryReader { geometry in
            let layout = FretboardLayout(config: config, size: geometry.size, visibleFretRange: visibleFretRange)

            Canvas { context, size in
                drawFretboard(context: &context, layout: layout)
                drawHighlightNotes(context: &context, layout: layout)
                drawNotes(context: &context, layout: layout)
                drawInvalidDragFeedback(context: &context, layout: layout)
            }
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        handleDrag(at: value.location, layout: layout)
                    }
                    .onEnded { _ in
                        finishDrag()
                        dragOffset = .zero
                    },
                including: isEditable ? .all : .none
            )
            .onTapGesture { location in
                handleTap(at: location, layout: layout)
            }
        }
        .background(Color(.systemBackground))
    }

    private func drawFretboard(context: inout GraphicsContext, layout: FretboardLayout) {
        drawFretMarkers(context: &context, layout: layout)
        drawFrets(context: &context, layout: layout)
        drawStrings(context: &context, layout: layout)
        drawStringLabels(context: &context, layout: layout)
        drawFretNumbers(context: &context, layout: layout)
    }

    private func drawFretMarkers(context: inout GraphicsContext, layout: FretboardLayout) {
        let markerFrets = [3, 5, 7, 9, 15, 17, 19, 21]
        let doubleFrets = [12, 24]

        for fret in markerFrets {
            guard fret >= layout.visibleFrets.lowerBound && fret <= layout.visibleFrets.upperBound else { continue }
            let x = layout.fretX(fret: fret) + layout.fretWidth * 0.5
            let y = layout.topPadding + layout.playableHeight * 0.5
            let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
            context.fill(Path(ellipseIn: rect), with: .color(.gray.opacity(0.3)))
        }

        for fret in doubleFrets {
            guard fret >= layout.visibleFrets.lowerBound && fret <= layout.visibleFrets.upperBound else { continue }
            let x = layout.fretX(fret: fret) + layout.fretWidth * 0.5
            let y1 = layout.topPadding + layout.playableHeight * 0.3
            let y2 = layout.topPadding + layout.playableHeight * 0.7
            let rect1 = CGRect(x: x - 4, y: y1 - 4, width: 8, height: 8)
            let rect2 = CGRect(x: x - 4, y: y2 - 4, width: 8, height: 8)
            context.fill(Path(ellipseIn: rect1), with: .color(.gray.opacity(0.3)))
            context.fill(Path(ellipseIn: rect2), with: .color(.gray.opacity(0.3)))
        }
    }

    private func drawFrets(context: inout GraphicsContext, layout: FretboardLayout) {
        for fret in layout.visibleFrets {
            let x = layout.fretX(fret: fret)
            var path = Path()
            path.move(to: CGPoint(x: x, y: layout.topPadding))
            path.addLine(to: CGPoint(x: x, y: layout.topPadding + layout.playableHeight))

            let lineWidth: CGFloat = fret == 0 ? 3 : 1.5
            let color: Color = fret == 0 ? .primary : .gray.opacity(0.5)
            context.stroke(path, with: .color(color), lineWidth: lineWidth)
        }
    }

    private func drawStrings(context: inout GraphicsContext, layout: FretboardLayout) {
        for stringIndex in 0..<config.stringCount {
            let y = layout.stringY(stringIndex: stringIndex)
            var path = Path()
            path.move(to: CGPoint(x: layout.leftPadding - layout.fretWidth * 0.5, y: y))
            path.addLine(to: CGPoint(x: layout.leftPadding + layout.playableWidth, y: y))

            let thickness = 3.0 - Double(stringIndex) * 0.4
            context.stroke(path, with: .color(.gray), lineWidth: thickness)
        }
    }

    private func drawStringLabels(context: inout GraphicsContext, layout: FretboardLayout) {
        for stringIndex in 0..<config.stringCount {
            let y = layout.stringY(stringIndex: stringIndex)
            let label = config.stringLabel(at: stringIndex)
            let text = Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            context.draw(text, at: CGPoint(x: 12, y: y), anchor: .center)
        }
    }

    private func drawFretNumbers(context: inout GraphicsContext, layout: FretboardLayout) {
        for fret in layout.visibleFrets where fret % 2 == 0 || fret == 0 {
            let x = fret == 0 ? layout.fretX(fret: 0) + layout.fretWidth * 0.25 : layout.fretX(fret: fret) + layout.fretWidth * 0.5
            let y = layout.topPadding + layout.playableHeight + 14
            let text = Text("\(fret)")
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.6))
            context.draw(text, at: CGPoint(x: x, y: y), anchor: .center)
        }
    }

    private func drawHighlightNotes(context: inout GraphicsContext, layout: FretboardLayout) {
        for note in highlightNotes {
            let point = layout.position(for: note.position)
            let radius: CGFloat = 12
            let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(highlightColor.opacity(0.3)))
            context.stroke(Path(ellipseIn: rect), with: .color(highlightColor), lineWidth: 1.5)
        }
    }

    private func drawNotes(context: inout GraphicsContext, layout: FretboardLayout) {
        for note in notes {
            let point = layout.position(for: note.position)
            let isSelected = note.id == selectedNoteID
            let radius: CGFloat = isSelected ? 14 : 12
            let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)

            let color = isSelected ? .red : noteColor
            context.fill(Path(ellipseIn: rect), with: .color(color))
            context.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 1.5)

            if showFingerNumbers, let finger = note.position.finger {
                let fingerText = Text("\(finger)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                context.draw(fingerText, at: point, anchor: .center)
            } else {
                let noteText = Text(note.pitch.noteName.displayName)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white)
                context.draw(noteText, at: point, anchor: .center)
            }
        }
    }

    private func drawInvalidDragFeedback(context: inout GraphicsContext, layout: FretboardLayout) {
        guard let invalidString = invalidStringIndex,
              let location = dragLocation else { return }

        let y = layout.stringY(stringIndex: invalidString)
        var line = Path()
        line.move(to: CGPoint(x: layout.leftPadding - layout.fretWidth * 0.5, y: y))
        line.addLine(to: CGPoint(x: layout.leftPadding + layout.playableWidth, y: y))
        context.stroke(line, with: .color(.red.opacity(0.35)), lineWidth: 5)

        let radius: CGFloat = 11
        let ring = CGRect(x: location.x - radius, y: location.y - radius, width: radius * 2, height: radius * 2)
        context.stroke(Path(ellipseIn: ring), with: .color(.red), lineWidth: 2)

        var cross = Path()
        cross.move(to: CGPoint(x: location.x - 5, y: location.y - 5))
        cross.addLine(to: CGPoint(x: location.x + 5, y: location.y + 5))
        cross.move(to: CGPoint(x: location.x + 5, y: location.y - 5))
        cross.addLine(to: CGPoint(x: location.x - 5, y: location.y + 5))
        context.stroke(cross, with: .color(.red), lineWidth: 2)

        let text = Text("该弦无对应品位")
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.red)
        context.draw(text, at: CGPoint(x: location.x, y: max(10, location.y - 22)), anchor: .center)
    }

    private func handleTap(at location: CGPoint, layout: FretboardLayout) {
        let tappedString = layout.nearestString(to: location.y)
        let tappedFret = layout.nearestFret(to: location.x)

        if let existingIndex = notes.firstIndex(where: { note in
            let pos = layout.position(for: note.position)
            return hypot(pos.x - location.x, pos.y - location.y) < 20
        }) {
            if selectedNoteID == notes[existingIndex].id {
                selectedNoteID = nil
            } else {
                selectedNoteID = notes[existingIndex].id
            }
        }
    }

    private func handleDrag(at location: CGPoint, layout: FretboardLayout) {
        guard isEditable,
              let selectedID = selectedNoteID,
              let idx = notes.firstIndex(where: { $0.id == selectedID }) else { return }

        dragLocation = location
        let newString = layout.nearestString(to: location.y)

        if notes[idx].moveTo(string: newString, config: config) {
            invalidStringIndex = nil
            dragMoved = true
        } else {
            // The target string cannot reach this pitch within the configured
            // fret range. Keep the note where it was and show why.
            invalidStringIndex = newString
        }
    }

    private func finishDrag() {
        if dragMoved,
           let selectedID = selectedNoteID,
           let note = notes.first(where: { $0.id == selectedID }) {
            onNoteMoved?(note)
        }

        dragMoved = false
        dragLocation = nil
        invalidStringIndex = nil
    }
}
