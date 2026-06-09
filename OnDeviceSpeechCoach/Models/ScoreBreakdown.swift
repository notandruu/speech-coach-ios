import Foundation

struct ScoreBreakdown: Hashable {
    let overall: Double
    let pace: Double
    let pauses: Double
    let clarity: Double
    let volumeConsistency: Double
    let confidence: Double
    let wordsPerMinute: Double
    let pauseCount: Int
    let longestPauseSeconds: Double
    let durationSeconds: Double
    let feedback: [SpeechFeedback]

    var overallGrade: String {
        switch overall {
        case 90...100: return "Excellent"
        case 75..<90: return "Good"
        case 60..<75: return "Fair"
        default: return "Needs Work"
        }
    }

    static var preview: ScoreBreakdown {
        ScoreBreakdown(
            overall: 78,
            pace: 82,
            pauses: 74,
            clarity: 80,
            volumeConsistency: 70,
            confidence: 0.85,
            wordsPerMinute: 145,
            pauseCount: 3,
            longestPauseSeconds: 1.2,
            durationSeconds: 28.5,
            feedback: SpeechFeedback.previewSet
        )
    }
}
