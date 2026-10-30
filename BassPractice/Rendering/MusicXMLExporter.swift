import Foundation

struct MusicXMLExporter {
    private let config: FretboardConfig

    init(config: FretboardConfig = .standard5StringBass) {
        self.config = config
    }

    func export(score: Score) -> String {
        let hasTab = score.measures.contains { measure in
            measure.notes.contains { $0.fretboardPosition != nil }
        }

        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<!DOCTYPE score-partwise PUBLIC \"-//Recordare//DTD MusicXML 3.1 Partwise//EN\" \"http://www.musicxml.org/dtds/partwise.dtd\">\n"
        xml += "<score-partwise version=\"3.1\">\n"

        xml += exportWork(score)
        xml += exportPartList()
        xml += exportPart(score, hasTab: hasTab)

        xml += "</score-partwise>\n"
        return xml
    }

    private func exportWork(_ score: Score) -> String {
        var xml = "  <work>\n"
        xml += "    <work-title>\(escapeXML(score.title))</work-title>\n"
        xml += "  </work>\n"
        return xml
    }

    private func exportPartList() -> String {
        var xml = "  <part-list>\n"
        xml += "    <score-part id=\"P1\">\n"
        xml += "      <part-name>Bass</part-name>\n"
        xml += "      <part-abbreviation>B</part-abbreviation>\n"
        xml += "    </score-part>\n"
        xml += "  </part-list>\n"
        return xml
    }

    private func exportPart(_ score: Score, hasTab: Bool) -> String {
        var xml = "  <part id=\"P1\">\n"

        for measure in score.measures {
            xml += exportMeasure(measure, isFirst: measure.measureNumber == 1, score: score, hasTab: hasTab)
        }

        xml += "  </part>\n"
        return xml
    }

    private func exportMeasure(_ measure: ScoreMeasure, isFirst: Bool, score: Score, hasTab: Bool) -> String {
        var xml = "    <measure number=\"\(measure.measureNumber)\">\n"

        if isFirst {
            xml += exportAttributes(score: score, hasTab: hasTab)
            xml += exportDirection(tempo: score.tempo)
        }

        if let timeSig = measure.timeSignature {
            xml += exportTimeSignature(timeSig)
        }

        if let keySig = measure.keySignature {
            xml += exportKeySignature(keySig)
        }

        if measure.notes.isEmpty {
            let timeSig = measure.timeSignature ?? score.timeSignature
            xml += exportRestNote(duration: timeSig.ticksPerMeasure, staffIndex: 1, isFullMeasure: true)
            if hasTab {
                xml += exportRestNote(duration: timeSig.ticksPerMeasure, staffIndex: 2, isFullMeasure: true)
            }
        } else {
            for note in measure.notes {
                xml += exportStandardNote(note, staffIndex: 1)
                if hasTab {
                    xml += exportTabNote(note, staffIndex: 2)
                }
            }
        }

        xml += "    </measure>\n"
        return xml
    }

    private func exportRestNote(duration: Int, staffIndex: Int, isFullMeasure: Bool) -> String {
        var xml = "      <note>\n"
        if isFullMeasure {
            xml += "        <rest measure=\"yes\"/>\n"
        } else {
            xml += "        <rest/>\n"
        }
        xml += "        <duration>\(duration)</duration>\n"
        xml += "        <voice>1</voice>\n"
        xml += "        <staff>\(staffIndex)</staff>\n"
        xml += "      </note>\n"
        return xml
    }

    private func exportAttributes(score: Score, hasTab: Bool) -> String {
        var xml = "      <attributes>\n"
        xml += "        <divisions>480</divisions>\n"
        xml += exportKeySignature(score.keySignature)
        xml += exportTimeSignature(score.timeSignature)

        if hasTab {
            xml += "        <staves>2</staves>\n"
            xml += "        <clef number=\"1\">\n"
            xml += "          <sign>F</sign>\n"
            xml += "          <line>4</line>\n"
            xml += "        </clef>\n"
            xml += "        <clef number=\"2\">\n"
            xml += "          <sign>TAB</sign>\n"
            xml += "          <line>5</line>\n"
            xml += "        </clef>\n"
            xml += exportStaffDetails()
        } else {
            xml += "        <staves>1</staves>\n"
            xml += "        <clef>\n"
            xml += "          <sign>F</sign>\n"
            xml += "          <line>4</line>\n"
            xml += "        </clef>\n"
        }

        xml += "      </attributes>\n"
        return xml
    }

    private func exportStaffDetails() -> String {
        var xml = "        <staff-details number=\"2\">\n"
        xml += "          <staff-lines>\(config.stringCount)</staff-lines>\n"
        for i in (0..<config.stringCount).reversed() {
            let pitch = config.tuning[i]
            let lineNumber = config.stringCount - i
            xml += "          <staff-tuning line=\"\(lineNumber)\">\n"
            xml += "            <tuning-step>\(stepName(pitch.noteName))</tuning-step>\n"
            if let alter = alterValue(pitch.noteName) {
                xml += "            <tuning-alter>\(alter)</tuning-alter>\n"
            }
            xml += "            <tuning-octave>\(pitch.octave)</tuning-octave>\n"
            xml += "          </staff-tuning>\n"
        }
        xml += "        </staff-details>\n"
        return xml
    }

