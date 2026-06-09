import SwiftData
import Foundation

@MainActor
final class SessionStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ session: PracticeSession) throws {
        context.insert(session)
        try context.save()
    }

    func fetchAll() throws -> [PracticeSession] {
        let descriptor = FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func deleteAll() throws {
        let sessions = try fetchAll()
        for session in sessions {
            context.delete(session)
        }
        try context.save()
    }

    func averageScore() throws -> Double? {
        let sessions = try fetchAll()
        guard !sessions.isEmpty else { return nil }
        return sessions.map(\.overallScore).reduce(0, +) / Double(sessions.count)
    }

    func bestScore() throws -> Double? {
        let sessions = try fetchAll()
        return sessions.map(\.overallScore).max()
    }
}
