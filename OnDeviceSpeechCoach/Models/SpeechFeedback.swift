import Foundation

enum FeedbackCategory: String, Hashable {
    case pace
    case pauses
    case clarity
    case volume
    case overall
}

enum FeedbackSentiment: String, Hashable {
    case positive
    case neutral
    case negative
}

struct SpeechFeedback: Identifiable, Hashable {
    let id: UUID
    let category: FeedbackCategory
    let sentiment: FeedbackSentiment
    let message: String

    init(category: FeedbackCategory, sentiment: FeedbackSentiment, message: String) {
        self.id = UUID()
        self.category = category
        self.sentiment = sentiment
        self.message = message
    }

    static var previewSet: [SpeechFeedback] {
        [
            SpeechFeedback(category: .pace, sentiment: .positive, message: "Your pace was steady and easy to follow."),
            SpeechFeedback(category: .pauses, sentiment: .negative, message: "You had a few long pauses. Try previewing the next phrase before finishing the current one."),
            SpeechFeedback(category: .clarity, sentiment: .positive, message: "Your clarity was strong throughout the recording."),
            SpeechFeedback(category: .volume, sentiment: .neutral, message: "Volume varied slightly. Try keeping a steady distance from the microphone."),
        ]
    }
}
