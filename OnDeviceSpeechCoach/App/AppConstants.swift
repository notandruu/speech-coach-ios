import Foundation

enum AppConstants {
    enum Scoring {
        static let paceWeight: Double = 0.30
        static let pauseWeight: Double = 0.30
        static let clarityWeight: Double = 0.25
        static let volumeConsistencyWeight: Double = 0.15

        static let idealWPMLow: Double = 130
        static let idealWPMHigh: Double = 170
        static let idealWPMMid: Double = 150

        // Silence longer than this threshold counts as a pause
        static let pauseThresholdSeconds: Double = 0.5
        // RMS below this (normalized 0–1) is considered silence
        static let silenceRMSThreshold: Float = 0.02
    }

    enum Audio {
        static let sampleRate: Double = 44100
        static let melBins: Int = 64
        static let melFrames: Int = 128
        static let levelMeterUpdateHz: Double = 20
    }

    enum Model {
        static let packageName = "FluencyScorer"
        static let inputName = "mel_spectrogram"
        static let outputName = "scores"
    }
}
