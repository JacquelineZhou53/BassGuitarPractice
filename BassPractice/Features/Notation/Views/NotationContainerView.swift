import SwiftUI

struct NotationContainerView: View {
    let score: Score
    private var exporter: MusicXMLExporter { MusicXMLExporter(config: score.instrumentType.defaultFretboardConfig) }
    private var musicXML: String { exporter.export(score: score) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            NotationView(musicXML: musicXML)
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(score.title)
                    .font(.headline)
                if !score.composer.isEmpty {
                    Text(score.composer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            HStack(spacing: 12) {
                Label(score.tempo.description, systemImage: "metronome")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label(score.timeSignature.displayString, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct NotationPreviewView: View {
    let musicXML: String

    var body: some View {
        NotationView(musicXML: musicXML)
    }
}
