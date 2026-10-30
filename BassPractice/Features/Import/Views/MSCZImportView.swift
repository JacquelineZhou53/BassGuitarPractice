import SwiftUI
import UniformTypeIdentifiers

struct MSCZImportView: View {
    @State private var selectedURL: URL?
    @State private var showingFilePicker = false
    @State private var errorMessage: String?
    @State private var parsedResult: MSCZParseResult?
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

            if let result = parsedResult {
                scorePreview(result)
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
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    parseMSCZ(url: url)
                }
            case .failure(let error):
                errorMessage = "选择文件失败: \(error.localizedDescription)"
            }
        }
    }

    private var allowedTypes: [UTType] {
        var types: [UTType] = [UTType(importedAs: "com.basspractice.mscz")]
        if let mscx = UTType(filenameExtension: "mscx") {
            types.append(mscx)
        }
        return types
    }

    private var selectFileView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("选择 MuseScore 文件")
                .font(.headline)

            Text("支持 .mscz / .mscx，导入后会转换为 App 内五线谱和指板")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

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

            Text("正在解析 MuseScore 文件...")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func scorePreview(_ result: MSCZParseResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.standardScore.title)
                    .font(.headline)
                Text("\(result.standardScore.measures.count) 小节 · \(result.standardScore.allNotes.filter { !$0.isRest }.count) 个音符 · ♩=\(result.standardScore.tempo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if result.hasTabStaff {
                    Text("已包含 TAB 谱")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            NotationContainerView(score: result.standardScore)
                .frame(height: 200)

            HStack {
                Button("重新选择") {
                    parsedResult = nil
                    selectedURL = nil
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("导入") {
                    onImport?(result.standardScore, result.tabScore, instrumentType, selectedURL)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private func parseMSCZ(url: URL) {
        isParsing = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let didAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if didAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let data = try Data(contentsOf: url)
                let result = try MSCZParser().parse(
                    data: data,
                    title: url.deletingPathExtension().lastPathComponent
                )

                DispatchQueue.main.async {
                    self.parsedResult = result
                    self.selectedURL = url
                    self.isParsing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "解析 MuseScore 文件失败: \(error.localizedDescription)"
                    self.isParsing = false
                }
            }
        }
    }
}
