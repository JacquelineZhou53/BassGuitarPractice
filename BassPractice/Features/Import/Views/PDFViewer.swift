import SwiftUI
import PDFKit

struct PDFDocumentItem: Identifiable {
    let id = UUID()
    let url: URL
    let title: String
}

struct PDFViewer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground

        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            uiView.document = document
        }
    }
}

struct PDFImportView: View {
    @State private var selectedPDF: URL?
    @State private var showingFilePicker = false
    @State private var errorMessage: String?
    @State private var instrumentType: InstrumentType = .bass

    var onImport: ((URL, InstrumentType) -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Picker("乐器类型", selection: $instrumentType) {
                ForEach(InstrumentType.allCases, id: \.self) { instrument in
                    Text(instrument.displayName).tag(instrument)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if let url = selectedPDF {
                PDFViewer(url: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(8)

                HStack {
                    Button("选择其他文件") {
                        showingFilePicker = true
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("导入") {
                        onImport?(url, instrumentType)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("选择 PDF 曲谱文件")
                        .font(.headline)

                    Text("支持导入 PDF 格式的乐谱文件")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("选择文件") {
                        showingFilePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedPDF = url
                    errorMessage = nil
                }
            case .failure(let error):
                errorMessage = "选择文件失败: \(error.localizedDescription)"
            }
        }
    }
}
