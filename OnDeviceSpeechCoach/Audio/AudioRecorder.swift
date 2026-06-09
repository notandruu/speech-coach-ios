import AVFoundation
import Combine
import os

final class AudioRecorder: NSObject {
    // Published on MainActor — observers can bind directly to UI
    @MainActor @Published var isRecording = false
    @MainActor @Published var elapsedSeconds: Double = 0
    @MainActor @Published var normalizedLevel: Float = 0  // 0.0–1.0

    private var recorder: AVAudioRecorder?
    private var outputURL: URL?
    private var levelTimer: Timer?
    private var elapsedTimer: Timer?
    private var startDate: Date?

    private static let log = Logger(subsystem: "com.speechcoach", category: "AudioRecorder")

    var recordedFileURL: URL? { outputURL }

    // MARK: - Start

    func startRecording() throws -> URL {
        let url = Self.makeTempURL()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: AppConstants.Audio.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
        ]

        try AudioSessionManager.shared.configureForRecording()

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.delegate = self
        recorder.isMeteringEnabled = true
        recorder.record()

        self.recorder = recorder
        self.outputURL = url

        startDate = Date()
        startTimers()

        Task { @MainActor in
            isRecording = true
        }

        Self.log.info("Recording started → \(url.lastPathComponent)")
        return url
    }

    // MARK: - Stop

    func stopRecording() -> URL? {
        guard let recorder, recorder.isRecording else { return nil }
        recorder.stop()
        stopTimers()
        AudioSessionManager.shared.deactivate()

        Task { @MainActor in
            isRecording = false
        }

        Self.log.info("Recording stopped")
        return outputURL
    }

    // MARK: - Cancel

    func cancelRecording() {
        recorder?.stop()
        stopTimers()
        AudioSessionManager.shared.deactivate()

        if let url = outputURL {
            try? FileManager.default.removeItem(at: url)
            Self.log.info("Temp file deleted on cancel")
        }

        outputURL = nil

        Task { @MainActor in
            isRecording = false
            elapsedSeconds = 0
            normalizedLevel = 0
        }
    }

    // MARK: - Timers

    private func startTimers() {
        levelTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / AppConstants.Audio.levelMeterUpdateHz,
            repeats: true
        ) { [weak self] _ in
            self?.updateLevel()
        }

        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let startDate = self.startDate else { return }
            let elapsed = Date().timeIntervalSince(startDate)
            Task { @MainActor in
                self.elapsedSeconds = elapsed
            }
        }
    }

    private func stopTimers() {
        levelTimer?.invalidate()
        levelTimer = nil
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    private func updateLevel() {
        guard let recorder, recorder.isRecording else { return }
        recorder.updateMeters()
        // averagePower is in dBFS; map [-60, 0] → [0, 1]
        let power = recorder.averagePower(forChannel: 0)
        let normalized = max(0, min(1, (power + 60) / 60))
        Task { @MainActor in
            self.normalizedLevel = normalized
        }
    }

    // MARK: - Helpers

    private static func makeTempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            Self.log.error("Recording finished unsuccessfully")
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error {
            Self.log.error("Encode error: \(error.localizedDescription)")
        }
    }
}
