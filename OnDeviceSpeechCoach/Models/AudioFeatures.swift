import Foundation

struct AudioFeatures {
    let durationSeconds: Double
    let rmsEnergy: Double
    let averageDecibels: Double
    let silenceRatio: Double
    let pauseCount: Int
    let longestPauseSeconds: Double
    let speechActivityRatio: Double
    let volumeVariance: Double
    let estimatedWordsPerMinute: Double
    // Fixed-size float array: melBins * melFrames (64 * 128 = 8192 elements)
    let melSpectrogram: [Float]
}

extension AudioFeatures {
    static var empty: AudioFeatures {
        AudioFeatures(
            durationSeconds: 0,
            rmsEnergy: 0,
            averageDecibels: -160,
            silenceRatio: 1,
            pauseCount: 0,
            longestPauseSeconds: 0,
            speechActivityRatio: 0,
            volumeVariance: 0,
            estimatedWordsPerMinute: 0,
            melSpectrogram: Array(repeating: 0, count: AppConstants.Audio.melBins * AppConstants.Audio.melFrames)
        )
    }
}
