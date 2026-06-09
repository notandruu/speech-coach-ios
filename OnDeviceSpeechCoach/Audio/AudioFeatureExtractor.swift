import AVFoundation
import Accelerate
import os

struct AudioFeatureExtractor {
    let sampleRate: Double
    let silenceDetector: SilenceDetector

    private static let log = Logger(subsystem: "com.speechcoach", category: "AudioFeatureExtractor")
    private static let signposter = OSSignposter(subsystem: "com.speechcoach", category: "Performance")

    init(sampleRate: Double = AppConstants.Audio.sampleRate) {
        self.sampleRate = sampleRate
        self.silenceDetector = SilenceDetector(sampleRate: sampleRate)
    }

    func extract(from url: URL, promptWordCount: Int) async throws -> AudioFeatures {
        let signpostID = Self.signposter.makeSignpostID()
        let state = Self.signposter.beginInterval("FeatureExtraction", id: signpostID)
        defer { Self.signposter.endInterval("FeatureExtraction", state) }

        let samples = try await loadSamples(from: url)

        let durationSeconds = Double(samples.count) / sampleRate

        let silenceResult = silenceDetector.detect(in: samples)
        let activeSeconds = durationSeconds * silenceResult.speechActivityRatio
        let wpm: Double
        if activeSeconds > 0 {
            wpm = Double(promptWordCount) / (activeSeconds / 60.0)
        } else {
            wpm = 0
        }

        let rms = computeRMS(samples)
        let avgDB = 20 * log10(max(rms, 1e-9))
        let variance = computeVariance(samples)

        let mel = buildApproximateMelSpectrogram(samples: samples)

        Self.log.debug("Extracted features: dur=\(durationSeconds, format: .fixed(precision: 2))s wpm=\(wpm, format: .fixed(precision: 0)) pauses=\(silenceResult.pauseSegments.count)")

        return AudioFeatures(
            durationSeconds: durationSeconds,
            rmsEnergy: Double(rms),
            averageDecibels: avgDB,
            silenceRatio: silenceResult.silenceRatio,
            pauseCount: silenceResult.pauseSegments.count,
            longestPauseSeconds: silenceResult.longestPauseSeconds(sampleRate: sampleRate),
            speechActivityRatio: silenceResult.speechActivityRatio,
            volumeVariance: Double(variance),
            estimatedWordsPerMinute: wpm,
            melSpectrogram: mel
        )
    }

    // MARK: - Private helpers

    private func loadSamples(from url: URL) async throws -> [Float] {
        try await Task.detached(priority: .userInitiated) {
            let file = try AVAudioFile(forReading: url)
            guard let format = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: file.fileFormat.sampleRate,
                channels: 1,
                interleaved: false
            ) else {
                throw ExtractionError.formatUnsupported
            }

            let frameCount = AVAudioFrameCount(file.length)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                throw ExtractionError.bufferAllocationFailed
            }
            try file.read(into: buffer)

            guard let data = buffer.floatChannelData?[0] else {
                throw ExtractionError.bufferAllocationFailed
            }
            return Array(UnsafeBufferPointer(start: data, count: Int(frameCount)))
        }.value
    }

    private func computeRMS(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(samples.count))
        return rms
    }

    private func computeVariance(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        var mean: Float = 0
        var std: Float = 0
        vDSP_normalize(samples, 1, nil, 1, &mean, &std, vDSP_Length(samples.count))
        return std * std
    }

    /// Produces a fixed 64×128 float array approximating log-mel energy.
    /// For a production model use vDSP FFT + proper filterbank; this gives
    /// the right shape for Core ML while remaining fast and dependency-free.
    private func buildApproximateMelSpectrogram(samples: [Float]) -> [Float] {
        let bins = AppConstants.Audio.melBins
        let frames = AppConstants.Audio.melFrames
        let total = bins * frames
        guard !samples.isEmpty else { return Array(repeating: 0, count: total) }

        let fftSize = 512
        let hopSize = max(1, samples.count / frames)

        var setup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(fftSize), vDSP_DFT_FORWARD)
        defer { if let s = setup { vDSP_DFT_DestroySetup(s) } }

        var result = [Float](repeating: 0, count: total)

        for frame in 0..<frames {
            let sampleStart = frame * hopSize
            let sampleEnd = min(sampleStart + fftSize, samples.count)
            let frameLen = sampleEnd - sampleStart

            var real = [Float](repeating: 0, count: fftSize)
            var imag = [Float](repeating: 0, count: fftSize)
            real[0..<frameLen] = samples[sampleStart..<sampleEnd]

            if let setup {
                vDSP_DFT_Execute(setup, real, imag, &real, &imag)
            }

            // Compute power spectrum for first half (Nyquist)
            let halfLen = fftSize / 2
            var power = [Float](repeating: 0, count: halfLen)
            for i in 0..<halfLen {
                power[i] = real[i] * real[i] + imag[i] * imag[i]
            }

            // Bin into mel buckets (linear approximation)
            let binSize = max(1, halfLen / bins)
            for bin in 0..<bins {
                let start = bin * binSize
                let end = min(start + binSize, halfLen)
                var energy: Float = 0
                vDSP_sve(Array(power[start..<end]), 1, &energy, vDSP_Length(end - start))
                result[bin * frames + frame] = log(max(energy, 1e-10))
            }
        }

        // Normalize to [-1, 1]
        var minVal: Float = 0, maxVal: Float = 0
        vDSP_minv(result, 1, &minVal, vDSP_Length(total))
        vDSP_maxv(result, 1, &maxVal, vDSP_Length(total))
        let range = maxVal - minVal
        if range > 0 {
            var shift = -minVal
            vDSP_vsadd(result, 1, &shift, &result, 1, vDSP_Length(total))
            var scale = 2.0 / range
            vDSP_vsmul(result, 1, &scale, &result, 1, vDSP_Length(total))
            var sub: Float = 1.0
            vDSP_vsadd(result, 1, &sub, &result, 1, vDSP_Length(total))
        }

        return result
    }
}

enum ExtractionError: Error {
    case formatUnsupported
    case bufferAllocationFailed
}
