import Foundation

enum PromptCategory: String, Codable, CaseIterable {
    case interview
    case storytelling
    case reading
    case presentation
}

enum PromptDifficulty: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced
}

struct PracticePrompt: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let text: String
    let category: PromptCategory
    let difficulty: PromptDifficulty
    let estimatedSeconds: Int

    var wordCount: Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }

    static let samples: [PracticePrompt] = [
        PracticePrompt(
            id: UUID(),
            title: "Morning Routine",
            text: "Every morning I wake up, stretch for a few minutes, and then make a cup of coffee. I find that starting the day slowly helps me focus better throughout the afternoon.",
            category: .storytelling,
            difficulty: .beginner,
            estimatedSeconds: 30
        ),
        PracticePrompt(
            id: UUID(),
            title: "Tell Me About Yourself",
            text: "I am a software engineer with three years of experience building mobile applications. I enjoy working on products that directly impact users and thrive in collaborative, fast-moving teams.",
            category: .interview,
            difficulty: .intermediate,
            estimatedSeconds: 30
        ),
        PracticePrompt(
            id: UUID(),
            title: "The Importance of Sleep",
            text: "Sleep is one of the most critical factors in cognitive performance and physical health. Research consistently shows that adults who sleep fewer than seven hours per night face increased risk of reduced attention, impaired memory consolidation, and weakened immune response.",
            category: .reading,
            difficulty: .intermediate,
            estimatedSeconds: 40
        ),
        PracticePrompt(
            id: UUID(),
            title: "Product Launch Pitch",
            text: "Today I want to share something our team has been building for the past six months. Our new platform helps small businesses automate their customer onboarding process, reducing setup time from days to under an hour.",
            category: .presentation,
            difficulty: .advanced,
            estimatedSeconds: 35
        ),
        PracticePrompt(
            id: UUID(),
            title: "A Childhood Memory",
            text: "When I was about eight years old, my grandfather taught me how to fish at a small lake near his house. I remember the early mornings, the stillness of the water, and how proud I felt the first time I caught something.",
            category: .storytelling,
            difficulty: .beginner,
            estimatedSeconds: 35
        ),
        PracticePrompt(
            id: UUID(),
            title: "Why This Role",
            text: "I applied because the mission resonated with me immediately. Combining my background in distributed systems with my interest in developer tooling, I believe I can contribute meaningfully from day one while continuing to grow.",
            category: .interview,
            difficulty: .advanced,
            estimatedSeconds: 30
        ),
    ]
}
