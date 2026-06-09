import XCTest
@testable import OnDeviceSpeechCoach

final class SilenceDetectorTests: XCTestCase {
    private let sampleRate: Double = 44100
    private lazy var detector = SilenceDetector(
        threshold: 0.02,
        sampleRate: sampleRate,
        minPauseSeconds: 0.5
    )

    func testEmptySamplesReturnsZero() {
        let result = detector.detect(in: [])
        XCTAssertEqual(result.pauseSegments.count, 0)
        XCTAssertEqual(result.silenceRatio, 0)
    }

    func testAllSilenceDetected() {
        let samples = [Float](repeating: 0.001, count: Int(sampleRate * 3))
        let result = detector.detect(in: samples)
        XCTAssertGreaterThan(result.silenceRatio, 0.9)
    }

    func testAllSpeechDetected() {
        let samples = (0..<Int(sampleRate * 3)).map { i in
            Float(sin(Double(i) * 0.1)) * 0.5
        }
        let result = detector.detect(in: samples)
        XCTAssertLessThan(result.silenceRatio, 0.2)
    }

    func testLongPauseIsDetected() {
        var samples = [Float](repeating: 0, count: Int(sampleRate))           // 1s silence
        samples += (0..<Int(sampleRate)).map { i in Float(sin(Double(i) * 0.1)) * 0.5 }  // 1s speech
        samples += [Float](repeating: 0, count: Int(sampleRate * 2))          // 2s silence
        samples += (0..<Int(sampleRate)).map { i in Float(sin(Double(i) * 0.1)) * 0.5 }  // 1s speech

        let result = detector.detect(in: samples)
        XCTAssertGreaterThanOrEqual(result.pauseSegments.count, 1)
        let longest = result.longestPauseSeconds(sampleRate: sampleRate)
        XCTAssertGreaterThan(longest, 1.5)
    }

    func testSpeechActivityRatioIsComplement() {
        let samples = (0..<Int(sampleRate * 2)).map { i -> Float in
            i % 1000 < 500 ? Float(sin(Double(i) * 0.1)) * 0.5 : 0.001
        }
        let result = detector.detect(in: samples)
        XCTAssertEqual(result.silenceRatio + result.speechActivityRatio, 1.0, accuracy: 0.001)
    }

    func testShortSilencesBelowThresholdNotCounted() {
        // 200ms silence — below 500ms threshold
        let shortSilence = [Float](repeating: 0.001, count: Int(sampleRate * 0.2))
        let speech = (0..<Int(sampleRate)).map { i in Float(sin(Double(i) * 0.1)) * 0.5 }
        let samples = speech + shortSilence + speech

        let result = detector.detect(in: samples)
        XCTAssertEqual(result.pauseSegments.count, 0)
    }
}
