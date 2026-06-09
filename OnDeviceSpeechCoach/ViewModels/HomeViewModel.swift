import Foundation
import SwiftData

@Observable
@MainActor
final class HomeViewModel {
    var recentSessions: [PracticeSession] = []
    var averageScore: Double?
    var bestScore: Double?
    var dailyPrompt: PracticePrompt = PracticePrompt.samples[0]
    var isLoading = false

    private var store: SessionStore?

    func configure(context: ModelContext) {
        store = SessionStore(context: context)
        loadDailyPrompt()
        Task { await refresh() }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        guard let store else { return }
        do {
            let all = try store.fetchAll()
            recentSessions = Array(all.prefix(3))
            averageScore = try store.averageScore()
            bestScore = try store.bestScore()
        } catch {
            // Non-critical — UI shows empty state
        }
    }

    private func loadDailyPrompt() {
        // Rotate prompts by day-of-year for variety
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let idx = (dayOfYear - 1) % PracticePrompt.samples.count
        dailyPrompt = PracticePrompt.samples[idx]
    }
}
