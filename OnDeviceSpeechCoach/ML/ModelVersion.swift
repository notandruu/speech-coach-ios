import Foundation

struct ModelVersion {
    static let name = "FluencyScorer"
    static let version = "1.0.0"
    static let inputShape = (batch: 1, channels: 1, bins: 64, frames: 128)
    static let outputCount = 2
}
