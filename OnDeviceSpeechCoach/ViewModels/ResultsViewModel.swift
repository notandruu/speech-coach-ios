import Foundation

@Observable
@MainActor
final class ResultsViewModel {
    let breakdown: ScoreBreakdown
    let prompt: PracticePrompt

    var animateScores = false

    init(breakdown: ScoreBreakdown, prompt: PracticePrompt) {
        self.breakdown = breakdown
        self.prompt = prompt
    }

    func onAppear() {
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            animateScores = true
        }
    }
}
