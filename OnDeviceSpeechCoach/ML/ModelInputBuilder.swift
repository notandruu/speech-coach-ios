import CoreML
import Foundation

struct ModelInputBuilder {
    /// Converts the flat mel spectrogram array [bins * frames] into an MLMultiArray
    /// with shape [1, 1, bins, frames] matching the Core ML model's expected input.
    func buildInput(from melSpectrogram: [Float]) throws -> MLMultiArray {
        let bins = ModelVersion.inputShape.bins
        let frames = ModelVersion.inputShape.frames
        let expectedCount = bins * frames

        guard melSpectrogram.count >= expectedCount else {
            throw ModelInputError.insufficientData(
                expected: expectedCount, got: melSpectrogram.count
            )
        }

        let shape: [NSNumber] = [1, 1, NSNumber(value: bins), NSNumber(value: frames)]
        let array = try MLMultiArray(shape: shape, dataType: .float32)

        for i in 0..<expectedCount {
            array[i] = NSNumber(value: melSpectrogram[i])
        }

        return array
    }
}

enum ModelInputError: Error, LocalizedError {
    case insufficientData(expected: Int, got: Int)

    var errorDescription: String? {
        switch self {
        case let .insufficientData(expected, got):
            return "Mel spectrogram has \(got) elements, expected \(expected)."
        }
    }
}
