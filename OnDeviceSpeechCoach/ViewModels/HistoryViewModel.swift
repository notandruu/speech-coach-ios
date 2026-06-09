import Foundation
import SwiftData

@Observable
@MainActor
final class HistoryViewModel {
    var sessions: [PracticeSession] = []
    var averageScore: Double?
    var bestScore: Double?
    var mostCommonWeakArea: String?
    var isLoading = false

    private var store: SessionStore?

    func configure(context: ModelContext) {
        store = SessionStore(context: context)
        Task { await refresh() }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        guard let store else { return }
        do {
            sessions = try store.fetchAll()
            averageScore = try store.averageScore()
            bestScore = try store.bestScore()
            mostCommonWeakArea = computeWeakArea()
        } catch {
            sessions = []
        }
    }

    func deleteAll() async {
        guard let store else { return }
        do {
            try store.deleteAll()
            sessions = []
            averageScore = nil
            bestScore = nil
            mostCommonWeakArea = nil
        } catch {
            // Silently fail — non-destructive from user's perspective
        }
    }

    private func computeWeakArea() -> String? {
        guard !sessions.isEmpty else { return nil }
        let avgPace = sessions.map(\.paceScore).reduce(0, +) / Double(sessions.count)
        let avgPause = sessions.map(\.pauseScore).reduce(0, +) / Double(sessions.count)
        let avgClarity = sessions.map(\.clarityScore).reduce(0, +) / Double(sessions.count)
        let avgVolume = sessions.map(\.volumeConsistencyScore).reduce(0, +) / Double(sessions.count)

        let scores = [("Pace", avgPace), ("Pauses", avgPause), ("Clarity", avgClarity), ("Volume", avgVolume)]
        return scores.min(by: { $0.1 < $1.1 })?.0
    }
}