    private func exportKeySignature(_ keySig: KeySignatureData) -> String {
        var xml = "        <key>\n"
        xml += "          <fifths>\(keySig.fifths)</fifths>\n"
        xml += "          <mode>\(keySig.mode)</mode>\n"
        xml += "        </key>\n"
        return xml
    }

    private func exportTimeSignature(_ timeSig: TimeSignatureData) -> String {
        var xml = "        <time>\n"
        xml += "          <beats>\(timeSig.numerator)</beats>\n"
        xml += "          <beat-type>\(timeSig.denominator)</beat-type>\n"
        xml += "        </time>\n"
        return xml
    }

    private func exportDirection(tempo: Int) -> String {
        var xml = "      <direction placement=\"above\">\n"
        xml += "        <direction-type>\n"
        xml += "          <metronome>\n"
        xml += "            <beat-unit>quarter</beat-unit>\n"
        xml += "            <per-minute>\(tempo)</per-minute>\n"
        xml += "          </metronome>\n"
        xml += "        </direction-type>\n"
        xml += "        <sound tempo=\"\(tempo)\"/>\n"
        xml += "      </direction>\n"
        return xml
    }

    private func exportStandardNote(_ note: ScoreNote, staffIndex: Int) -> String {
        var xml = "      <note>\n"

        if note.isRest {
            xml += "        <rest/>\n"
        } else {
            xml += exportPitch(note.pitch)
        }

        xml += exportDuration(note.duration)
        xml += "        <voice>1</voice>\n"
        xml += "        <type>\(note.duration.musicXMLType)</type>\n"

        if note.duration.dots > 0 {
            for _ in 0..<note.duration.dots {
                xml += "        <dot/>\n"
            }
        }

        xml += "        <staff>\(staffIndex)</staff>\n"

        if !note.isRest && note.velocity > 0 {
            xml += "        <dynamics>\n"
            xml += "          <\(velocityToDynamic(note.velocity))/>\n"
            xml += "        </dynamics>\n"
        }

        xml += "      </note>\n"
        return xml
    }

    private func exportTabNote(_ note: ScoreNote, staffIndex: Int) -> String {
        var xml = "      <note>\n"

        if note.isRest || note.fretboardPosition == nil {
            xml += "        <rest/>\n"
        } else {
            let pos = note.fretboardPosition!
            let stringNumber = config.stringCount - pos.stringIndex
            let displayOctave = 4 + (stringNumber - 1) / 2
            xml += "        <unpitched>\n"
            xml += "          <display-step>C</display-step>\n"
            xml += "          <display-octave>\(displayOctave)</display-octave>\n"
            xml += "        </unpitched>\n"
        }

        xml += exportDuration(note.duration)
        xml += "        <voice>1</voice>\n"
        xml += "        <type>\(note.duration.musicXMLType)</type>\n"
        xml += "        <staff>\(staffIndex)</staff>\n"

        if !note.isRest, let pos = note.fretboardPosition {
            let stringNumber = config.stringCount - pos.stringIndex
            xml += "        <notations>\n"
            xml += "          <technical>\n"
            xml += "            <string>\(stringNumber)</string>\n"
            xml += "            <fret>\(pos.fretNumber)</fret>\n"
            xml += "          </technical>\n"
            xml += "        </notations>\n"
        }

        xml += "      </note>\n"
        return xml
    }

    private func exportPitch(_ pitch: Pitch) -> String {
        var xml = "        <pitch>\n"
        xml += "          <step>\(stepName(pitch.noteName))</step>\n"

        if let alter = alterValue(pitch.noteName) {
            xml += "          <alter>\(alter)</alter>\n"
        }

        xml += "          <octave>\(pitch.octave + 1)</octave>\n"
        xml += "        </pitch>\n"
        return xml
    }

    private func exportDuration(_ duration: NoteDuration) -> String {
        "        <duration>\(duration.ticks)</duration>\n"
    }

    private func stepName(_ noteName: NoteName) -> String {
        switch noteName {
        case .C, .Cs: return "C"
        case .D, .Ds: return "D"
        case .E: return "E"
        case .F, .Fs: return "F"
        case .G, .Gs: return "G"
        case .A, .As: return "A"
        case .B: return "B"
        }
    }

    private func alterValue(_ noteName: NoteName) -> Int? {
        switch noteName {
        case .Cs, .Ds, .Fs, .Gs, .As: return 1
        default: return nil
        }
    }

    private func velocityToDynamic(_ velocity: Int) -> String {
        switch velocity {
        case 0...20: return "ppp"
        case 21...40: return "pp"
        case 41...60: return "p"
        case 61...80: return "mp"
        case 81...100: return "mf"
        case 101...110: return "f"
        case 111...120: return "ff"
        default: return "fff"
        }
    }

    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
