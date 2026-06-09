import SwiftData
import Foundation

final class PersistenceController {
    static let shared = PersistenceController()
    static let preview = PersistenceController(inMemory: true)

    let container: ModelContainer

    init(inMemory: Bool = false) {
        let schema = Schema([PracticeSession.self])
        let config: ModelConfiguration

        if inMemory {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
