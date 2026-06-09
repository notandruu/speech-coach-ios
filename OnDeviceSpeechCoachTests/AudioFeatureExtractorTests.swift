import XCTest
import AVFoundation
@testable import OnDeviceSpeechCoach

final class AudioFeatureExtractorTests: XCTestCase {
    private let extractor = AudioFeatureExtractor()
    private let sampleRate: Double = 44100
    private let wordCount = 35  // representative prompt

    // MARK: - Fixture helpers

    private func makeSineWave(durationSeconds: Double, frequency: Double = 440, amplitude: Float = 0.3) -> URL {
        let sampleCount = Int(sampleRate * durationSeconds)
        var samples = [Float](repeating: 0, count: sampleCount)
        for i in 0..<sampleCount {
            samples[i] = amplitude * Float(sin(2 * Double.pi * frequency * Double(i) / sampleRate))
        }
        return writeWAV(samples: samples)
    }

    private func makeSilence(durationSeconds: Double) -> URL {
        let sampleCount = Int(sampleRate * durationSeconds)
        let samples = [Float](repeating: 0.001, count: sampleCount)
        return writeWAV(samples: samples)
    }

    private func makeWithPause(speechSeconds: Double, pauseSeconds: Double) -> URL {
        let speechCount = Int(sampleRate * speechSeconds)
        let silenceCount = Int(sampleRate * pauseSeconds)
        var samples = (0..<speechCount).map { i in Float(sin(Double(i) * 0.1)) * 0.4 }
        samples += [Float](repeating: 0.001, count: silenceCount)
        samples += (0..<speechCount).map { i in Float(sin(Double(i) * 0.1)) * 0.4 }
        return writeWAV(samples: samples)
    }

    private func writeWAV(samples: [Float]) -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")

        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        let channelData = buffer.floatChannelData![0]
        for (i, v) in samples.enumerated() { channelData[i] = v }

        let file = try! AVAudioFile(forWriting: url, settings: format.settings)
        try! file.write(from: buffer)
        return url
    }

    // MARK: - Tests

    func testDurationIsAccurate() async throws {
        let url = makeSineWave(durationSeconds: 5.0)
        defer { try? FileManager.default.removeItem(at: url) }
        let features = try await extractor.extract(from: url, promptWordCount: wordCount)
        XCTAssertEqual(features.durationSeconds, 5.0, accuracy: 0.1)
    }

    func testSilenceHasHighSilenceRatio() async throws {
        let url = makeSilence(durationSeconds: 3.0)
        defer { try? FileManager.default.removeItem(at: url) }
        let features = try await extractor.extract(from: url, promptWordCount: wordCount)
        XCTAssertGreaterThan(features.silenceRatio, 0.8)
    }

    func testSpeechHasLowSilenceRatio() async throws {
        let url = makeSineWave(durationSeconds: 4.0, amplitude: 0.4)
        defer { try? FileManager.default.removeItem(at: url) }
        let features = try await extractor.extract(from: url, promptWordCount: wordCount)
        XCTAssertLessThan(features.silenceRatio, 0.3)
    }

    func testPauseIsDetected() async throws {
        // 2s speech, 1.5s silence, 2s speech — should detect 1 pause
        let url = makeWithPause(speechSeconds: 2.0, pauseSeconds: 1.5)
        defer { try? FileManager.default.removeItem(at: url) }
        let features = try await extractor.extract(from: url, promptWordCount: wordCount)
        XCTAssertGreaterThanOrEqual(features.pauseCount, 1)
        XCTAssertGreaterThan(features.longestPauseSeconds, 1.0)
    }

    func testMelSpectrogramHasCorrectSize() async throws {
        let url = makeSineWave(durationSeconds: 3.0)
        defer { try? FileManager.default.removeItem(at: url) }
        let features = try await extractor.extract(from: url, promptWordCount: wordCount)
        XCTAssertEqual(features.melSpectrogram.count, AppConstants.Audio.melBins * AppConstants.Audio.melFrames)
    }

    func testShortClipDoesNotCrash() async throws {
        let url = makeSineWave(durationSeconds: 0.3, amplitude: 0.1)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertNoThrow(try await extractor.extract(from: url, promptWordCount: 5))
    }

    func testWPMIsPositiveForSpeech() async throws {
        let url = makeSineWave(durationSeconds: 5.0, amplitude: 0.4)
        defer { try? FileManager.default.removeItem(at: url) }
        let features = try await extractor.extract(from: url, promptWordCount: 20)
        XCTAssertGreaterThan(features.estimatedWordsPerMinute, 0)
    }
}
