import AVFoundation
import Accelerate

struct WaveformExtractor {
    // Returns normalized RMS values per bucket for waveform display.
    static func extract(from url: URL, buckets: Int = 100) async throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: file.fileFormat.sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            return Array(repeating: 0, count: buckets)
        }

        let frameCount = AVAudioFrameCount(file.length)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return Array(repeating: 0, count: buckets)
        }

        try file.read(into: buffer)
        guard let channelData = buffer.floatChannelData?[0] else {
            return Array(repeating: 0, count: buckets)
        }

        let samples = Array(UnsafeBufferPointer(start: channelData, count: Int(frameCount)))
        let bucketSize = max(1, samples.count / buckets)

        var result = [Float]()
        result.reserveCapacity(buckets)

        for i in 0..<buckets {
            let start = i * bucketSize
            let end = min(start + bucketSize, samples.count)
            guard start < end else {
                result.append(0)
                continue
            }
            var rms: Float = 0
            vDSP_rmsqv(Array(samples[start..<end]), 1, &rms, vDSP_Length(end - start))
            result.append(rms)
        }

        // Normalize to [0, 1]
        var maxVal: Float = 0
        vDSP_maxv(result, 1, &maxVal, vDSP_Length(result.count))
        if maxVal > 0 {
            var scale = 1.0 / maxVal
            vDSP_vsmul(result, 1, &scale, &result, 1, vDSP_Length(result.count))
        }

        return result
    }
}
