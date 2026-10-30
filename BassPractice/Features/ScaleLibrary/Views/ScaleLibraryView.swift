import SwiftUI

struct ScaleLibraryView: View {
    @State private var viewModel = ScaleLibraryViewModel()
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    private var instrumentPicker: some View {
        Picker("乐器", selection: $viewModel.instrumentType) {
            ForEach(InstrumentType.allCases, id: \.self) { instrument in
                Text(instrument.displayName).tag(instrument)
            }
        }
        .pickerStyle(.segmented)
    }

    private var iPadLayout: some View {
        VStack(spacing: 0) {
            instrumentPicker
                .padding(.horizontal)
                .padding(.vertical, 8)

            HStack(spacing: 0) {
            // Sidebar - Categories
            sidebarView
                .frame(width: 200)
                .border(Color.gray.opacity(0.2), width: 0.5)

            // Content - Scales list
            scaleListView
                .frame(width: 250)
                .border(Color.gray.opacity(0.2), width: 0.5)

            // Detail
            detailView
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var detailView: some View {
        Group {
            if let chord = viewModel.selectedGuitarChord {
                ChordPracticeView(chord: chord)
            } else if viewModel.selectedScale != nil && viewModel.isSelectedComplete {
                ScaleDetailView(viewModel: viewModel)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("选择音阶和根音开始练习")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var iPhoneLayout: some View {
        NavigationStack {
            categoryListView
                .navigationTitle("练习库")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        instrumentPicker
                            .frame(maxWidth: 200)
                    }
                }
                .navigationDestination(for: ScaleCategory.self) { category in
                    scaleListViewForCategory(category)
                        .navigationTitle(category.displayName)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .navigationDestination(for: Scale.self) { scale in
                    ScaleDetailView(viewModel: viewModel, initialScale: scale)
                        .navigationTitle(scale.name)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .navigationDestination(for: GuitarChord.self) { chord in
                    ChordPracticeView(chord: chord)
                        .navigationTitle(chord.name)
                        .navigationBarTitleDisplayMode(.inline)
                }
        }
    }

    private var categoryListView: some View {
        List {
            Section("音阶类型") {
                let categories = ScaleCategory.allCases.filter {
                    $0 != .arpeggio && $0 != .chord
                }
                ForEach(categories, id: \.self) { category in
                    NavigationLink(value: category) {
                        HStack {
                            Text(category.displayName)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section("琶音") {
                ForEach(viewModel.arpeggioScales) { scale in
                    NavigationLink(value: scale) {
                        HStack {
                            Text(scale.name)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if viewModel.instrumentType == .guitar {
                Section("和弦") {
                    ForEach(GuitarChord.ChordCategory.allCases) { category in
                        DisclosureGroup(category.rawValue) {
                            ForEach(GuitarChord.chords(in: category)) { chord in
                                NavigationLink(value: chord) {
                                    HStack {
                                        Text(chord.name)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func scaleListViewForCategory(_ category: ScaleCategory) -> some View {
        let scales: [Scale]
        if category == .arpeggio {
            scales = viewModel.arpeggioScales
        } else {
            scales = Scale.allScales.filter { $0.category == category }
        }

        return List {
            ForEach(scales) { scale in
                NavigationLink(value: scale) {
                    HStack {
                        Text(scale.name)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var sidebarView: some View {
        List {
            Section("音阶类型") {
                let categories = ScaleCategory.allCases.filter {
                    $0 != .arpeggio && $0 != .chord
                }
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        print("DEBUG: Clicked category \(category.displayName)")
                        selectCategory(category)
                        print("DEBUG: After select, selectedCategory = \(viewModel.selectedCategory?.displayName ?? "nil")")
                    }) {
                        HStack {
                            Text(category.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            if viewModel.selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("琶音类型") {
                Button(action: {
                    print("DEBUG: Clicked arpeggio category")
                    selectCategory(.arpeggio)
                    print("DEBUG: After select, selectedCategory = \(viewModel.selectedCategory?.displayName ?? "nil")")
                }) {
                    HStack {
                        Text("琶音")
                            .foregroundColor(.primary)
                        Spacer()
                        if viewModel.selectedCategory == .arpeggio {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if viewModel.instrumentType == .guitar {
                Section("和弦") {
                    ForEach(GuitarChord.ChordCategory.allCases) { category in
                        DisclosureGroup(category.rawValue) {
                            ForEach(GuitarChord.chords(in: category)) { chord in
                                Button {
                                    viewModel.selectGuitarChord(chord)
                                } label: {
                                    HStack {
                                        Text(chord.name)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if viewModel.selectedGuitarChord?.id == chord.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func selectCategory(_ category: ScaleCategory) {
        viewModel.selectedCategory = category
        viewModel.selectedScale = nil
        viewModel.selectedRoot = nil
        viewModel.selectedFingeringIndex = 0
        viewModel.fingerings = []
    }

    private var scaleListView: some View {
        let scales = viewModel.scalesInCategory

        return List {
            if scales.isEmpty {
                Section {
                    Text("请先选择左侧的分类")
                        .foregroundColor(.secondary)
                }
            } else {
                Section(viewModel.selectedCategory?.displayName ?? "音阶") {
                    ForEach(scales) { scale in
                        Button {
                            viewModel.selectScale(scale)
                        } label: {
                            HStack {
                                Text(scale.name)
                                Spacer()
                                if viewModel.selectedScale?.id == scale.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
