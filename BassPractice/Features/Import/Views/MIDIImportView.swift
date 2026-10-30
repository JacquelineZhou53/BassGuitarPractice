import SwiftUI
import UniformTypeIdentifiers

struct MIDIImportView: View {
    @State private var selectedMIDI: URL?
    @State private var showingFilePicker = false
    @State private var errorMessage: String?
    @State private var parsedScore: Score?
    @State private var parsedTabScore: Score?
    @State private var isParsing = false
    @State private var instrumentType: InstrumentType = .bass

    var onImport: ((Score, Score?, InstrumentType, URL?) -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Picker("乐器类型", selection: $instrumentType) {
                ForEach(InstrumentType.allCases, id: \.self) { instrument in
                    Text(instrument.displayName).tag(instrument)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if let score = parsedScore {
                scorePreview(score)
            } else if isParsing {
                parsingView
            } else {
                selectFileView
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "mid")!, UTType(filenameExtension: "midi")!],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    parseMIDI(url: url)
                }
            case .failure(let error):
                errorMessage = "选择文件失败: \(error.localizedDescription)"
            }
        }
    }

    private var selectFileView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("选择 MIDI 文件")
                .font(.headline)

            Text("支持导入 .mid/.midi 格式的 MIDI 文件")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("选择文件") {
                showingFilePicker = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var parsingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("正在解析 MIDI 文件...")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func scorePreview(_ score: Score) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(score.title)
                        .font(.headline)
                    Text("\(score.measures.count) 小节 · \(score.allNotes.count) 个音符 · ♩=\(score.tempo)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            NotationContainerView(score: score)
                .frame(height: 200)

            HStack {
                Button("重新选择") {
                    parsedScore = nil
                    selectedMIDI = nil
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("导入") {
                    onImport?(score, parsedTabScore, instrumentType, selectedMIDI)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private func parseMIDI(url: URL) {
        isParsing = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: url)
                let parser = MIDIParser(data: data)
                let midiFile = try parser.parse()

                let converter = MIDIToScoreConverter(ticksPerQuarterNote: midiFile.ticksPerQuarterNote)
                let score = converter.convert(midiFile, title: url.deletingPathExtension().lastPathComponent)
                
                let config = instrumentType.defaultFretboardConfig
                let tabGenerator = TabGenerator(config: config)
                let tabScore = tabGenerator.generateTab(for: score)

                DispatchQueue.main.async {
                    self.parsedScore = score
                    self.parsedTabScore = tabScore
                    self.selectedMIDI = url
                    self.isParsing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "解析 MIDI 失败: \(error.localizedDescription)"
                    self.isParsing = false
                }
            }
        }
    }
}

struct FileImportView: View {
    @State private var selectedTab = 0

    var onMIDIImport: ((Score, Score?, InstrumentType, URL?) -> Void)?
    var onPDFImport: ((URL, InstrumentType) -> Void)?
    var onMSCZImport: ((Score, Score?, InstrumentType, URL?) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Picker("导入类型", selection: $selectedTab) {
                Text("MIDI").tag(0)
                Text("PDF").tag(1)
                Text("MSCZ").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                MIDIImportView(onImport: onMIDIImport)
            } else if selectedTab == 1 {
                PDFImportView(onImport: onPDFImport)
            } else {
                MSCZImportView(onImport: onMSCZImport)
            }
        }
        .navigationTitle("导入曲谱")
    }
}
