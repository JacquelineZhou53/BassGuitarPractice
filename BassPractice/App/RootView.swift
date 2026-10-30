import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable, Identifiable {
    case scaleLibrary = "音阶库"
    case fretboard = "指板"
    case editor = "编辑器"
    case importFiles = "导入"
    case practice = "练习"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .scaleLibrary: return "music.note.list"
        case .fretboard: return "guitars"
        case .editor: return "pencil.and.outline"
        case .importFiles: return "square.and.arrow.down"
        case .practice: return "metronome"
        }
    }
}

struct RootView: View {
    @State private var selectedTab: AppTab = .scaleLibrary
    @State private var presentedPDF: PDFDocumentItem?
    @State private var importError: String?
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if sizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .onOpenURL { url in
            handleIncomingURL(url)
        }
        .sheet(item: $presentedPDF) { item in
            NavigationView {
                PDFViewer(url: item.url)
                    .navigationTitle(item.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("完成") { presentedPDF = nil }
                        }
                    }
            }
        }
        .alert("导入失败", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("好", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }

    @MainActor
    private func handleIncomingURL(_ url: URL) {
        do {
            let score = try ImportManager.makeScore(from: url)
            try ImportManager.persist(score, in: modelContext)
            selectedTab = .importFiles

            if score.sourceType == .pdfImport,
               let relativePath = score.sourceFileURL {
                presentedPDF = PDFDocumentItem(
                    url: ImportedFileStore.url(forRelativePath: relativePath),
                    title: score.title
                )
            }
        } catch {
            importError = error.localizedDescription
        }
    }

    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    tabContent(for: tab)
                }
                .tabItem {
                    Label(tab.rawValue, systemImage: tab.icon)
                }
                .tag(tab)
            }
        }
    }

    private var iPadLayout: some View {
        NavigationSplitView {
            List {
                ForEach(AppTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                    .tag(tab)
                }
            }
            .navigationTitle("贝斯练习")
        } detail: {
            NavigationStack {
                tabContent(for: selectedTab)
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .scaleLibrary:
            ScaleLibraryView()
        case .fretboard:
            InteractiveFretboardView()
        case .editor:
            EditorHomeView()
        case .importFiles:
            ImportView()
        case .practice:
            PracticeHomeView()
        }
    }
}

