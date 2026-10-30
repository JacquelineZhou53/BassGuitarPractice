import SwiftUI
import SwiftData

@main
struct BassPracticeApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [StoredScore.self, ScoreLibrary.self])
    }
}
