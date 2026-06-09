import Accelerate

struct PauseSegment {
    let startSample: Int
    let endSample: Int
    var durationSamples: Int { endSample - startSample }
    func durationSeconds(sampleRate: Double) -> Double {
        Double(durationSamples) / sampleRate
    }
}

struct SilenceDetectionResult {
    let pauseSegments: [PauseSegment]
    let silenceSampleCount: Int
    let totalSamples: Int

    var silenceRatio: Double {
        totalSamples > 0 ? Double(silenceSampleCount) / Double(totalSamples) : 0
    }

    var speechActivityRatio: Double { 1.0 - silenceRatio }

    func longestPauseSeconds(sampleRate: Double) -> Double {
        pauseSegments.map { $0.durationSeconds(sampleRate: sampleRate) }.max() ?? 0
    }
}

struct SilenceDetector {
    let threshold: Float
    let sampleRate: Double
    let minPauseSamples: Int

    init(
        threshold: Float = AppConstants.Scoring.silenceRMSThreshold,
        sampleRate: Double = AppConstants.Audio.sampleRate,
        minPauseSeconds: Double = AppConstants.Scoring.pauseThresholdSeconds
    ) {
        self.threshold = threshold
        self.sampleRate = sampleRate
        self.minPauseSamples = Int(minPauseSeconds * sampleRate)
    }

    func detect(in samples: [Float]) -> SilenceDetectionResult {
        guard !samples.isEmpty else {
            return SilenceDetectionResult(pauseSegments: [], silenceSampleCount: 0, totalSamples: 0)
        }

        let frameSize = 512
        var isSilent = [Bool]()
        isSilent.reserveCapacity(samples.count / frameSize + 1)

        var idx = 0
        while idx < samples.count {
            let end = min(idx + frameSize, samples.count)
            let frame = Array(samples[idx..<end])
            var rms: Float = 0
            vDSP_rmsqv(frame, 1, &rms, vDSP_Length(frame.count))
            isSilent.append(rms < threshold)
            idx += frameSize
        }

        // Map frame-level flags back to sample-level counts
        var pauseSegments = [PauseSegment]()
        var silenceSampleCount = 0

        var inSilence = false
        var silenceStart = 0

        for (frameIdx, silent) in isSilent.enumerated() {
            let sampleStart = frameIdx * frameSize
            let sampleEnd = min(sampleStart + frameSize, samples.count)
            let frameSamples = sampleEnd - sampleStart

            if silent {
                silenceSampleCount += frameSamples
                if !inSilence {
                    inSilence = true
                    silenceStart = sampleStart
                }
            } else {
                if inSilence {
                    let pauseLen = sampleStart - silenceStart
                    if pauseLen >= minPauseSamples {
                        pauseSegments.append(PauseSegment(startSample: silenceStart, endSample: sampleStart))
                    }
                    inSilence = false
                }
            }
        }

        if inSilence {
            let pauseLen = samples.count - silenceStart
            if pauseLen >= minPauseSamples {
                pauseSegments.append(PauseSegment(startSample: silenceStart, endSample: samples.count))
            }
        }

        return SilenceDetectionResult(
            pauseSegments: pauseSegments,
            silenceSampleCount: silenceSampleCount,
            totalSamples: samples.count
        )
    }
}
