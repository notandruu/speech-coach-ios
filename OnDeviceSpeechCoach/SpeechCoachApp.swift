import SwiftUI
import SwiftData

@main
struct SpeechCoachApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .modelContainer(PersistenceController.shared.container)
        }
    }
}
