import Foundation

struct FluencyScorer {
    private let inputBuilder = ModelInputBuilder()
    private let modelRunner = FluencyModelRunner()

    func score(features: AudioFeatures, prediction: ModelPrediction) -> ScoreBreakdown {
        let pace = paceScore(wpm: features.estimatedWordsPerMinute)
        let pauses = pauseScore(
            pauseCount: features.pauseCount,
            longestPause: features.longestPauseSeconds,
            silenceRatio: features.silenceRatio
        )
        let clarity = prediction.clarityScore * 100
        let volume = volumeConsistencyScore(variance: features.volumeVariance)

        let overall = (
            AppConstants.Scoring.paceWeight * pace +
            AppConstants.Scoring.pauseWeight * pauses +
            AppConstants.Scoring.clarityWeight * clarity +
            AppConstants.Scoring.volumeConsistencyWeight * volume
        ).clamped(to: 0...100)

        let feedback = generateFeedback(
            wpm: features.estimatedWordsPerMinute,
            pauseCount: features.pauseCount,
            longestPause: features.longestPauseSeconds,
            clarityScore: prediction.clarityScore,
            volumeVariance: features.volumeVariance
        )

        return ScoreBreakdown(
            overall: overall.rounded(),
            pace: pace.clamped(to: 0...100).rounded(),
            pauses: pauses.clamped(to: 0...100).rounded(),
            clarity: clarity.clamped(to: 0...100).rounded(),
            volumeConsistency: volume.clamped(to: 0...100).rounded(),
            confidence: prediction.confidence,
            wordsPerMinute: features.estimatedWordsPerMinute,
            pauseCount: features.pauseCount,
            longestPauseSeconds: features.longestPauseSeconds,
            durationSeconds: features.durationSeconds,
            feedback: feedback
        )
    }

    // MARK: - Component scores

    func paceScore(wpm: Double) -> Double {
        guard wpm > 0 else { return 40 }
        let ideal = AppConstants.Scoring.idealWPMMid
        let deviation = abs(wpm - ideal)
        return max(0, 100 - deviation * 0.8)
    }

    func pauseScore(pauseCount: Int, longestPause: Double, silenceRatio: Double) -> Double {
        var score = 100.0
        // Penalize each long pause
        score -= Double(pauseCount) * 5
        // Penalize unusually long single pause
        if longestPause > 2.0 { score -= (longestPause - 2.0) * 10 }
        // Penalize high silence ratio
        if silenceRatio > 0.4 { score -= (silenceRatio - 0.4) * 60 }
        return score
    }

    func volumeConsistencyScore(variance: Double) -> Double {
        // Normalized: lower variance → higher score
        max(0, 100 - variance * 200)
    }

    // MARK: - Feedback generation

    private func generateFeedback(
        wpm: Double,
        pauseCount: Int,
        longestPause: Double,
        clarityScore: Double,
        volumeVariance: Double
    ) -> [SpeechFeedback] {
        var items = [SpeechFeedback]()

        // Pace
        if wpm == 0 {
            items.append(.init(category: .pace, sentiment: .neutral, message: "Not enough speech detected to estimate pace."))
        } else if wpm > AppConstants.Scoring.idealWPMHigh + 30 {
            items.append(.init(category: .pace, sentiment: .negative, message: "Your pace was too fast. Try slowing down and pausing after key points."))
        } else if wpm > AppConstants.Scoring.idealWPMHigh {
            items.append(.init(category: .pace, sentiment: .negative, message: "Your pace was slightly fast. Try adding a half-second pause after each sentence."))
        } else if wpm < AppConstants.Scoring.idealWPMLow - 30 {
            items.append(.init(category: .pace, sentiment: .negative, message: "Your pace was too slow. Try reading in full phrases rather than word-by-word."))
        } else if wpm < AppConstants.Scoring.idealWPMLow {
            items.append(.init(category: .pace, sentiment: .neutral, message: "Your pace was slightly slow. Try picking up momentum between phrases."))
        } else {
            items.append(.init(category: .pace, sentiment: .positive, message: "Your pace was steady and easy to follow."))
        }

        // Pauses
        if pauseCount > 6 || longestPause > 3.0 {
            items.append(.init(category: .pauses, sentiment: .negative, message: "You had several long pauses. Try previewing the next phrase before finishing the current one."))
        } else if pauseCount > 3 {
            items.append(.init(category: .pauses, sentiment: .neutral, message: "A few noticeable pauses. Try reading the full prompt once before recording."))
        } else {
            items.append(.init(category: .pauses, sentiment: .positive, message: "Your pauses were well-spaced and made the reading sound natural."))
        }

        // Clarity
        if clarityScore < 0.5 {
            items.append(.init(category: .clarity, sentiment: .negative, message: "Some sections were quiet or unclear. Try keeping your phone 8–12 inches away and speaking directly."))
        } else if clarityScore < 0.75 {
            items.append(.init(category: .clarity, sentiment: .neutral, message: "Clarity was moderate. Ensure a quiet environment and consistent microphone distance."))
        } else {
            items.append(.init(category: .clarity, sentiment: .positive, message: "Your clarity was strong. Most of the recording had stable, clear sound."))
        }

        // Volume
        if volumeVariance > 0.3 {
            items.append(.init(category: .volume, sentiment: .negative, message: "Your volume varied significantly. Try keeping a steady distance from the microphone."))
        } else if volumeVariance > 0.15 {
            items.append(.init(category: .volume, sentiment: .neutral, message: "Volume varied slightly. Try keeping a consistent distance from the mic."))
        } else {
            items.append(.init(category: .volume, sentiment: .positive, message: "Your volume was consistent throughout."))
        }

        return items
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        max(range.lowerBound, min(range.upperBound, self))
    }
}
