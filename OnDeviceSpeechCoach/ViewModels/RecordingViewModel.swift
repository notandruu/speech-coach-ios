import Foundation
import SwiftData
import Combine
import os

enum RecordingState {
    case idle
    case requestingPermission
    case permissionDenied
    case recording
    case processing
    case done(ScoreBreakdown)
    case failed(String)
}

@Observable
@MainActor
final class RecordingViewModel {
    var state: RecordingState = .idle
    var elapsedSeconds: Double = 0
    var normalizedLevel: Float = 0

    private let prompt: PracticePrompt
    private let recorder = AudioRecorder()
    private let extractor = AudioFeatureExtractor()
    private let scorer = FluencyScorer()
    private let inputBuilder = ModelInputBuilder()
    private let modelRunner = FluencyModelRunner()
    private let permission: MicrophonePermissionProvider
    private var store: SessionStore?
    private var recordedURL: URL?

    private static let log = Logger(subsystem: "com.speechcoach", category: "RecordingViewModel")

    init(prompt: PracticePrompt, permission: MicrophonePermissionProvider = LiveMicrophonePermission()) {
        self.prompt = prompt
        self.permission = permission
    }

    func configure(context: ModelContext) {
        store = SessionStore(context: context)
        bindRecorder()
    }

    // MARK: - Actions

    func startRecording() async {
        let currentStatus = PermissionState(permission.currentStatus())

        switch currentStatus {
        case .denied:
            state = .permissionDenied
            return
        case .undetermined:
            state = .requestingPermission
            let granted = await permission.requestAccess()
            guard granted else {
                state = .permissionDenied
                return
            }
        case .granted:
            break
        }

        do {
            recordedURL = try recorder.startRecording()
            state = .recording
        } catch {
            state = .failed("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() async {
        guard case .recording = state else { return }
        recorder.stopRecording()
        state = .processing
        await processRecording()
    }

    func cancelRecording() {
        recorder.cancelRecording()
        recordedURL = nil
        state = .idle
    }

    func retry() {
        recordedURL = nil
        state = .idle
    }

    // MARK: - Processing

    private func processRecording() async {
        guard let url = recordedURL else {
            state = .failed("No recording found.")
            return
        }

        do {
            let features = try await extractor.extract(from: url, promptWordCount: prompt.wordCount)
            let mlInput = try inputBuilder.buildInput(from: features.melSpectrogram)
            let prediction = try modelRunner.predict(melSpectrogram: mlInput)
            let breakdown = scorer.score(features: features, prediction: prediction)

            // Save session
            if let store {
                let session = PracticeSession(
                    promptTitle: prompt.title,
                    promptText: prompt.text,
                    durationSeconds: features.durationSeconds,
                    overallScore: breakdown.overall,
                    paceScore: breakdown.pace,
                    pauseScore: breakdown.pauses,
                    clarityScore: breakdown.clarity,
                    volumeConsistencyScore: breakdown.volumeConsistency,
                    wordsPerMinute: features.estimatedWordsPerMinute,
                    pauseCount: features.pauseCount,
                    longestPauseSeconds: features.longestPauseSeconds,
                    speechActivityRatio: features.speechActivityRatio,
                    feedbackSummary: breakdown.feedback.first?.message ?? ""
                )
                try? store.save(session)
            }

            // Clean up temp file (raw audio does not persist by default)
            try? FileManager.default.removeItem(at: url)
            recordedURL = nil

            state = .done(breakdown)
        } catch {
            Self.log.error("Processing failed: \(error.localizedDescription)")
            state = .failed("Processing failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Bind recorder output

    private var cancellables = Set<AnyCancellable>()

    private func bindRecorder() {
        // Bridge @Published properties on AudioRecorder into this @Observable ViewModel.
        Timer.publish(every: 0.05, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsedSeconds = self.recorder.elapsedSeconds
                self.normalizedLevel = self.recorder.normalizedLevel
            }
            .store(in: &cancellables)
    }
}
