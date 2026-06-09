import XCTest
@testable import OnDeviceSpeechCoach

final class FluencyScorerTests: XCTestCase {
    private let scorer = FluencyScorer()
    private let neutralPrediction = ModelPrediction(clarityScore: 0.75, confidence: 0.8)

    // MARK: - Pace score

    func testIdealPaceScoresHigh() {
        let score = scorer.paceScore(wpm: 150)
        XCTAssertGreaterThanOrEqual(score, 90)
    }

    func testTooFastPaceIsLower() {
        let fast = scorer.paceScore(wpm: 230)
        let ideal = scorer.paceScore(wpm: 150)
        XCTAssertLessThan(fast, ideal)
    }

    func testTooSlowPaceIsLower() {
        let slow = scorer.paceScore(wpm: 80)
        let ideal = scorer.paceScore(wpm: 150)
        XCTAssertLessThan(slow, ideal)
    }

    func testZeroWPMReturnsFallback() {
        let score = scorer.paceScore(wpm: 0)
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThan(score, 70)
    }

    // MARK: - Pause score

    func testNoPausesScoresHigh() {
        let score = scorer.pauseScore(pauseCount: 0, longestPause: 0, silenceRatio: 0.05)
        XCTAssertGreaterThanOrEqual(score, 90)
    }

    func testManyPausesReduceScore() {
        let many = scorer.pauseScore(pauseCount: 10, longestPause: 3.5, silenceRatio: 0.5)
        let few = scorer.pauseScore(pauseCount: 1, longestPause: 0.6, silenceRatio: 0.1)
        XCTAssertLessThan(many, few)
    }

    // MARK: - Overall scoring

    func testScoreClamping() {
        let features = AudioFeatures(
            durationSeconds: 30,
            rmsEnergy: 0.5,
            averageDecibels: -20,
            silenceRatio: 0.9,  // extreme silence
            pauseCount: 20,
            longestPauseSeconds: 10,
            speechActivityRatio: 0.1,
            volumeVariance: 1.0,
            estimatedWordsPerMinute: 300,
            melSpectrogram: Array(repeating: 0, count: 8192)
        )
        let badPrediction = ModelPrediction(clarityScore: 0.0, confidence: 0.1)
        let result = scorer.score(features: features, prediction: badPrediction)
        XCTAssertGreaterThanOrEqual(result.overall, 0)
        XCTAssertLessThanOrEqual(result.overall, 100)
        XCTAssertGreaterThanOrEqual(result.pace, 0)
        XCTAssertLessThanOrEqual(result.pace, 100)
    }

    func testGoodSessionScoresWell() {
        let features = AudioFeatures(
            durationSeconds: 30,
            rmsEnergy: 0.3,
            averageDecibels: -15,
            silenceRatio: 0.15,
            pauseCount: 2,
            longestPauseSeconds: 0.7,
            speechActivityRatio: 0.85,
            volumeVariance: 0.05,
            estimatedWordsPerMinute: 148,
            melSpectrogram: Array(repeating: 0.1, count: 8192)
        )
        let goodPrediction = ModelPrediction(clarityScore: 0.9, confidence: 0.95)
        let result = scorer.score(features: features, prediction: goodPrediction)
        XCTAssertGreaterThanOrEqual(result.overall, 70)
    }

    func testFeedbackCountMatchesDimensions() {
        let features = AudioFeatures.empty
        let result = scorer.score(features: features, prediction: neutralPrediction)
        // Expect exactly 4 feedback items (pace, pauses, clarity, volume)
        XCTAssertEqual(result.feedback.count, 4)
    }

    func testPositiveFeedbackForIdealSession() {
        let features = AudioFeatures(
            durationSeconds: 30,
            rmsEnergy: 0.3,
            averageDecibels: -15,
            silenceRatio: 0.12,
            pauseCount: 1,
            longestPauseSeconds: 0.55,
            speechActivityRatio: 0.88,
            volumeVariance: 0.02,
            estimatedWordsPerMinute: 152,
            melSpectrogram: Array(repeating: 0.2, count: 8192)
        )
        let result = scorer.score(features: features, prediction: ModelPrediction(clarityScore: 0.92, confidence: 0.97))
        let positiveCount = result.feedback.filter { $0.sentiment == .positive }.count
        XCTAssertGreaterThanOrEqual(positiveCount, 3)
    }

    // MARK: - Volume consistency

    func testLowVarianceScoresHigh() {
        let score = scorer.volumeConsistencyScore(variance: 0.01)
        XCTAssertGreaterThanOrEqual(score, 90)
    }

    func testHighVarianceScoresLow() {
        let score = scorer.volumeConsistencyScore(variance: 0.5)
        XCTAssertLessThan(score, 10)
    }
}
