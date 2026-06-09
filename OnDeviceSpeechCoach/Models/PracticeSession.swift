import Foundation
import SwiftData

@Model
final class PracticeSession {
    @Attribute(.unique) var id: UUID
    var promptTitle: String
    var promptText: String
    var createdAt: Date
    var durationSeconds: Double

    var overallScore: Double
    var paceScore: Double
    var pauseScore: Double
    var clarityScore: Double
    var volumeConsistencyScore: Double

    var wordsPerMinute: Double
    var pauseCount: Int
    var longestPauseSeconds: Double
    var speechActivityRatio: Double

    var feedbackSummary: String
    var audioLocalURL: URL?

    init(
        id: UUID = UUID(),
        promptTitle: String,
        promptText: String,
        createdAt: Date = Date(),
        durationSeconds: Double,
        overallScore: Double,
        paceScore: Double,
        pauseScore: Double,
        clarityScore: Double,
        volumeConsistencyScore: Double,
        wordsPerMinute: Double,
        pauseCount: Int,
        longestPauseSeconds: Double,
        speechActivityRatio: Double,
        feedbackSummary: String,
        audioLocalURL: URL? = nil
    ) {
        self.id = id
        self.promptTitle = promptTitle
        self.promptText = promptText
        self.createdAt = createdAt
        self.durationSeconds = durationSeconds
        self.overallScore = overallScore
        self.paceScore = paceScore
        self.pauseScore = pauseScore
        self.clarityScore = clarityScore
        self.volumeConsistencyScore = volumeConsistencyScore
        self.wordsPerMinute = wordsPerMinute
        self.pauseCount = pauseCount
        self.longestPauseSeconds = longestPauseSeconds
        self.speechActivityRatio = speechActivityRatio
        self.feedbackSummary = feedbackSummary
        self.audioLocalURL = audioLocalURL
    }
}

extension PracticeSession {
    static var preview: PracticeSession {
        PracticeSession(
            promptTitle: "Tell Me About Yourself",
            promptText: "I am a software engineer...",
            durationSeconds: 28.5,
            overallScore: 78.0,
            paceScore: 82.0,
            pauseScore: 74.0,
            clarityScore: 80.0,
            volumeConsistencyScore: 70.0,
            wordsPerMinute: 145.0,
            pauseCount: 3,
            longestPauseSeconds: 1.2,
            speechActivityRatio: 0.88,
            feedbackSummary: "Good pace. Try reducing long pauses between sentences."
        )
    }
}
