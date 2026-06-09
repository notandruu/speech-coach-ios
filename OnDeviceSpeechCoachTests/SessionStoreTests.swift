import XCTest
import SwiftData
@testable import OnDeviceSpeechCoach

@MainActor
final class SessionStoreTests: XCTestCase {
    private var container: ModelContainer!
    private var store: SessionStore!

    override func setUpWithError() throws {
        let schema = Schema([PracticeSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        store = SessionStore(context: container.mainContext)
    }

    override func tearDown() {
        container = nil
        store = nil
    }

    func testSaveAndFetch() throws {
        let session = makeSession(score: 80)
        try store.save(session)

        let fetched = try store.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].overallScore, 80)
    }

    func testFetchOrderedByDateDescending() throws {
        let older = makeSession(score: 60, date: Date(timeIntervalSinceNow: -3600))
        let newer = makeSession(score: 90, date: Date())
        try store.save(older)
        try store.save(newer)

        let fetched = try store.fetchAll()
        XCTAssertEqual(fetched.count, 2)
        XCTAssertEqual(fetched[0].overallScore, 90, "Newest session should be first")
    }

    func testDeleteAll() throws {
        try store.save(makeSession(score: 70))
        try store.save(makeSession(score: 80))

        try store.deleteAll()
        let fetched = try store.fetchAll()
        XCTAssertEqual(fetched.count, 0)
    }

    func testAverageScore() throws {
        try store.save(makeSession(score: 60))
        try store.save(makeSession(score: 80))

        let avg = try store.averageScore()
        XCTAssertEqual(avg, 70, accuracy: 0.01)
    }

    func testAverageScoreNilWhenEmpty() throws {
        let avg = try store.averageScore()
        XCTAssertNil(avg)
    }

    func testBestScore() throws {
        try store.save(makeSession(score: 55))
        try store.save(makeSession(score: 92))
        try store.save(makeSession(score: 73))

        let best = try store.bestScore()
        XCTAssertEqual(best, 92)
    }

    // MARK: - Helper

    private func makeSession(score: Double, date: Date = Date()) -> PracticeSession {
        PracticeSession(
            promptTitle: "Test Prompt",
            promptText: "Some text",
            createdAt: date,
            durationSeconds: 25,
            overallScore: score,
            paceScore: score,
            pauseScore: score,
            clarityScore: score,
            volumeConsistencyScore: score,
            wordsPerMinute: 140,
            pauseCount: 2,
            longestPauseSeconds: 0.8,
            speechActivityRatio: 0.85,
            feedbackSummary: "Test feedback"
        )
    }
}
