import XCTest
import CoreML
import AVFoundation
@testable import OnDeviceSpeechCoach

final class PerformanceTests: XCTestCase {
    private let extractor = AudioFeatureExtractor()
    private let builder = ModelInputBuilder()
    private let scorer = FluencyScorer()

    // MARK: - Feature extraction

    func testFeatureExtractionPerformance() throws {
        // Generate a synthetic 30s WAV fixture and measure extraction time.
        // Target: p95 < 300ms
        let url = try makeSineWaveWAV(durationSeconds: 30.0)
        defer { try? FileManager.default.removeItem(at: url) }

        let expectation = expectation(description: "extraction completes")
        measure {
            Task {
                _ = try? await self.extractor.extract(from: url, promptWordCount: 70)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10)
    }

    // MARK: - Scoring

    func testScoringPerformance() {
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
        let prediction = ModelPrediction(clarityScore: 0.8, confidence: 0.9)

        measure {
            _ = self.scorer.score(features: features, prediction: prediction)
        }
    }

    // MARK: - Model input builder

    func testInputBuilderPerformance() throws {
        let mel = Array(repeating: Float(0.5), count: 8192)
        measure {
            _ = try? self.builder.buildInput(from: mel)
        }
    }

    // MARK: - Fixture helper

    private func makeSineWaveWAV(durationSeconds: Double) throws -> URL {
        let sampleRate: Double = 44100
        let sampleCount = Int(sampleRate * durationSeconds)
        var samples = [Float](repeating: 0, count: sampleCount)
        for i in 0..<sampleCount {
            samples[i] = 0.3 * Float(sin(2 * Double.pi * 440 * Double(i) / sampleRate))
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")

        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount))!
        buffer.frameLength = AVAudioFrameCount(sampleCount)
        let channelData = buffer.floatChannelData![0]
        for (i, v) in samples.enumerated() { channelData[i] = v }

        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
        return url
    }
}