struct InteractiveFretboardView: View {
    @State private var viewModel = FretboardViewModel()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("五弦贝斯指板")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }

            Text("点击选择音符，拖动到不同弦上可自动计算品格")
                .font(.caption)
                .foregroundColor(.secondary)

            FretboardView(
                config: viewModel.config,
                notes: $viewModel.notes,
                selectedNoteID: $viewModel.selectedNoteID,
                highlightNotes: viewModel.highlightNotes,
                showFingerNumbers: viewModel.showFingerNumbers,
                noteColor: viewModel.noteColor,
                isEditable: true
            )
            .frame(height: 200)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)

            HStack(spacing: 12) {
                Button {
                    viewModel.showFingerNumbers.toggle()
                } label: {
                    Label(viewModel.showFingerNumbers ? "隐藏指法" : "显示指法",
                          systemImage: viewModel.showFingerNumbers ? "hand.tap" : "hand.tap.fill")
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.clearNotes()
                } label: {
                    Label("清除", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            if let selectedID = viewModel.selectedNoteID,
               let note = viewModel.notes.first(where: { $0.id == selectedID }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("选中音符")
                        .font(.headline)
                    HStack {
                        Text("音高: \(note.pitch.displayName)")
                        Text("弦: \(note.position.stringIndex + 1)")
                        Text("品: \(note.position.fretNumber)")
                    }
                    .font(.subheadline)

                    Text("移动到:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        ForEach(0..<viewModel.config.stringCount, id: \.self) { stringIndex in
                            Button {
                                viewModel.moveSelectedNote(to: stringIndex)
                            } label: {
                                VStack {
                                    Text("\(stringIndex + 1)弦")
                                        .font(.caption2)
                                    if let fret = viewModel.solver.fretForPitch(note.pitch, onString: stringIndex) {
                                        Text("\(fret)品")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    } else {
                                        Text("不可用")
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(6)
                                .background(note.position.stringIndex == stringIndex ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("指板")
    }
}

struct PracticeHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredScore.modifyTime, order: .reverse) private var storedScores: [StoredScore]
    @State private var selectedScore: Score?
    @State private var showStandaloneMetronome = false

    private var practiceScores: [StoredScore] {
        storedScores.filter { !$0.isPDF && $0.hasNotation }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showStandaloneMetronome = true
                    } label: {
                        Label("独立节拍器", systemImage: "metronome")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }

                if !practiceScores.isEmpty {
                    Section("选择曲谱练习") {
                        ForEach(practiceScores, id: \.id) { stored in
                            Button {
                                selectedScore = stored.toScore()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stored.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    HStack {
                                        Text("♩=\(stored.tempo)")
                                        Text("\(stored.measuresData.count > 0 ? "有" : "无")音符")
                                        Spacer()
                                        Image(systemName: "play.circle")
                                            .foregroundColor(.blue)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "music.note.list")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("暂无曲谱")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("在编辑器中创建曲谱或导入 MIDI 文件后，即可在此练习")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("练习")
            .navigationDestination(item: $selectedScore) { score in
                PracticeSessionView(viewModel: PracticeSessionViewModel(
                    score: score,
                    onScoreChanged: { updatedScore in
                        guard let stored = storedScores.first(where: { $0.id == updatedScore.id }) else { return }
                        stored.update(from: updatedScore)
                        try? modelContext.save()
                    }
                ))
            }
            .sheet(isPresented: $showStandaloneMetronome) {
                StandaloneMetronomeView()
            }
        }
    }
}

struct StandaloneMetronomeView: View {
    @State private var metronome = MetronomeEngine()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                MetronomeView(metronome: metronome)
                    .padding()
                Spacer()
            }
            .navigationTitle("节拍器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        metronome.stop()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredScore.modifyTime, order: .reverse) private var storedScores: [StoredScore]

    @State private var importedScore: Score?
    @State private var importedPDF: URL?
    @State private var previewScore: Score?
    @State private var presentedPDF: PDFDocumentItem?
    @State private var errorMessage: String?

    @State private var showingMIDIPicker = false
    @State private var showingPDFPicker = false
    @State private var showingMSCZPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                importOptionsSection

                if let score = importedScore {
                    importedScoreSection(score)
                }

                if let pdf = importedPDF {
                    importedPDFSection(pdf)
                }

                if !storedScores.isEmpty {
                    storedScoresSection
                }
            }
            .padding()
        }
        .navigationTitle("导入曲谱")
        .sheet(isPresented: $showingMIDIPicker) {
            MIDIFilePicker { score, tabScore, instrumentType, url in
                handleImportedScore(score, tabScore: tabScore, instrumentType: instrumentType, sourceURL: url)
            }
        }
        .sheet(isPresented: $showingPDFPicker) {
            PDFFilePicker { url, instrumentType in
                handleImportedPDF(url, instrumentType: instrumentType)
            }
        }
        .sheet(isPresented: $showingMSCZPicker) {
            MSCZFilePicker { score, tabScore, instrumentType, url in
                handleImportedScore(score, tabScore: tabScore, instrumentType: instrumentType, sourceURL: url)
            }
        }
        .sheet(item: $presentedPDF) { item in
            NavigationView {
                PDFViewer(url: item.url)
                    .navigationTitle(item.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("完成") { presentedPDF = nil }
                        }
                    }
            }
        }
        .sheet(item: $previewScore) { score in
            NavigationView {
                DualScoreView(
                    score: score,
                    onScoreChanged: { updatedScore in
                        saveScore(updatedScore)
                    }
                )
                .navigationTitle(score.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完成") { previewScore = nil }
                    }
                }
            }
        }
        .alert("导入失败", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var importOptionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("导入选项")
                    .font(.headline)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                importButton(
                    title: "MIDI",
                    icon: "music.note",
                    color: .blue
                ) {
                    showingMIDIPicker = true
                }

                importButton(
                    title: "PDF",
                    icon: "doc.text",
                    color: .red
                ) {
                    showingPDFPicker = true
                }

                importButton(
                    title: "MSCZ",
                    icon: "music.note.list",
                    color: .purple
                ) {
                    showingMSCZPicker = true
                }
            }
        }
    }

    private func importButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func importedScoreSection(_ score: Score) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("已导入: \(score.title)")
                    .font(.headline)
                Spacer()
                Text(score.instrumentType.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }

            DualScoreView(
                score: score,
                onScoreChanged: { updatedScore in
                    importedScore = updatedScore
                    saveScore(updatedScore)
                }
            )
            .frame(height: 500)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)

            Button("清除预览") {
                importedScore = nil
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }

    private func importedPDFSection(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PDF: \(url.lastPathComponent)")
                    .font(.headline)
                Spacer()
                Button("查看") {
                    presentedPDF = PDFDocumentItem(url: url, title: url.lastPathComponent)
                }
                .buttonStyle(.bordered)
            }

            Button("清除预览") {
                importedPDF = nil
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private var storedScoresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            scoresByInstrumentSection(instrumentType: .bass, title: "贝斯曲谱")
            scoresByInstrumentSection(instrumentType: .guitar, title: "吉他曲谱")
        }
    }

    private func scoresByInstrumentSection(instrumentType: InstrumentType, title: String) -> some View {
        let filtered = storedScores.filter { $0.instrumentType == instrumentType }

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }

            if filtered.isEmpty {
                Text("暂无\(title)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(filtered, id: \.id) { stored in
                        HStack(spacing: 12) {
                            Image(systemName: iconName(for: stored))
                                .font(.title3)
                                .foregroundColor(color(for: stored))
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(stored.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Text("\(sourceLabel(for: stored)) · \(stored.modifyTime, style: .date)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button("打开") {
                                open(stored)
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)

                            Button(role: .destructive) {
                                delete(stored)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 10)

                        if stored.id != filtered.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
    }

    private func iconName(for stored: StoredScore) -> String {
        switch stored.sourceType {
        case .pdfImport: return "doc.text"
        case .midiImport: return "music.note"
        case .msczImport: return "music.note.list"
        default: return "music.note"
        }
    }

    private func color(for stored: StoredScore) -> Color {
        switch stored.sourceType {
        case .pdfImport: return .red
        case .midiImport: return .blue
        case .msczImport: return .purple
        default: return .blue
        }
    }

    private func sourceLabel(for stored: StoredScore) -> String {
        switch stored.sourceType {
        case .pdfImport: return "PDF"
        case .midiImport: return "MIDI"
        case .msczImport: return "MSCZ"
        default: return "曲谱"
        }
    }

    private func open(_ stored: StoredScore) {
        if stored.isPDF {
            guard let relativePath = stored.sourceFileURL else { return }
            let url = ImportedFileStore.url(forRelativePath: relativePath)
            guard FileManager.default.fileExists(atPath: url.path) else {
                errorMessage = "PDF 文件已不存在，请重新导入。"
                return
            }
            presentedPDF = PDFDocumentItem(url: url, title: stored.title)
        } else {
            previewScore = stored.toScore()
        }
    }

    private func delete(_ stored: StoredScore) {
        if let relativePath = stored.sourceFileURL {
            ImportedFileStore.delete(relativePath: relativePath)
        }
        modelContext.delete(stored)
        try? modelContext.save()
    }

    @MainActor
    private func handleImportedScore(_ importedScore: Score, tabScore: Score?, instrumentType: InstrumentType, sourceURL: URL?) {
        var score = importedScore
        score.instrumentType = instrumentType

        if let tabScore {
            score = mergeTabPositions(standard: score, tab: tabScore)
        }

        if let sourceURL {
            let didAccess = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }
            if let relativePath = try? ImportedFileStore.copyImportedFile(from: sourceURL) {
                score.sourceFileURL = relativePath
            }
        }

        do {
            try ImportManager.persist(score, in: modelContext)
            self.importedScore = score
            importedPDF = nil
        } catch {
            errorMessage = "保存曲谱失败：\(error.localizedDescription)"
        }
    }

    private func mergeTabPositions(standard: Score, tab: Score) -> Score {
        var merged = standard
        for mi in 0..<merged.measures.count {
            guard mi < tab.measures.count else { break }
            let tabNotes = tab.measures[mi].notes
            for ni in 0..<merged.measures[mi].notes.count {
                guard ni < tabNotes.count, let pos = tabNotes[ni].fretboardPosition else { continue }
                merged.measures[mi].notes[ni].fretboardPosition = pos
            }
        }
        return merged
    }

    @MainActor
    private func handleImportedPDF(_ url: URL, instrumentType: InstrumentType) {
        do {
            let score = try ImportManager.makeScore(from: url, instrumentType: instrumentType)
            try ImportManager.persist(score, in: modelContext)
            importedScore = nil
            if let relativePath = score.sourceFileURL {
                let copiedURL = ImportedFileStore.url(forRelativePath: relativePath)
                importedPDF = copiedURL
                presentedPDF = PDFDocumentItem(url: copiedURL, title: score.title)
            }
        } catch {
            errorMessage = "保存 PDF 失败：\(error.localizedDescription)"
        }
    }

    @MainActor
    private func saveScore(_ score: Score) {
        guard let stored = storedScores.first(where: { $0.id == score.id }) else { return }
        stored.update(from: score)
        try? modelContext.save()
    }
}

struct MIDIFilePicker: View {
    var onPick: (Score, Score?, InstrumentType, URL?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            MIDIImportView(onImport: { score, tabScore, instrumentType, url in
                onPick(score, tabScore, instrumentType, url)
                dismiss()
            })
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

struct PDFFilePicker: View {
    var onPick: (URL, InstrumentType) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            PDFImportView(onImport: { url, instrumentType in
                onPick(url, instrumentType)
                dismiss()
            })
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

struct MSCZFilePicker: View {
    var onPick: (Score, Score?, InstrumentType, URL?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            MSCZImportView(onImport: { score, tabScore, instrumentType, url in
                onPick(score, tabScore, instrumentType, url)
                dismiss()
            })
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

struct EditorHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredScore.modifyTime, order: .reverse) private var storedScores: [StoredScore]
    @State private var editingScore: Score?
    @State private var showNewEditor = false

    private var editableScores: [StoredScore] {
        storedScores.filter { !$0.isPDF }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showNewEditor = true
                    } label: {
                        Label("新建曲谱", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }

                if !editableScores.isEmpty {
                    Section("我的曲谱") {
                        ForEach(editableScores, id: \.id) { stored in
                            Button {
                                editingScore = stored.toScore()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stored.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    HStack {
                                        Text(stored.composer.isEmpty ? "未知" : stored.composer)
                                        Spacer()
                                        Text(stored.modifyTime, style: .date)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                modelContext.delete(editableScores[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("曲谱编辑器")
            .navigationDestination(item: $editingScore) { score in
                ScoreEditorView(score: score)
            }
            .navigationDestination(isPresented: $showNewEditor) {
                ScoreEditorView()
            }
        }
    }
}
