import SwiftUI
import UniformTypeIdentifiers

struct ScoreExportView: View {
    let score: Score
    @Environment(\.dismiss) private var dismiss

    private var musicXMLExporter: MusicXMLExporter { MusicXMLExporter(config: score.instrumentType.defaultFretboardConfig) }
    private let midiExporter = MIDIExporter()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerSection

                exportOption(
                    title: "导出 MusicXML",
                    subtitle: "通用乐谱交换格式，可导入 MuseScore、Finale 等",
                    icon: "doc.richtext",
                    color: .blue
                ) {
                    exportMusicXML()
                }

                exportOption(
                    title: "导出 MIDI",
                    subtitle: "标准 MIDI 文件，可导入 DAW 或其他乐器软件",
                    icon: "music.note",
                    color: .green
                ) {
                    exportMIDI()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("导出曲谱")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(score.title)
                .font(.headline)
            Text("\(score.measures.count) 小节 · \(score.allNotes.count) 个音符")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }

    private func exportOption(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func exportMusicXML() {
        let xml = musicXMLExporter.export(score: score)
        guard let data = xml.data(using: .utf8) else { return }

        let filename = "\(score.title).musicxml"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: tempURL)
            showShareSheet(items: [tempURL])
        } catch {
            print("Export error: \(error)")
        }
    }

    private func exportMIDI() {
        let data = midiExporter.export(score: score)
        let filename = "\(score.title).mid"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: tempURL)
            showShareSheet(items: [tempURL])
        } catch {
            print("Export error: \(error)")
        }
    }

    private func showShareSheet(items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            }

            topVC.present(activityVC, animated: true)
        }
    }
}
