import CoreML
import Foundation
import os

struct ModelPrediction {
    let clarityScore: Double   // 0.0–1.0
    let confidence: Double     // 0.0–1.0
}

final class FluencyModelRunner {
    private static let log = Logger(subsystem: "com.speechcoach", category: "FluencyModelRunner")
    private static let signposter = OSSignposter(subsystem: "com.speechcoach", category: "Performance")

    // Model is loaded lazily — nil when bundle doesn't contain the .mlpackage
    private let model: MLModel?

    init() {
        let config = MLModelConfiguration()
        config.computeUnits = .all

        // In DEBUG builds the model may be absent; fall through to fallback scoring.
        if let url = Bundle.main.url(forResource: ModelVersion.name, withExtension: "mlmodelc")
            ?? Bundle.main.url(forResource: ModelVersion.name, withExtension: "mlpackage") {
            do {
                model = try MLModel(contentsOf: url, configuration: config)
                Self.log.info("Core ML model loaded from \(url.lastPathComponent)")
            } catch {
                Self.log.error("Failed to load Core ML model: \(error.localizedDescription)")
                model = nil
            }
        } else {
            Self.log.warning("Core ML model not found in bundle — using fallback scoring")
            model = nil
        }
    }

    func predict(melSpectrogram: MLMultiArray) throws -> ModelPrediction {
        let signpostID = Self.signposter.makeSignpostID()
        let state = Self.signposter.beginInterval("CoreMLInference", id: signpostID)
        defer { Self.signposter.endInterval("CoreMLInference", state) }

        guard let model else {
            return fallbackPrediction(melSpectrogram: melSpectrogram)
        }

        let input = try MLDictionaryFeatureProvider(
            dictionary: [AppConstants.Model.inputName: melSpectrogram]
        )
        let output = try model.prediction(from: input)

        guard let scores = output.featureValue(for: AppConstants.Model.outputName)?.multiArrayValue,
              scores.count >= 2 else {
            return fallbackPrediction(melSpectrogram: melSpectrogram)
        }

        return ModelPrediction(
            clarityScore: scores[0].doubleValue.clamped(to: 0...1),
            confidence: scores[1].doubleValue.clamped(to: 0...1)
        )
    }

    // Deterministic heuristic when model unavailable (DEBUG / simulator without mlpackage)
    private func fallbackPrediction(melSpectrogram: MLMultiArray) -> ModelPrediction {
        let count = melSpectrogram.count
        var sum: Double = 0
        for i in 0..<count {
            sum += melSpectrogram[i].doubleValue
        }
        let mean = count > 0 ? sum / Double(count) : 0
        // Map mean energy to a plausible clarity estimate
        let clarity = min(1.0, max(0.0, 0.5 + mean * 0.2))
        return ModelPrediction(clarityScore: clarity, confidence: 0.5)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        max(range.lowerBound, min(range.upperBound, self))
    }
}
